import stripe
from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload
from . import models, schemas
from app.core.config import STRIPE_SECRET_KEY
from app.services.models import Job, JobStatus, ServiceRequest

stripe.api_key = STRIPE_SECRET_KEY


def create_payment(db: Session, payment: schemas.PaymentCreate):
    """Flujo de pago original (sin Stripe, para compatibilidad)."""
    db_contract = db.query(models.Contract).filter(
        models.Contract.id == payment.contract_id
    ).first()

    if not db_contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"El contrato {payment.contract_id} no existe."
        )

    if db_contract.status in ["in_progress", "cancelled"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Este contrato ya fue pagado o está cancelado."
        )

    precio_real = db_contract.job.final_price
    amount_cents = int(float(precio_real) * 100)

    db_payment = models.Payment(
        contract_id=payment.contract_id,
        amount=float(precio_real),
        amount_cents=amount_cents,
        payment_method=payment.payment_method,
        status=models.PaymentStatus.COMPLETED
    )

    db_contract.status = "in_progress"  # type: ignore

    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)
    return db_payment


def create_payment_intent(db: Session, job_id: str, amount: float):
    """
    Crea un PaymentIntent en Stripe con capture_method='manual' (escrow).
    Los fondos se retienen pero NO se cobran hasta llamar a capture().
    """
    # 1. Validar que el job exista y esté en MATCHED
    job = db.query(Job).filter(Job.id == job_id).first()
    
    # Si no lo encuentra directo por Job ID, buscarlo por Service ID
    # (El frontend en ContractsScreen envía el service.id)
    if not job:
        job = db.query(Job).join(ServiceRequest).filter(ServiceRequest.service_id == job_id).first()

    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"El trabajo {job_id} no existe o no tiene una postulación aceptada."
        )

    if job.status != JobStatus.MATCHED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El trabajo no está en estado 'matched'. Estado actual: {job.status.value}"
        )

    # 2. Buscar o crear contrato para este job
    contract = db.query(models.Contract).filter(
        models.Contract.job_id == job.id
    ).first()

    if not contract:
        contract = models.Contract(
            job_id=job.id,
            client_id=job.client_id,
            status="pending"
        )
        db.add(contract)
        db.flush()

    # 3. Verificar que no exista ya un pago pendiente/retenido para este contrato
    existing_payment = db.query(models.Payment).filter(
        models.Payment.contract_id == contract.id,
        models.Payment.status.in_([
            models.PaymentStatus.PENDING,
            models.PaymentStatus.HELD_IN_ESCROW
        ])
    ).first()

    if existing_payment:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe un pago pendiente o retenido para este trabajo."
        )

    # 4. Calcular cantidad en centavos
    amount_cents = int(amount * 100)

    # 5. Crear PaymentIntent en Stripe (capture_method='manual' = escrow)
    try:
        intent = stripe.PaymentIntent.create(
            amount=amount_cents,
            currency="mxn",
            capture_method="manual",
            metadata={
                "job_id": str(job.id),
                "contract_id": str(contract.id)
            }
        )
    except stripe.error.StripeError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error al crear PaymentIntent en Stripe: {str(e)}"
        )

    # 6. Guardar Payment en nuestra BD
    db_payment = models.Payment(
        contract_id=contract.id,
        amount=amount,
        amount_cents=amount_cents,
        status=models.PaymentStatus.PENDING,
        payment_method="card",
        stripe_payment_intent_id=intent.id
    )

    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)

    return {
        "client_secret": intent.client_secret,
        "payment_intent_id": intent.id,
        "amount_cents": amount_cents,
        "payment_id": db_payment.id
    }


def confirm_escrow(db: Session, payment_intent_id: str):
    """
    Marca el pago como 'held_in_escrow' después de que el cliente
    confirma el pago exitosamente desde Flutter.
    """
    payment = db.query(models.Payment).filter(
        models.Payment.stripe_payment_intent_id == payment_intent_id
    ).first()

    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No se encontró un pago con ese PaymentIntent ID."
        )

    if payment.status != models.PaymentStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El pago no está pendiente. Estado actual: {payment.status.value}"
        )

    # Verificar en Stripe que realmente requires_capture
    try:
        intent = stripe.PaymentIntent.retrieve(payment_intent_id)
        if intent.status != "requires_capture":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Stripe: el PaymentIntent no está listo para retener. Estado: {intent.status}"
            )
    except stripe.error.StripeError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error al consultar Stripe: {str(e)}"
        )

    # Actualizar estado en nuestra BD
    payment.status = models.PaymentStatus.HELD_IN_ESCROW  # type: ignore

    # Actualizar contrato a in_progress
    contract = db.query(models.Contract).filter(
        models.Contract.id == payment.contract_id
    ).first()
    if contract:
        contract.status = "in_progress"  # type: ignore

    db.commit()
    db.refresh(payment)
    return payment


def capture_payment(db: Session, job_id: str):
    """
    Captura los fondos retenidos en Stripe cuando el trabajo se completa.
    Busca el Payment asociado al job y llama a PaymentIntent.capture().
    """
    # 1. Buscar el job primero por si job_id es en realidad un service_id
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        job = db.query(Job).join(ServiceRequest).filter(ServiceRequest.service_id == job_id).first()

    if not job:
        return None

    # 2. Buscar el contrato del job usando el ID real del job
    contract = db.query(models.Contract).filter(
        models.Contract.job_id == job.id
    ).first()

    if not contract:
        # Si no hay contrato, no hay pago Stripe que capturar (flujo sin Stripe)
        return None

    # 2. Buscar el pago retenido
    payment = db.query(models.Payment).filter(
        models.Payment.contract_id == contract.id,
        models.Payment.status == models.PaymentStatus.HELD_IN_ESCROW
    ).first()

    if not payment:
        # No hay pago en escrow, puede ser un flujo sin Stripe
        return None

    if not payment.stripe_payment_intent_id:
        return None

    # 3. Capturar en Stripe
    try:
        captured_intent = stripe.PaymentIntent.capture(
            str(payment.stripe_payment_intent_id)
        )
    except stripe.error.StripeError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error al capturar pago en Stripe: {str(e)}"
        )

    # 4. Actualizar nuestra BD
    payment.status = models.PaymentStatus.RELEASED  # type: ignore
    contract.status = "completed"  # type: ignore

    db.commit()
    db.refresh(payment)
    return payment


def get_payment(db: Session, payment_id: str):
    return db.query(models.Payment).filter(models.Payment.id == payment_id).first()


def get_payments_by_role(db: Session, current_user):
    """Filtra el historial de pagos según el rol del usuario logueado."""
    if current_user.role == "admin":
        return db.query(models.Payment).all()

    if current_user.role == "client":
        return db.query(models.Payment)\
            .join(models.Contract)\
            .filter(models.Contract.client_id == current_user.id)\
            .all()

    if current_user.role == "worker":
        return db.query(models.Payment)\
            .join(models.Contract)\
            .filter(models.Contract.job.has(Job.provider_id == current_user.id))\
            .all()

    return []


def get_contracts_by_role(db: Session, current_user):
    """Obtiene contratos con la información del Job cargada."""
    query = db.query(models.Contract).options(joinedload(models.Contract.job))

    if current_user.role == "admin":
        return query.all()
    
    return query.filter(models.Contract.client_id == current_user.id).all()