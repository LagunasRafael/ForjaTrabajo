from sqlalchemy.orm import Session
from app.services import models
from app.auth import models as auth_models
from app.utils.notifications import send_push_notification
from app.services.notifications.base_service import create_in_app_notification
import logging

logger = logging.getLogger(__name__)


def notify_job_accepted(db: Session, job: models.Job, service_title: str, conversation_id: str = None):
    try:
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()
        if worker:
            title = "Fuiste aceptado!"
            body = f"El cliente acepto tu propuesta para: {service_title}"

            create_in_app_notification(
                db=db, user_id=str(worker.id), title=title, body=body,
                notification_type="job_accepted", reference_id=str(job.id),
                target_role="worker"
            )

            if worker.fcm_token:
                data = {
                    "type": "job_accepted",
                    "job_id": str(job.id),
                    "service_title": service_title,
                    "target_role": "worker"
                }
                if conversation_id:
                    data["conversation_id"] = str(conversation_id)

                send_push_notification(
                    fcm_token=str(worker.fcm_token),
                    title=title,
                    body=body,
                    data=data
                )
    except Exception as e:
        logger.warning("Error en notify_job_accepted: %s", e)


def notify_job_completed(db: Session, job: models.Job):
    try:
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()
        if worker:
            title = "Trabajo finalizado"
            body = "El cliente confirmo la finalizacion del trabajo"

            create_in_app_notification(
                db=db, user_id=str(worker.id), title=title, body=body,
                notification_type="job_completed", reference_id=str(job.id),
                target_role="worker"
            )

            if worker.fcm_token:
                send_push_notification(
                    fcm_token=str(worker.fcm_token),
                    title=title,
                    body=body,
                    data={
                        "type": "job_completed",
                        "job_id": str(job.id),
                        "target_role": "worker"
                    }
                )
    except Exception as e:
        logger.warning("Error en notify_job_completed: %s", e)


def notify_job_waiting_confirmation(db: Session, job: models.Job):
    try:
        client = db.query(auth_models.User).filter(auth_models.User.id == job.client_id).first()
        if client:
            title = "Trabajo terminado"
            body = "El trabajador ha marcado como finalizado el servicio. Por favor, confirma la entrega."

            create_in_app_notification(
                db=db, user_id=str(client.id), title=title, body=body,
                notification_type="job_waiting_confirmation", reference_id=str(job.id),
                target_role="client"
            )

            if client.fcm_token:
                send_push_notification(
                    fcm_token=str(client.fcm_token),
                    title=title,
                    body=body,
                    data={
                        "type": "job_waiting_confirmation",
                        "job_id": str(job.id),
                        "target_role": "client"
                    }
                )
    except Exception as e:
        logger.warning("Error en notify_job_waiting_confirmation: %s", e)


def notify_job_cancelled(db: Session, job: models.Job, cancelled_by_id: str):
    try:
        if str(job.client_id) == str(cancelled_by_id):
            receiver_id = str(job.provider_id)
            role_canceller = "El cliente"
        else:
            receiver_id = str(job.client_id)
            role_canceller = "El trabajador"

        receiver = db.query(auth_models.User).filter(auth_models.User.id == receiver_id).first()
        if receiver:
            title = "Trabajo cancelado"
            body = f"{role_canceller} cancelo el trabajo."

            create_in_app_notification(
                db=db, user_id=receiver_id, title=title, body=body,
                notification_type="job_cancelled", reference_id=str(job.id),
                target_role="client" if role_canceller == "El trabajador" else "worker"
            )

            if receiver.fcm_token:
                receiver_role_push = "client" if role_canceller == "El trabajador" else "worker"
                send_push_notification(
                    fcm_token=str(receiver.fcm_token),
                    title=title,
                    body=body,
                    data={
                        "type": "job_cancelled",
                        "job_id": str(job.id),
                        "target_role": receiver_role_push
                    }
                )
    except Exception as e:
        logger.warning("Error en notify_job_cancelled: %s", e)


def notify_auto_released(db: Session, job: models.Job):
    try:
        client = db.query(auth_models.User).filter(auth_models.User.id == job.client_id).first()
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()

        if worker:
            create_in_app_notification(
                db=db, user_id=str(worker.id),
                title="Pago liberado automaticamente",
                body="El cliente no respondio a tiempo. El pago ha sido liberado automaticamente.",
                notification_type="auto_released", reference_id=str(job.id),
                target_role="worker"
            )
            if worker.fcm_token:
                send_push_notification(
                    fcm_token=str(worker.fcm_token), title="Pago liberado",
                    body="El cliente no respondio. El pago se libero automaticamente a tu cuenta.",
                    data={"type": "auto_released", "job_id": str(job.id), "target_role": "worker"}
                )

        if client:
            create_in_app_notification(
                db=db, user_id=str(client.id),
                title="Pago liberado automaticamente",
                body="El pago del trabajo fue liberado automaticamente al trabajador por falta de respuesta.",
                notification_type="auto_released", reference_id=str(job.id),
                target_role="client"
            )
            if client.fcm_token:
                send_push_notification(
                    fcm_token=str(client.fcm_token), title="Pago liberado",
                    body="El pago fue liberado automaticamente al trabajador porque no confirmaste a tiempo.",
                    data={"type": "auto_released", "job_id": str(job.id), "target_role": "client"}
                )
    except Exception as e:
        logger.warning("Error en notify_auto_released: %s", e)
