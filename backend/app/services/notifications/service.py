from sqlalchemy.orm import Session
from app.services import models
from app.auth import models as auth_models
from app.utils.notifications import send_push_notification
from fastapi import HTTPException
import logging

logger = logging.getLogger(__name__)

# ---------------------------------------------------------
# FUNCIONES BASE (CRUD)
# ---------------------------------------------------------

def create_in_app_notification(
    db: Session, 
    user_id: str, 
    title: str, 
    body: str, 
    notification_type: str, 
    reference_id: str = None
):
    """Guarda una notificación en la base de datos para el historial in-app."""
    try:
        new_notification = models.Notification(
            user_id=user_id,
            title=title,
            body=body,
            notification_type=notification_type,
            reference_id=reference_id
        )
        db.add(new_notification)
        db.commit()
        db.refresh(new_notification)
        return new_notification
    except Exception as e:
        logger.error(f"Error guardando notificación en BD: {e}")
        db.rollback()
        return None

# ---------------------------------------------------------
# MÉTODOS DE NEGOCIO (MIGRACIÓN DESDE OTROS SERVICIOS)
# ---------------------------------------------------------

def notify_new_application(db: Session, service_entry: models.Service, worker: auth_models.User):
    """Notifica al cliente que un trabajador se postuló a su servicio."""
    try:
        client = db.query(auth_models.User).filter(auth_models.User.id == service_entry.client_id).first()
        if client:
            # Contar cuántas postulaciones hay para este servicio
            request_count = db.query(models.ServiceRequest).filter(
                models.ServiceRequest.service_id == service_entry.id
            ).count()

            if request_count <= 1:
                title = "Nueva postulación recibida"
                body = f"{worker.full_name} se postuló a: {service_entry.title}"
            else:
                title = "Postulaciones recibidas"
                body = f"{request_count} personas se han postulado a: {service_entry.title}"
            
            # Buscar si ya hay una notificación de este tipo no leída para este servicio
            existing_notif = db.query(models.Notification).filter(
                models.Notification.user_id == str(client.id),
                models.Notification.notification_type == "new_application",
                models.Notification.reference_id == str(service_entry.id),
                models.Notification.is_read == False
            ).first()

            if existing_notif:
                # Si existe, la actualizamos para agruparlas
                existing_notif.title = title
                existing_notif.body = body
                # Se podría actualizar created_at aquí si quisiéramos que suba al principio
                db.commit()
            else:
                create_in_app_notification(
                    db=db, user_id=str(client.id), title=title, body=body,
                    notification_type="new_application", reference_id=str(service_entry.id)
                )
            
            if client.fcm_token:
                send_push_notification(
                    fcm_token=str(client.fcm_token),
                    title=title,
                    body=body,
                    data={
                        "type": "new_application", 
                        "service_id": str(service_entry.id),
                        "service_title": service_entry.title
                    }
                )
    except Exception as e:
        logger.warning(f"⚠️ Error en notify_new_application: {e}")

def notify_job_accepted(db: Session, job: models.Job, service_title: str, conversation_id: str = None):
    """Notifica al trabajador que su propuesta fue aceptada."""
    try:
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()
        if worker:
            title = "¡Fuiste aceptado!"
            body = f"El cliente aceptó tu propuesta para: {service_title}"
            
            create_in_app_notification(
                db=db, user_id=str(worker.id), title=title, body=body,
                notification_type="job_accepted", reference_id=str(job.id)
            )
            
            if worker.fcm_token:
                # Data para navegación
                data = {
                    "type": "job_accepted", 
                    "job_id": str(job.id),
                    "service_title": service_title
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
        logger.warning(f"⚠️ Error en notify_job_accepted: {e}")

def notify_job_completed(db: Session, job: models.Job):
    """Notifica al trabajador que el cliente confirmó la finalización."""
    try:
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()
        if worker:
            title = "Trabajo finalizado"
            body = f"El cliente confirmó la finalización de el trabajo"
            
            create_in_app_notification(
                db=db, user_id=str(worker.id), title=title, body=body,
                notification_type="job_completed", reference_id=str(job.id)
            )
            
            if worker.fcm_token:
                send_push_notification(
                    fcm_token=str(worker.fcm_token),
                    title=title,
                    body=body,
                    data={"type": "job_completed", "job_id": str(job.id)}
                )
    except Exception as e:
        logger.warning(f"⚠️ Error en notify_job_completed: {e}")

def notify_job_waiting_confirmation(db: Session, job: models.Job):
    """Notifica al cliente que el trabajador marcó el trabajo como terminado."""
    try:
        client = db.query(auth_models.User).filter(auth_models.User.id == job.client_id).first()
        if client:
            title = "¡Trabajo terminado! 🏁"
            body = f"El trabajador ha marcado como finalizado el servicio. Por favor, confirma la entrega."
            
            create_in_app_notification(
                db=db, user_id=str(client.id), title=title, body=body,
                notification_type="job_waiting_confirmation", reference_id=str(job.id)
            )
            
            if client.fcm_token:
                send_push_notification(
                    fcm_token=str(client.fcm_token),
                    title=title,
                    body=body,
                    data={"type": "job_waiting_confirmation", "job_id": str(job.id)}
                )
    except Exception as e:
        logger.warning(f"⚠️ Error en notify_job_waiting_confirmation: {e}")

def notify_offer_responded(db: Session, conversation_id: str, receiver_id: str, sender_id: str, amount: str, action: str):
    """Notifica a un usuario que su contraoferta fue aceptada o rechazada."""
    try:
        receiver = db.query(auth_models.User).filter(auth_models.User.id == receiver_id).first()
        sender = db.query(auth_models.User).filter(auth_models.User.id == sender_id).first()
        if receiver:
            action_text = "acepto" if action == "accept" else "rechazo"
            sender_name = sender.full_name if sender else "La otra parte"
            title = f"Oferta {action_text}"
            body = f"{sender_name} {action_text} tu contraoferta de ${amount}."
            
            create_in_app_notification(
                db=db, user_id=str(receiver.id), title=title, body=body,
                notification_type="offer_responded", reference_id=str(conversation_id)
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
                        "sender_name": sender_name
                    }
                )
    except Exception as e:
        logger.warning(f"⚠️ Error en notify_offer_responded: {e}")

