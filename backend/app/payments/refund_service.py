import logging
import uuid
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.payments.stripe_client import stripe
from . import models
from app.services.models import Job

logger = logging.getLogger(__name__)


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

    if payment.status in (models.PaymentStatus.RELEASED, models.PaymentStatus.COMPLETED):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se puede reembolsar un pago que ya fue liberado al trabajador."
        )

    try:
        if payment.stripe_payment_intent_id:
            logger.info("Refund: Stripe intent ID: %s", payment.stripe_payment_intent_id)
            intent = stripe.PaymentIntent.retrieve(payment.stripe_payment_intent_id)
            logger.info("Refund: Stripe intent status: %s", intent.status)
            if intent.status == "requires_capture":
                logger.info("Refund: Cancelando PaymentIntent...")
                stripe.PaymentIntent.cancel(
                    payment.stripe_payment_intent_id,
                    idempotency_key=f"cancel_refund_{payment.id}_{uuid.uuid4().hex}",
                )
                logger.info("Refund: PaymentIntent cancelado exitosamente")
            else:
                logger.info("Refund: Creando refund para PaymentIntent...")
                stripe.Refund.create(
                    payment_intent=payment.stripe_payment_intent_id,
                    idempotency_key=f"refund_{payment.id}_{uuid.uuid4().hex}",
                )
                logger.info("Refund: Refund creado exitosamente")
    except stripe.error.StripeError as e:
        logger.error("Refund: Error Stripe: %s", e)
        error_msg = str(e).lower()
        if "does not have a successful charge to refund" in error_msg or "no such payment_intent" in error_msg:
            logger.info("Refund: Stripe indica que no hay cargo exitoso, actualizando solo BD")
        else:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Error al procesar reembolso en Stripe: {str(e)}"
            )

    payment.status = models.PaymentStatus.REFUNDED

    contract = db.query(models.Contract).filter(models.Contract.id == payment.contract_id).first()
    if contract:
        contract.status = "cancelled"

    job = None
    if contract:
        job = db.query(Job).filter(Job.id == contract.job_id).first()

    db.commit()
    db.refresh(payment)

    if job:
        from app.services.notifications.service import notify_payment_refunded
        notify_payment_refunded(db, job)

    return payment
