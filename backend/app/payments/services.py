import stripe
import logging
from datetime import datetime
from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload
from . import models, schemas
from app.core.config import STRIPE_SECRET_KEY
from app.services.models import Job, JobStatus, ServiceRequest

logger = logging.getLogger(__name__)

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

    if db_contract.job:
        db_contract.job.payment_due_at = None
        if db_contract.job.request and db_contract.job.request.service:
            for req in db_contract.job.request.service.requests:
                if str(req.id) != str(db_contract.job.request_id):
                    req.status = "rejected"

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

    # 4. Calcular cantidad en centavos
    amount_cents = int(amount * 100)

    # 5. Crear PaymentIntent en Stripe (capture_method='manual' = escrow)
    print(f"DEBUG: Intentando crear PaymentIntent para Job: {job.id}, Amount: {amount_cents} cents")
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
        print(f"DEBUG: PaymentIntent creado exitosamente: {intent.id}")
    except stripe.error.StripeError as e:
        print(f"🚨 ERROR STRIPE: {str(e)}")
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

    # El cliente inició el pago, ya no necesita el deadline
    job.payment_due_at = None  # type: ignore

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
    print(f"DEBUG: Confirmando escrow para Intent: {payment_intent_id}")
    try:
        intent = stripe.PaymentIntent.retrieve(payment_intent_id)
        print(f"DEBUG: Estado de Intent en Stripe: {intent.status}")
        if intent.status != "requires_capture":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Stripe: el PaymentIntent no está listo para retener. Estado: {intent.status}"
            )
    except stripe.error.StripeError as e:
        print(f"🚨 ERROR STRIPE AL RECUPERAR: {str(e)}")
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
        job = db.query(Job).filter(Job.id == contract.job_id).first()
        if job:
            job.payment_due_at = None
            job.work_started_at = datetime.utcnow()
            if job.request and job.request.service:
                for req in job.request.service.requests:
                    if str(req.id) != str(job.request_id):
                        req.status = "rejected"

    db.commit()
    db.refresh(payment)

    # Notificar al trabajador que el pago está retenido
    try:
        from app.services.notifications import service as notif_service
        if contract:
            job = db.query(Job).filter(Job.id == contract.job_id).first()
            if job:
                service_title = "Servicio"
                if job.request and job.request.service:
                    service_title = job.request.service.title
                notif_service.notify_escrow_confirmed(
                    db=db,
                    worker_id=str(job.provider_id),
                    amount=payment.amount,
                    service_title=service_title,
                    job_id=str(job.id)
                )
    except Exception as e:
        print(f"⚠️ Error notificando pago retenido: {e}")

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

    # 3. Capturar en Stripe (si aplica)
    if payment.stripe_payment_intent_id:
        try:
            print(f"[CAPTURE] Capturando PaymentIntent: {payment.stripe_payment_intent_id}", flush=True)
            captured_intent = stripe.PaymentIntent.capture(
                str(payment.stripe_payment_intent_id)
            )
            print(f"[CAPTURE] Capture exitoso, status: {captured_intent.status}", flush=True)
        except stripe.error.StripeError as e:
            print(f"[CAPTURE] ERROR DE STRIPE al capturar: {e}", flush=True)
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Error al capturar pago en Stripe: {str(e)}"
            )

        # 4. Transferir los fondos a la cuenta Stripe Connect del trabajador
        print(f"[CAPTURE] Iniciando transferencia al worker...", flush=True)
        _transfer_to_worker(db, job, payment)
        print(f"[CAPTURE] Transferencia completada", flush=True)

    # 5. Actualizar nuestra BD (con o sin Stripe)
    payment.status = models.PaymentStatus.RELEASED  # type: ignore
    contract.status = "completed"  # type: ignore

    db.commit()
    db.refresh(payment)
    return payment


def _transfer_to_worker(db: Session, job, payment):
    """
    Transfiere los fondos capturados desde la cuenta de la plataforma
    a la cuenta Stripe Connect Express del trabajador.
    Si el worker no tiene Stripe configurado, los fondos quedan retenidos
    en la plataforma y se registra una advertencia.
    """
    from app.auth.models import User

    worker = db.query(User).filter(User.id == job.provider_id).first()
    if not worker or not worker.stripe_account_id:
        logger.warning(
            f"Worker {job.provider_id} no tiene cuenta Stripe Connect. "
            f"Fondos ${payment.amount} retenidos en la plataforma."
        )
        return

    try:
        stripe.Transfer.create(
            amount=payment.amount_cents,
            currency="mxn",
            destination=worker.stripe_account_id,
            transfer_group=f"payment_{payment.id}",
        )
        logger.info(
            f"Transferencia exitosa de ${payment.amount} al worker "
            f"{worker.id} (Stripe account: {worker.stripe_account_id})"
        )
    except stripe.error.StripeError as e:
        logger.error(
            f"Error al transferir ${payment.amount} al worker {worker.id}: {e}"
        )


def get_payment(db: Session, payment_id: str):
    return db.query(models.Payment).filter(models.Payment.id == payment_id).first()


