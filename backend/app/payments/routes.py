import stripe
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.auth.security import get_current_user
from app.auth import models as auth_models
from app.services import models as services_models
from app.services.notifications import service as notification_service
from . import schemas, models
import app.payments.services as services
from .invoice_pdf import generate_invoice_pdf

router = APIRouter()
workers_router = APIRouter()


# --- CONTRATOS ---

@router.post("/contracts", response_model=schemas.ContractResponse, status_code=201)
def create_contract(contract: schemas.ContractCreate, db: Session = Depends(get_db)):
    import uuid
    new_contract = models.Contract(
        id=str(uuid.uuid4()),
        job_id=contract.job_id,
        client_id=contract.client_id,
        status=models.ContractStatus.PENDING
    )
    db.add(new_contract)
    db.commit()
    db.refresh(new_contract)
    return new_contract


@router.get("/contracts", response_model=List[schemas.ContractResponse])
def get_contracts(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Obtiene los contratos filtrados según el rol del usuario."""
    return services.get_contracts_by_role(db=db, current_user=current_user)


# --- PAGOS CLÁSICOS ---

@router.post("/", response_model=schemas.PaymentResponse, status_code=201)
def create_payment(payment: schemas.PaymentCreate, db: Session = Depends(get_db)):
    """Pago directo (sin Stripe escrow). Mantiene compatibilidad."""
    return services.create_payment(db=db, payment=payment)


@router.get("/", response_model=List[schemas.PaymentResponse])
def get_payments(
    db: Session = Depends(get_db), 
    current_user: auth_models.User = Depends(get_current_user)
):
    """Historial de pagos filtrado por rol."""
    return services.get_payments_by_role(db=db, current_user=current_user)


# --- STRIPE ESCROW (SIN STRIPE CONNECT) ---

@router.post("/create-intent", response_model=schemas.CreateIntentResponse)
def create_payment_intent(
    data: schemas.CreateIntentRequest,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """
    Crea un PaymentIntent con capture_method='manual' (escrow).
    Stripe retiene los fondos sin cobrarlos hasta que el trabajo se complete.
    NO requiere Stripe Connect del trabajador — el cliente solo paga con su tarjeta.
    """
    # 1. Validar que el trabajo exista y esté en MATCHED
    from app.services.models import Job, JobStatus, ServiceRequest

    job = db.query(Job).filter(Job.id == data.job_id).first()
    if not job:
        job = db.query(Job).join(ServiceRequest).filter(
            ServiceRequest.service_id == data.job_id,
            Job.status != JobStatus.CANCELLED
        ).first()
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trabajo no encontrado"
        )
    if job.status != JobStatus.MATCHED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El trabajo no está en estado 'matched'. Estado actual: {job.status.value}"
        )

    # 2. Buscar o crear contrato
    contract = db.query(models.Contract).filter(
        models.Contract.job_id == job.id
    ).first()
    if not contract:
        contract = models.Contract(
            job_id=job.id,
            client_id=str(job.client_id),
            status="pending"
        )
        db.add(contract)
        db.flush()

    # 3. Buscar pago existente pendiente
    existing_payment = db.query(models.Payment).filter(
        models.Payment.contract_id == contract.id,
        models.Payment.status.in_([
            models.PaymentStatus.PENDING,
            models.PaymentStatus.HELD_IN_ESCROW
        ])
    ).first()

    if existing_payment:
        if existing_payment.status == models.PaymentStatus.HELD_IN_ESCROW:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya existe un pago retenido para este trabajo. No puedes reiniciar el pago."
            )
        # PENDING: cancelar el intent anterior en Stripe y reemplazarlo
        if existing_payment.stripe_payment_intent_id:
            try:
                stripe.PaymentIntent.cancel(existing_payment.stripe_payment_intent_id)
            except stripe.error.StripeError:
                pass
        existing_payment.status = models.PaymentStatus.FAILED
        db.commit()

    # 4. Crear PaymentIntent en Stripe (manual capture = escrow)
    amount_cents = int(data.amount_mxn * 100)
    try:
        intent = stripe.PaymentIntent.create(
            amount=amount_cents,
            currency="mxn",
            capture_method="manual",
            metadata={
                "worker_id": data.worker_id,
                "job_id": data.job_id,
            }
        )
    except stripe.error.StripeError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error al crear PaymentIntent: {str(e)}"
        )

    # 5. Guardar Payment en BD
    db_payment = models.Payment(
        contract_id=contract.id,
        amount=data.amount_mxn,
        amount_cents=amount_cents,
        status=models.PaymentStatus.PENDING,
        payment_method="card",
        stripe_payment_intent_id=intent.id
    )
    db.add(db_payment)
    # El cliente inició el pago, ya no necesita el deadline
    job.payment_due_at = None  # type: ignore
    db.commit()

    return schemas.CreateIntentResponse(
        client_secret=intent.client_secret,
        payment_intent_id=intent.id
    )


@router.post("/confirm-payment")
def confirm_payment(
    data: schemas.ConfirmPaymentRequest,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """
    Confirma un pago exitoso (llamado desde Flutter tras el PaymentSheet).
    Crea el registro de pago en BD y notifica al trabajador.
    """
    worker = db.query(auth_models.User).filter(
        auth_models.User.id == data.worker_id
    ).first()
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trabajador no encontrado"
        )

    job = db.query(services_models.Job).filter(
        services_models.Job.id == data.job_id
    ).first()
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trabajo no encontrado"
        )

    contract = db.query(models.Contract).filter(
        models.Contract.job_id == job.id
    ).first()

    if not contract:
        contract = models.Contract(
            job_id=job.id,
            client_id=str(job.client_id),
            status="in_progress"
        )
        db.add(contract)
        db.flush()

    try:
        stripe.PaymentIntent.retrieve(data.payment_intent_id)
    except stripe.error.StripeError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error al verificar pago en Stripe: {str(e)}"
        )

    amount_cents = int(data.amount_mxn * 100)
    payment = models.Payment(
        contract_id=contract.id,
        amount=data.amount_mxn,
        amount_cents=amount_cents,
        status=models.PaymentStatus.COMPLETED,
        stripe_payment_intent_id=data.payment_intent_id,
    )
    db.add(payment)
    job.payment_due_at = None
    if job.request and job.request.service:
        for req in job.request.service.requests:
            if str(req.id) != str(job.request_id):
                req.status = "rejected"
    db.commit()
    db.refresh(payment)

    service_title = ""
    if job.request and job.request.service:
        service_title = job.request.service.title or ""

    notification_service.notify_payment_made(
        db=db,
        worker_id=data.worker_id,
        amount=data.amount_mxn,
        service_title=service_title,
        job_id=data.job_id
    )

    return {"status": "success", "payment_id": payment.id}


@router.post("/confirm-escrow", response_model=schemas.PaymentResponse)
def confirm_escrow(
    data: schemas.ConfirmEscrowRequest,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """
    Endpoint llamado desde Flutter DESPUÉS de que el SDK de Stripe
    confirma que el pago fue autorizado exitosamente.
    Actualiza el estado del pago a 'held_in_escrow'.
    """
    payment = services.confirm_escrow(db=db, payment_intent_id=data.payment_intent_id)
    return payment


@router.post("/refund/{payment_id}", response_model=schemas.PaymentResponse)
def refund_payment(
    payment_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """
    Realiza un reembolso (solo Admin por ahora).
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="No tienes permiso")
    return services.refund_payment(db=db, payment_id=payment_id)