def notify_new_offer(db: Session, conversation_id: str, receiver_id: str, sender_id: str, amount: str):
    """Notifica al usuario que recibió una nueva contraoferta en el chat. Agrupa notificaciones pendientes."""
    try:
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
            
            if receiver.fcm_token:
                send_push_notification(
                    fcm_token=str(receiver.fcm_token),
                    title=title,
                    body=body,
                    data={
                        "type": "new_offer", 
                        "conversation_id": str(conversation_id),
                        "sender_name": sender_name
                    }
                )
    except Exception as e:
        logger.warning(f"⚠️ Error en notify_new_offer: {e}")

def notify_new_message(db: Session, conversation_id: str, sender_id: str, content: str):
    """Notifica al receptor que tiene un nuevo mensaje en el chat."""
    try:
        convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
        if not convo: return
        
        receiver_id = str(convo.worker_id) if str(convo.client_id) == str(sender_id) else str(convo.client_id)
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
                    "sender_name": sender.full_name if sender else "Chat"
                }
            )
            # No guardamos mensaje en historial in-app de notificaciones para no saturar,
            # ya que el chat tiene su propia persistencia. Pero se podría si se desea.
    except Exception as e:
        logger.warning(f"⚠️ Error en notify_new_message: {e}")

def notify_job_cancelled(db: Session, job: models.Job, cancelled_by_id: str):
    """Notifica a la otra parte que el trabajo fue cancelado."""
    try:
        # Determinar quién cancela y quién recibe
        if str(job.client_id) == str(cancelled_by_id):
            receiver_id = str(job.provider_id)
            role_canceller = "El cliente"
        else:
            receiver_id = str(job.client_id)
            role_canceller = "El trabajador"
        
        receiver = db.query(auth_models.User).filter(auth_models.User.id == receiver_id).first()
        if receiver:
            title = "Trabajo cancelado ❌"
            body = f"{role_canceller} canceló el trabajo."
            
            create_in_app_notification(
                db=db, user_id=receiver_id, title=title, body=body,
                notification_type="job_cancelled", reference_id=str(job.id)
            )
            
            if receiver.fcm_token:
                send_push_notification(
                    fcm_token=str(receiver.fcm_token),
                    title=title,
                    body=body,
                    data={"type": "job_cancelled", "job_id": str(job.id)}
                )
    except Exception as e:
        logger.warning(f"⚠️ Error en notify_job_cancelled: {e}")

# ---------------------------------------------------------
# OTROS MÉTODOS EXISTENTES
# ---------------------------------------------------------

def get_user_notifications(db: Session, user_id: str, limit: int = 50):
    return db.query(models.Notification).filter(
        models.Notification.user_id == user_id
    ).order_by(models.Notification.created_at.desc()).limit(limit).all()

def mark_notification_as_read(db: Session, notification_id: str, user_id: str):
    notification = db.query(models.Notification).filter(
        models.Notification.id == notification_id,
        models.Notification.user_id == user_id
    ).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notificación no encontrada")
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return notification

def mark_all_as_read(db: Session, user_id: str):
    db.query(models.Notification).filter(
        models.Notification.user_id == user_id,
        models.Notification.is_read == False
    ).update({"is_read": True})
    db.commit()
    return {"status": "success", "message": "Todas las notificaciones marcadas como leídas"}

