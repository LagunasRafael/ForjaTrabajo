from sqlalchemy.orm import Session
from datetime import datetime
from app.services import models as service_models
from app.payments import models as payment_models
from app.payments.services import capture_payment, refund_payment
from app.services.notifications.service import notify_payment_expired, notify_auto_released
from app.services.chats.service import close_chat
import stripe
import logging

logger = logging.getLogger(__name__)


def process_expired_payments(db: Session):
    """
    Revisa y procesa trabajos expirados:
    - Feature 2: Cancela trabajos en MATCHED cuyo payment_due_at haya vencido
    - Feature 9: Libera pago automaticamente si auto_release_at vencio
    """
    now = datetime.utcnow()
    results = {"cancelled": 0, "auto_released": 0}

    cancelled = _cancel_unpaid_jobs(db, now)
    results["cancelled"] = cancelled

    auto_released = _auto_release_jobs(db, now)
    results["auto_released"] = auto_released

    if cancelled > 0 or auto_released > 0:
        logger.info(
            f"Expiración: {cancelled} cancelados por falta de pago, "
            f"{auto_released} liberados automáticamente"
        )

    return results


def _cancel_unpaid_jobs(db: Session, now: datetime) -> int:
    jobs = db.query(service_models.Job).filter(
        service_models.Job.status == service_models.JobStatus.MATCHED,
        service_models.Job.payment_due_at.isnot(None),
        service_models.Job.payment_due_at < now,
    ).all()

    count = 0
    for job in jobs:
        try:
            # Cancelar PaymentIntent en Stripe si existe
            contract = db.query(payment_models.Contract).filter(
                payment_models.Contract.job_id == job.id
            ).first()
            if contract:
                payments = db.query(payment_models.Payment).filter(
                    payment_models.Payment.contract_id == contract.id,
                    payment_models.Payment.status.in_([
                        payment_models.PaymentStatus.PENDING,
                        payment_models.PaymentStatus.HELD_IN_ESCROW
                    ])
                ).all()
                for payment in payments:
                    if payment.stripe_payment_intent_id:
                        try:
                            intent = stripe.PaymentIntent.retrieve(payment.stripe_payment_intent_id)
                            if intent.status in ("requires_payment_method", "requires_confirmation", "requires_capture"):
                                stripe.PaymentIntent.cancel(payment.stripe_payment_intent_id)
                        except Exception:
                            pass
                    payment.status = payment_models.PaymentStatus.FAILED

            job.status = service_models.JobStatus.CANCELLED
            job.payment_due_at = None
            
            # Marcar la postulación seleccionada como expirada
            if job.request:
                job.request.status = "expired"
                if job.request.service:
                    job.request.service.status = service_models.JobStatus.OPEN
                    job.request.service.is_active = True
                    
            db.commit()

            # Notificar al cliente y al trabajador
            notify_payment_expired(db, job)

            # Cerrar el chat del trabajador seleccionado
            try:
                if job.request:
                    convo = db.query(service_models.Conversation).filter(
                        service_models.Conversation.request_id == job.request.id
                    ).first()
                    if convo and convo.status != service_models.ConversationStatus.CLOSED.value:
                        close_chat(db, str(convo.id), service_models.ClosedReason.CLIENT_PAYMENT_TIMEOUT.value)
            except Exception:
                pass

            count += 1
        except Exception as e:
            logger.error(f"Error cancelando job {job.id} por expiración: {e}")
            db.rollback()

    return count


def _auto_release_jobs(db: Session, now: datetime) -> int:
    jobs = db.query(service_models.Job).filter(
        service_models.Job.status == service_models.JobStatus.WAITING_CONFIRMATION,
        service_models.Job.auto_release_at.isnot(None),
        service_models.Job.auto_release_at < now,
    ).all()

    count = 0
    for job in jobs:
        try:
            capture_payment(db, str(job.id))
            job.status = service_models.JobStatus.COMPLETED
            job.completed_at = now
            job.auto_release_at = None
            if job.request and job.request.service:
                job.request.service.status = service_models.JobStatus.COMPLETED
                job.request.service.is_active = False

            # Cerrar el chat
            try:
                if job.request:
                    convo = db.query(service_models.Conversation).filter(
                        service_models.Conversation.request_id == job.request.id
                    ).first()
                    if convo and convo.status != service_models.ConversationStatus.CLOSED.value:
                        close_chat(db, str(convo.id), service_models.ClosedReason.SERVICE_COMPLETED_AUTO.value)
            except Exception:
                pass

            db.commit()

            notify_auto_released(db, job)

            count += 1
        except Exception as e:
            logger.error(f"Error liberando job {job.id} automáticamente: {e}")
            db.rollback()

    return count