@router.post("/resolve-dispute")
def resolve_dispute(
    conversation_id: str,
    resolution: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """
    Resuelve una disputa administrativa.
    resolution: 'refund' o 'release'.
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="No tienes permiso")
    return services.resolve_dispute(db=db, conversation_id=conversation_id, resolution=resolution)


@router.get("/invoice/{payment_id}/pdf")
def download_invoice_pdf(
    payment_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Genera y descarga el PDF de una factura."""
    payment = db.query(models.Payment).filter(models.Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Pago no encontrado")

    contract = payment.contract
    if not contract:
        raise HTTPException(status_code=404, detail="Contrato no encontrado")

    svc = None
    if contract.job and contract.job.request and contract.job.request.service:
        svc = contract.job.request.service

    payment_data = {
        "id": payment.id,
        "contract_id": payment.contract_id,
        "amount": payment.amount,
        "status": payment.status.value if hasattr(payment.status, 'value') else payment.status,
        "service_title": svc.title if svc else "Servicio",
        "service_description": svc.description if svc else "",
        "service_category": svc.category.name if svc and svc.category else "",
    }

    pdf_path = generate_invoice_pdf(payment_data)
    filename = f"factura_{payment.id[:8].upper()}.pdf"

    return FileResponse(
        pdf_path,
        media_type="application/pdf",
        filename=filename,
        headers={"Content-Disposition": f'attachment; filename="{filename}"'}
    )


# --- WORKER STRIPE CONNECT ---

@workers_router.get("/stripe-status", response_model=schemas.StripeStatusResponse)
def get_worker_stripe_status(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """
    Devuelve el estado de la cuenta Stripe Connect del trabajador.
    """
    user = db.query(auth_models.User).filter(
        auth_models.User.id == current_user.id
    ).first()

    if not user or not user.stripe_account_id:
        return schemas.StripeStatusResponse()

    try:
        account = stripe.Account.retrieve(user.stripe_account_id)
        return schemas.StripeStatusResponse(
            has_stripe_account=True,
            onboarding_completed=account.charges_enabled,
            charges_enabled=account.charges_enabled,
            payouts_enabled=account.payouts_enabled,
        )
    except stripe.error.StripeError:
        return schemas.StripeStatusResponse(has_stripe_account=True)


@workers_router.post("/stripe-setup", response_model=schemas.StripeSetupResponse)
def setup_worker_stripe(
    data: schemas.StripeSetupRequest,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    if current_user.id != data.user_id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No puedes configurar la billetera de otro usuario"
        )

    user = db.query(auth_models.User).filter(auth_models.User.id == data.user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trabajador no encontrado"
        )

    stripe_account_id = user.stripe_account_id

    if not stripe_account_id:
        try:
            names = (user.full_name or "").strip().split(maxsplit=1)
            first_name = names[0] if names else ""
            last_name = names[1] if len(names) > 1 else ""

            account = stripe.Account.create(
                type="express",
                country="MX",
                email=user.email,
                business_type="individual",
                capabilities={
                    "transfers": {"requested": True},
                },
                business_profile={
                    "url": "https://forjatrabajo.com",
                    "product_description": "Proveedor de servicios independientes en la plataforma.",
                    "mcc": "7299"
                },
                individual={
                    "first_name": first_name,
                    "last_name": last_name,
                },
            )
            stripe_account_id = account.id
            user.stripe_account_id = stripe_account_id
            db.commit()
        except stripe.error.StripeError as e:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Error al crear cuenta de Stripe: {str(e)}"
            )

    # Verificar si ya completó el onboarding
    try:
        account = stripe.Account.retrieve(stripe_account_id)
        if account.charges_enabled and account.payouts_enabled:
            return schemas.StripeSetupResponse(url="__ALREADY_COMPLETED__")
    except stripe.error.StripeError:
        pass

    try:
        account_link = stripe.AccountLink.create(
            account=stripe_account_id,
            type="account_onboarding",
            refresh_url="https://forjatrabajo.com/configurar-billetera",
            return_url="https://forjatrabajo.com/billetera-lista"
        )
        return schemas.StripeSetupResponse(url=account_link.url)
    except stripe.error.StripeError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error al crear enlace de onboarding: {str(e)}"
        )