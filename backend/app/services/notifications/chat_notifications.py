from sqlalchemy.orm import Session
from app.services import models
from app.auth import models as auth_models
from app.utils.notifications import send_push_notification
from app.services.notifications.base_service import create_in_app_notification
import logging

logger = logging.getLogger(__name__)


def notify_new_message(db: Session, conversation_id: str, sender_id: str, content: str):
    try:
        convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
        if not convo:
            return

        receiver_id = str(convo.worker_id) if str(convo.client_id) == str(sender_id) else str(convo.client_id)
        receiver_role = "client" if str(convo.client_id) == receiver_id else "worker"
        sender = db.query(auth_models.User).filter(auth_models.User.id == str(sender_id)).first()
        receiver = db.query(auth_models.User).filter(auth_models.User.id == receiver_id).first()

        if receiver and receiver.fcm_token:
            title = f"Nuevo mensaje de {sender.full_name if sender else 'Chat'}"
            body = content if len(content) < 100 else content[:97] + "..."

            send_push_notification(
                fcm_token=str(receiver.fcm_token),
                title=title,
                body=body,
                data={
                    "type": "new_message",
                    "conversation_id": str(conversation_id),
                    "sender_name": sender.full_name if sender else "Chat",
                    "target_role": receiver_role
                }
            )
    except Exception as e:
        logger.warning("Error en notify_new_message: %s", e)


def notify_new_offer(db: Session, conversation_id: str, receiver_id: str, sender_id: str, amount: str):
    try:
        try:
            val = float(amount)
            if val.is_integer():
                amount = str(int(val))
            else:
                amount = f"{val:.2f}"
        except (ValueError, TypeError):
            pass

        receiver = db.query(auth_models.User).filter(auth_models.User.id == receiver_id).first()
        sender = db.query(auth_models.User).filter(auth_models.User.id == sender_id).first()
        if receiver:
            sender_name = sender.full_name if sender else "Alguien"
            title = "Nueva contraoferta"
            body = f"{sender_name} ha realizado una contraoferta de ${amount}"

            existing_notif = db.query(models.Notification).filter(
                models.Notification.user_id == str(receiver.id),
                models.Notification.notification_type == "new_offer",
                models.Notification.reference_id == str(conversation_id),
                models.Notification.is_read == False
            ).first()

            if existing_notif:
                from datetime import datetime
                existing_notif.title = title
                existing_notif.body = body
                existing_notif.created_at = datetime.utcnow()
                db.commit()
            else:
                create_in_app_notification(
                    db=db, user_id=str(receiver.id), title=title, body=body,
                    notification_type="new_offer", reference_id=str(conversation_id)
                )

            convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
            role = "client" if convo and str(convo.client_id) == str(receiver_id) else "worker"

            if receiver.fcm_token:
                send_push_notification(
                    fcm_token=str(receiver.fcm_token),
                    title=title,
                    body=body,
                    data={
                        "type": "new_offer",
                        "conversation_id": str(conversation_id),
                        "sender_name": sender_name,
                        "target_role": role
                    }
                )
    except Exception as e:
        logger.warning("Error en notify_new_offer: %s", e)


def notify_offer_responded(db: Session, conversation_id: str, receiver_id: str, sender_id: str, amount: str, action: str):
    try:
        try:
            val = float(amount)
            if val.is_integer():
                amount = str(int(val))
            else:
                amount = f"{val:.2f}"
        except (ValueError, TypeError):
            pass

        receiver = db.query(auth_models.User).filter(auth_models.User.id == receiver_id).first()
        sender = db.query(auth_models.User).filter(auth_models.User.id == sender_id).first()
        if receiver:
            sender_name = sender.full_name if sender else "La otra parte"
            if action == "accept":
                title = "Oferta aceptada"
                body = f"{sender_name} acepto tu contraoferta de ${amount}."
            elif action == "reject":
                title = "Oferta rechazada"
                body = f"{sender_name} rechazo tu contraoferta de ${amount}."
            else:
                title = "Oferta retirada"
                body = f"{sender_name} retiro la contraoferta de ${amount}."

            convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
            role = "client" if convo and str(convo.client_id) == str(receiver.id) else "worker"

            create_in_app_notification(
                db=db, user_id=str(receiver.id), title=title, body=body,
                notification_type="offer_responded", reference_id=str(conversation_id),
                target_role=role
            )

            if receiver.fcm_token:
                send_push_notification(
                    fcm_token=str(receiver.fcm_token),
                    title=title,
                    body=body,
                    data={
                        "type": "offer_responded",
                        "action": action,
                        "conversation_id": str(conversation_id),
                        "sender_name": sender_name,
                        "target_role": role
                    }
                )
    except Exception as e:
        logger.warning("Error en notify_offer_responded: %s", e)
