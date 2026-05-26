from sqlalchemy.orm import Session
from app.auth import models as auth_models
from app.utils.notifications import send_push_notification
from app.services.notifications.base_service import create_in_app_notification
import logging

logger = logging.getLogger(__name__)


def notify_dispute_opened(db: Session, conversation_id: str, client: auth_models.User, worker: auth_models.User):
    """Create in-app notification and push for both parties when a dispute is opened."""
    dispute_msg = "Este chat ha entrado en disputa y un administrador intervendra pronto."

    for user in [client, worker]:
        if not user:
            continue
        role = "client" if str(user.id) == str(client.id) else "worker"
        create_in_app_notification(
            db=db, user_id=str(user.id),
            title="Disputa Iniciada",
            body=dispute_msg,
            notification_type="dispute_opened",
            reference_id=conversation_id,
            target_role=role
        )
        if user.fcm_token:
            send_push_notification(
                fcm_token=str(user.fcm_token),
                title="Disputa Iniciada",
                body=dispute_msg,
                data={
                    "type": "dispute_opened",
                    "conversation_id": conversation_id,
                    "sender_name": "Sistema"
                }
            )


def notify_admin_dispute_message(db: Session, conversation_id: str, client: auth_models.User, worker: auth_models.User, content: str):
    """Create in-app notification and push when admin sends a message in a dispute."""
    preview = content[:60] + "..." if len(content) > 60 else content

    for user in [client, worker]:
        if not user:
            continue
        role = "client" if str(user.id) == str(client.id) else "worker"
        create_in_app_notification(
            db=db, user_id=str(user.id),
            title="Soporte Forja",
            body=preview,
            notification_type="admin_message",
            reference_id=conversation_id,
            target_role=role
        )
        if user.fcm_token:
            send_push_notification(
                fcm_token=str(user.fcm_token),
                title="Soporte Forja",
                body=preview,
                data={
                    "type": "new_message",
                    "conversation_id": conversation_id,
                    "sender_name": "Soporte Forja"
                }
            )


def notify_dispute_resolved(
    db: Session,
    conversation_id: str,
    winner_role: str,
    client: auth_models.User,
    worker: auth_models.User,
    resolution_msg: str
):
    """Create in-app notification and push when dispute is resolved."""
    if winner_role == "client":
        push_type = "job_cancelled"
        title = "Resolucion de Trabajo"
    elif winner_role == "worker":
        push_type = "job_completed"
        title = "Resolucion de Trabajo"
    else:
        push_type = "dispute_continued"
        title = "Disputa Cerrada"

    for user in [client, worker]:
        if not user:
            continue
        role = "client" if str(user.id) == str(client.id) else "worker"
        create_in_app_notification(
            db=db, user_id=str(user.id),
            title=title,
            body=resolution_msg,
            notification_type=push_type,
            reference_id=conversation_id,
            target_role=role
        )
        if user.fcm_token:
            send_push_notification(
                fcm_token=str(user.fcm_token),
                title=title,
                body=resolution_msg,
                data={
                    "type": push_type,
                    "conversation_id": conversation_id,
                    "sender_name": "Soporte Forja"
                }
            )
