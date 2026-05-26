from sqlalchemy.orm import Session
from app.services import models
from app.auth import models as auth_models
from app.utils.notifications import send_push_notification
from app.services.notifications.base_service import create_in_app_notification
import logging

logger = logging.getLogger(__name__)


def notify_payment_made(db: Session, worker_id: str, amount: float, service_title: str, job_id: str = None):
    try:
        worker = db.query(auth_models.User).filter(auth_models.User.id == worker_id).first()
        if worker:
            title = "Pago recibido"
            body = f"Recibiste ${amount:.2f} por: {service_title}"

            create_in_app_notification(
                db=db, user_id=str(worker.id), title=title, body=body,
                notification_type="payment_released", reference_id=job_id or str(worker.id),
                target_role="worker"
            )

            if worker.fcm_token:
                send_push_notification(
                    fcm_token=str(worker.fcm_token),
                    title=title,
                    body=body,
                    data={
                        "type": "payment_released",
                        "job_id": job_id or "",
                        "amount": str(amount),
                        "service_title": service_title,
                        "target_role": "worker"
                    }
                )
    except Exception as e:
        logger.warning("Error en notify_payment_made: %s", e)


def notify_escrow_confirmed(db: Session, worker_id: str, amount: float, service_title: str, job_id: str = None):
    try:
        worker = db.query(auth_models.User).filter(auth_models.User.id == worker_id).first()
        if worker:
            title = "Pago recibido"
            body = f'El cliente ya realizo el pago por el servicio "{service_title}". Puedes comenzar el trabajo.'

            create_in_app_notification(
                db=db, user_id=str(worker.id), title=title, body=body,
                notification_type="payment_held", reference_id=job_id or str(worker.id),
                target_role="worker"
            )

            if worker.fcm_token:
                send_push_notification(
                    fcm_token=str(worker.fcm_token),
                    title=title,
                    body=body,
                    data={
                        "type": "payment_held",
                        "job_id": job_id or "",
                        "amount": str(amount),
                        "service_title": service_title,
                        "target_role": "worker"
                    }
                )
    except Exception as e:
        logger.warning("Error en notify_escrow_confirmed: %s", e)


def notify_client_payment_deadline(db: Session, job: models.Job, payment_due_minutes: int):
    try:
        client = db.query(auth_models.User).filter(auth_models.User.id == job.client_id).first()
        if client:
            hours = payment_due_minutes // 60
            if hours > 0:
                time_str = f"{hours} horas"
            else:
                time_str = f"{payment_due_minutes} minutos"
            title = "Plazo para realizar el pago"
            body = f"Tienes {time_str} para pagar el trabajo. Si no pagas a tiempo, se cancelara automaticamente."

            create_in_app_notification(
                db=db, user_id=str(client.id), title=title, body=body,
                notification_type="payment_deadline", reference_id=str(job.id),
                target_role="client"
            )
            if client.fcm_token:
                send_push_notification(
                    fcm_token=str(client.fcm_token), title=title, body=body,
                    data={"type": "payment_deadline", "job_id": str(job.id), "target_role": "client"}
                )
    except Exception as e:
        logger.warning("Error en notify_client_payment_deadline: %s", e)


def notify_worker_confirmation_deadline(db: Session, job: models.Job, auto_release_minutes: int):
    try:
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()
        if worker:
            hours = auto_release_minutes // 60
            if hours > 0:
                time_str = f"{hours} horas"
            else:
                time_str = f"{auto_release_minutes} minutos"
            title = "Esperando confirmacion del cliente"
            body = f"Marcaste el trabajo como terminado. El cliente tiene {time_str} para confirmar. Si no responde, el pago se liberara automaticamente."

            create_in_app_notification(
                db=db, user_id=str(worker.id), title=title, body=body,
                notification_type="confirmation_deadline", reference_id=str(job.id),
                target_role="worker"
            )
            if worker.fcm_token:
                send_push_notification(
                    fcm_token=str(worker.fcm_token), title=title, body=body,
                    data={"type": "confirmation_deadline", "job_id": str(job.id), "target_role": "worker"}
                )
    except Exception as e:
        logger.warning("Error en notify_worker_confirmation_deadline: %s", e)


def notify_payment_expired(db: Session, job: models.Job):
    try:
        client = db.query(auth_models.User).filter(auth_models.User.id == job.client_id).first()
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()

        if client:
            create_in_app_notification(
                db=db, user_id=str(client.id),
                title="Plazo de pago vencido",
                body="El plazo para pagar el trabajo ha expirado. El trabajo ha sido cancelado.",
                notification_type="payment_expired", reference_id=str(job.id),
                target_role="client"
            )
            if client.fcm_token:
                send_push_notification(
                    fcm_token=str(client.fcm_token), title="Plazo de pago vencido",
                    body="El trabajo fue cancelado porque no se realizo el pago a tiempo.",
                    data={"type": "payment_expired", "job_id": str(job.id), "target_role": "client"}
                )

        if worker:
            create_in_app_notification(
                db=db, user_id=str(worker.id),
                title="Trabajo cancelado por falta de pago",
                body="El cliente no realizo el pago a tiempo. El trabajo ha sido cancelado.",
                notification_type="payment_expired", reference_id=str(job.id),
                target_role="worker"
            )
            if worker.fcm_token:
                send_push_notification(
                    fcm_token=str(worker.fcm_token), title="Trabajo cancelado",
                    body="El cliente no pago a tiempo. El trabajo fue cancelado.",
                    data={"type": "payment_expired", "job_id": str(job.id), "target_role": "worker"}
                )
    except Exception as e:
        logger.warning("Error en notify_payment_expired: %s", e)


def notify_payment_refunded(db: Session, job: models.Job):
    try:
        client = db.query(auth_models.User).filter(auth_models.User.id == job.client_id).first()
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()

        if client:
            create_in_app_notification(
                db=db, user_id=str(client.id),
                title="Pago reembolsado",
                body="El pago del trabajo ha sido reembolsado exitosamente.",
                notification_type="payment_refunded", reference_id=str(job.id),
                target_role="client"
            )
            if client.fcm_token:
                send_push_notification(
                    fcm_token=str(client.fcm_token), title="Pago reembolsado",
                    body="El pago del trabajo ha sido reembolsado exitosamente.",
                    data={"type": "payment_refunded", "job_id": str(job.id), "target_role": "client"}
                )

        if worker:
            create_in_app_notification(
                db=db, user_id=str(worker.id),
                title="Pago reembolsado",
                body="El pago del trabajo ha sido reembolsado al cliente.",
                notification_type="payment_refunded", reference_id=str(job.id),
                target_role="worker"
            )
            if worker.fcm_token:
                send_push_notification(
                    fcm_token=str(worker.fcm_token), title="Pago reembolsado",
                    body="El pago del trabajo ha sido reembolsado al cliente.",
                    data={"type": "payment_refunded", "job_id": str(job.id), "target_role": "worker"}
                )
    except Exception as e:
        logger.warning("Error en notify_payment_refunded: %s", e)
