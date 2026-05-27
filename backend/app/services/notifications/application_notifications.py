from sqlalchemy.orm import Session
from app.services import models
from app.auth import models as auth_models
from app.utils.notifications import send_push_notification
from app.services.notifications.base_service import create_in_app_notification
import logging

logger = logging.getLogger(__name__)


def notify_new_application(db: Session, service_entry: models.Service, worker: auth_models.User):
    try:
        client = db.query(auth_models.User).filter(auth_models.User.id == service_entry.client_id).first()
        if client:
            request_count = db.query(models.ServiceRequest).filter(
                models.ServiceRequest.service_id == service_entry.id
            ).count()

            if request_count <= 1:
                title = "Nueva postulacion recibida"
                body = f"{worker.full_name} se postulo a: {service_entry.title}"
            else:
                title = "Postulaciones recibidas"
                body = f"{request_count} personas se han postulado a: {service_entry.title}"

            existing_notif = db.query(models.Notification).filter(
                models.Notification.user_id == str(client.id),
                models.Notification.notification_type == "new_application",
                models.Notification.reference_id == str(service_entry.id),
                models.Notification.is_read == False
            ).first()

            if existing_notif:
                existing_notif.title = title
                existing_notif.body = body
                db.commit()
            else:
                create_in_app_notification(
                    db=db, user_id=str(client.id), title=title, body=body,
                    notification_type="new_application", reference_id=str(service_entry.id),
                    target_role="client"
                )

            if client.fcm_token:
                send_push_notification(
                    fcm_token=str(client.fcm_token),
                    title=title,
                    body=body,
                    data={
                        "type": "new_application",
                        "service_id": str(service_entry.id),
                        "service_title": service_entry.title,
                        "target_role": "client"
                    }
                )
    except Exception as e:
        logger.warning("Error en notify_new_application: %s", e)