def get_payments_by_role(db: Session, current_user):
    """Filtra el historial de pagos según el rol del usuario logueado."""
    from sqlalchemy.orm import joinedload

    base_query = db.query(models.Payment).options(
        joinedload(models.Payment.contract).joinedload(models.Contract.job)
    )

    if current_user.role == "admin":
        payments = base_query.all()
    elif current_user.role == "client":
        payments = base_query\
            .join(models.Contract)\
            .filter(models.Contract.client_id == current_user.id)\
            .all()
    elif current_user.role == "worker":
        payments = base_query\
            .join(models.Contract)\
            .filter(models.Contract.job.has(Job.provider_id == current_user.id))\
            .all()
    else:
        return []

    result = []
    for payment in payments:
        status_val = payment.status.value if hasattr(payment.status, 'value') else payment.status
        payment_dict = {
            "id": payment.id,
            "contract_id": payment.contract_id,
            "amount": payment.amount,
            "amount_cents": payment.amount_cents,
            "status": status_val,
            "payment_method": payment.payment_method,
            "stripe_payment_intent_id": payment.stripe_payment_intent_id,
            "created_at": payment.created_at,
            "service_title": None,
            "service_description": None,
            "service_category": None,
        }
        contract = payment.contract
        if contract and contract.job:
            job = contract.job
            if job.request and job.request.service:
                svc = job.request.service
                payment_dict["service_title"] = svc.title
                payment_dict["service_description"] = svc.description
                payment_dict["service_category"] = svc.category.name if svc.category else None
        result.append(payment_dict)

    return result


def get_contracts_by_role(db: Session, current_user):
    """Obtiene contratos con la información del Job cargada."""
    query = db.query(models.Contract).options(joinedload(models.Contract.job))

    if current_user.role == "admin":
        return query.all()
    
    return query.filter(models.Contract.client_id == current_user.id).all()


def refund_payment(db: Session, payment_id: str):
    """
    Realiza un reembolso en Stripe y actualiza el estado en la BD.
    Se usa en disputas o cancelaciones justificadas.
    """
    payment = db.query(models.Payment).filter(models.Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Pago no encontrado")

    if payment.status == models.PaymentStatus.REFUNDED:
        return payment

    # 1. Reembolsar en Stripe
    try:
        if payment.stripe_payment_intent_id:
            print(f"[REFUND] Stripe intent ID: {payment.stripe_payment_intent_id}", flush=True)
            intent = stripe.PaymentIntent.retrieve(payment.stripe_payment_intent_id)
            print(f"[REFUND] Stripe intent status: {intent.status}", flush=True)
            if intent.status == "requires_capture":
                print(f"[REFUND] Cancelando PaymentIntent...", flush=True)
                stripe.PaymentIntent.cancel(payment.stripe_payment_intent_id)
                print(f"[REFUND] PaymentIntent cancelado exitosamente", flush=True)
            else:
                print(f"[REFUND] Creando refund para PaymentIntent...", flush=True)
                stripe.Refund.create(payment_intent=payment.stripe_payment_intent_id)
                print(f"[REFUND] Refund creado exitosamente", flush=True)
    except stripe.error.StripeError as e:
        print(f"[REFUND] ERROR DE STRIPE: {e}", flush=True)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error al procesar reembolso en Stripe: {str(e)}"
        )

    # 2. Actualizar BD
    payment.status = models.PaymentStatus.REFUNDED # type: ignore
    
    contract = db.query(models.Contract).filter(models.Contract.id == payment.contract_id).first()
    if contract:
        contract.status = "cancelled" # type: ignore

    # 3. Buscar el Job para notificar
    job = None
    if contract:
        job = db.query(Job).filter(Job.id == contract.job_id).first()

    db.commit()
    db.refresh(payment)

    if job:
        from app.services.notifications.service import notify_payment_refunded
        notify_payment_refunded(db, job)

    return payment


def resolve_dispute(db: Session, conversation_id: str, resolution: str):
    """
    Resuelve una disputa. 
    resolution: 'refund' (devuelve al cliente) o 'release' (paga al trabajador).
    """
    from app.services.models import Conversation, ConversationStatus
    
    convo = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")

    # Buscar el Job asociado a través del request
    if not convo.request or not convo.request.job:
        raise HTTPException(status_code=404, detail="No hay un trabajo asociado a este chat")
    
    job = convo.request.job
    
    # Buscar el pago asociado
    contract = db.query(models.Contract).filter(
        models.Contract.job_id == job.id
    ).first()
    if not contract:
        raise HTTPException(status_code=404, detail="No se encontró un contrato para este trabajo")
    
    payment = db.query(models.Payment).filter(
        models.Payment.contract_id == contract.id,
        models.Payment.status == models.PaymentStatus.HELD_IN_ESCROW
    ).first()

    if resolution == "refund":
        if payment:
            refund_payment(db, payment.id)
        job.status = JobStatus.CANCELLED # type: ignore
    elif resolution == "release":
        if payment:
            capture_payment(db, job.id)
        job.status = JobStatus.COMPLETED # type: ignore
    else:
        raise HTTPException(status_code=400, detail="Resolución inválida. Use 'refund' o 'release'")

    convo.status = ConversationStatus.CLOSED.value # type: ignore
    db.commit()
    
    return {"status": "success", "message": f"Disputa resuelta como: {resolution}"}