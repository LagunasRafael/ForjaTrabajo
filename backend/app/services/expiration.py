from sqlalchemy.orm import Session
from datetime import datetime
from app.services import models as service_models
from app.payments import models as payment_models
from app.payments.services import capture_payment, refund_payment
from app.services.notifications.service import notify_payment_expired, notify_auto_released
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
            job.status = service_models.JobStatus.CANCELLED
            if job.request and job.request.service:
                job.request.service.status = service_models.JobStatus.OPEN
                job.request.service.is_active = True
            job.payment_due_at = None
            db.commit()

            notify_payment_expired(db, job)

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
            db.commit()

            notify_auto_released(db, job)

            count += 1
        except Exception as e:
            logger.error(f"Error liberando job {job.id} automáticamente: {e}")
            db.rollback()

    return count
