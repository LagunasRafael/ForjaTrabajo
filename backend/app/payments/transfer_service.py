import logging
import uuid
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.payments.stripe_client import stripe
from . import models
from app.services.models import Job, JobStatus, ServiceRequest
from .commission_service import get_commission_rate

logger = logging.getLogger(__name__)


def capture_payment(db: Session, job_id: str):
    """
    Captura los fondos retenidos en Stripe cuando el trabajo se completa.
    Busca el Payment asociado al job y llama a PaymentIntent.capture().
    """
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        job = db.query(Job).join(ServiceRequest).filter(ServiceRequest.service_id == job_id).first()

    if not job:
        return None

    contract = db.query(models.Contract).filter(
        models.Contract.job_id == job.id
    ).first()

    if not contract:
        return None

    payment = db.query(models.Payment).filter(
        models.Payment.contract_id == contract.id,
        models.Payment.status.in_([
            models.PaymentStatus.HELD_IN_ESCROW,
            models.PaymentStatus.PENDING_TRANSFER,
        ])
    ).first()

    if not payment:
        return None

    if payment.stripe_payment_intent_id and payment.status == models.PaymentStatus.HELD_IN_ESCROW:
        try:
            logger.info("Capturando PaymentIntent: %s", payment.stripe_payment_intent_id)
            captured_intent = stripe.PaymentIntent.capture(
                str(payment.stripe_payment_intent_id),
                idempotency_key=f"capture_{payment.stripe_payment_intent_id}_{uuid.uuid4().hex}",
            )
            logger.info("Capture exitoso, status: %s", captured_intent.status)
        except stripe.error.StripeError as e:
            logger.error("Error Stripe al capturar: %s", e)
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Error al capturar pago en Stripe: {str(e)}"
            )

        logger.info("Iniciando transferencia al worker...")
        _transfer_to_worker(db, job, payment)

    elif payment.status == models.PaymentStatus.PENDING_TRANSFER:
        logger.info("PaymentIntent ya capturado, reintentando transferencia...")
        _transfer_to_worker(db, job, payment)

    contract.status = "completed"

    db.commit()
    db.refresh(payment)
    return payment


def _transfer_to_worker(db: Session, job, payment):
    """
    Transfiere los fondos capturados desde la cuenta de la plataforma
    a la cuenta Stripe Connect Express del trabajador, descontando
    la comisión de la plataforma.
    Si el worker no tiene Stripe configurado O la transferencia falla,
    el pago queda como PENDING_TRANSFER y se reintenta automáticamente
    cuando el worker consulte su estado de Stripe.
    """
    from app.auth.models import User

    worker = db.query(User).filter(User.id == job.provider_id).first()
    if not worker or not worker.stripe_account_id:
        payment.status = models.PaymentStatus.PENDING_TRANSFER
        logger.info(
            f"Pago {payment.id} marcado como PENDING_TRANSFER — "
            f"el worker {job.provider_id} no tiene Stripe configurado"
        )
        return

    fee_rate = get_commission_rate(db)
    transfer_cents = payment.amount_cents - int(payment.amount_cents * fee_rate)
    transfer_amount = round(transfer_cents / 100, 2)

    try:
        stripe.Transfer.create(
            amount=transfer_cents,
            currency="mxn",
            destination=worker.stripe_account_id,
            transfer_group=f"payment_{payment.id}",
            idempotency_key=f"transfer_{payment.id}_{uuid.uuid4().hex}",
        )
        payment.status = models.PaymentStatus.RELEASED
        logger.info(
            f"Transferencia de ${transfer_amount} al worker "
            f"{worker.id} (comisión ${payment.platform_fee or 0})"
        )
    except stripe.error.StripeError as e:
        payment.status = models.PaymentStatus.PENDING_TRANSFER
        logger.error(
            f"Error al transferir ${transfer_amount} al worker {worker.id}: {e}. "
            f"Pago {payment.id} marcado como PENDING_TRANSFER para reintento."
        )


def process_pending_transfers_for_worker(db: Session, worker_id: str):
    """
    Cuando un worker configura su Stripe Connect, procesa todos los pagos
    que quedaron pendientes de transferir (PENDING_TRANSFER).
    """
    from app.auth.models import User

    worker = db.query(User).filter(User.id == worker_id).first()
    if not worker or not worker.stripe_account_id:
        return

    pending_payments = (
        db.query(models.Payment)
        .join(models.Contract)
        .join(Job, models.Contract.job_id == Job.id)
        .filter(
            Job.provider_id == worker_id,
            models.Payment.status == models.PaymentStatus.PENDING_TRANSFER,
        )
        .all()
    )

    if not pending_payments:
        logger.info(f"No hay pagos pendientes para el worker {worker_id}")
        return

    fee_rate = get_commission_rate(db)
    for payment in pending_payments:
        try:
            fee_cents = int(payment.amount_cents * fee_rate)
            transfer_cents = payment.amount_cents - fee_cents
            stripe.Transfer.create(
                amount=transfer_cents,
                currency="mxn",
                destination=worker.stripe_account_id,
                transfer_group=f"payment_{payment.id}",
                idempotency_key=f"pending_transfer_{payment.id}_{uuid.uuid4().hex}",
            )
            payment.platform_fee = round(fee_cents / 100, 2)
            payment.platform_fee_cents = fee_cents
            payment.status = models.PaymentStatus.RELEASED
            contract = payment.contract
            if contract:
                contract.status = "completed"
            logger.info(
                f"Transferencia pendiente completada para pago {payment.id} "
                f"(${round(transfer_cents / 100, 2)} al worker, "
                f"comisión ${payment.platform_fee})"
            )
        except stripe.error.StripeError as e:
            logger.error(
                f"Error al procesar transferencia pendiente "
                f"para pago {payment.id}: {e}"
            )

    db.commit()
