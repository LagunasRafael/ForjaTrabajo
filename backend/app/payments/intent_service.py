import logging
import uuid
from datetime import datetime
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.payments.stripe_client import stripe
from . import models, schemas
from app.services.models import Job, JobStatus, ServiceRequest
from .commission_service import get_commission_rate

logger = logging.getLogger(__name__)


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

    db_contract.status = "in_progress"

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
    job = db.query(Job).filter(Job.id == job_id).first()

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
        if existing_payment.stripe_payment_intent_id:
            try:
                stripe.PaymentIntent.cancel(existing_payment.stripe_payment_intent_id)
            except stripe.error.StripeError as e:
                logger.error("Error cancelando PaymentIntent previo %s: %s", existing_payment.stripe_payment_intent_id, e)
        existing_payment.status = models.PaymentStatus.FAILED
        db.commit()

    amount_cents = int(amount * 100)

    logger.info("Creando PaymentIntent para Job: %s, Amount: %d cents", job.id, amount_cents)
    try:
        intent = stripe.PaymentIntent.create(
            amount=amount_cents,
            currency="mxn",
            capture_method="manual",
            idempotency_key=f"create_intent_{job.id}_{uuid.uuid4().hex}",
            metadata={
                "job_id": str(job.id),
                "contract_id": str(contract.id)
            }
        )
        logger.info("PaymentIntent creado exitosamente: %s", intent.id)
    except stripe.error.StripeError as e:
        logger.error("Error Stripe creando PaymentIntent: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error al crear PaymentIntent en Stripe: {str(e)}"
        )

    fee_rate = get_commission_rate(db)
    fee_cents = int(amount_cents * fee_rate)
    fee_amount = round(fee_cents / 100, 2)

    db_payment = models.Payment(
        contract_id=contract.id,
        amount=amount,
        amount_cents=amount_cents,
        platform_fee=fee_amount,
        platform_fee_cents=fee_cents,
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

    logger.info("Confirmando escrow para Intent: %s", payment_intent_id)
    try:
        intent = stripe.PaymentIntent.retrieve(payment_intent_id)
        logger.info("Estado de Intent en Stripe: %s", intent.status)
        if intent.status != "requires_capture":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Stripe: el PaymentIntent no está listo para retener. Estado: {intent.status}"
            )
    except stripe.error.StripeError as e:
        logger.error("Error Stripe al recuperar intent: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error al consultar Stripe: {str(e)}"
        )

    payment.status = models.PaymentStatus.HELD_IN_ESCROW

    if payment.platform_fee == 0 or payment.platform_fee is None:
        fee_rate = get_commission_rate(db)
        fee_cents = int(payment.amount_cents * fee_rate)
        payment.platform_fee = round(fee_cents / 100, 2)
        payment.platform_fee_cents = fee_cents

    contract = db.query(models.Contract).filter(
        models.Contract.id == payment.contract_id
    ).first()
    if contract:
        contract.status = "in_progress"
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
        logger.warning("Error notificando pago retenido: %s", e)

    return payment
