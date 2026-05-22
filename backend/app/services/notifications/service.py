from sqlalchemy.orm import Session
from typing import Optional
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
    reference_id: str = None,
    target_role: str = None
):
    """Guarda una notificación en la base de datos para el historial in-app."""
    try:
        new_notification = models.Notification(
            user_id=user_id,
            title=title,
            body=body,
            notification_type=notification_type,
            reference_id=reference_id,
            target_role=target_role
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
                notification_type="job_accepted", reference_id=str(job.id),
                target_role="worker"
            )

            
            if worker.fcm_token:
                # Data para navegación
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
        logger.warning(f"⚠️ Error en notify_job_waiting_confirmation: {e}")

def notify_offer_responded(db: Session, conversation_id: str, receiver_id: str, sender_id: str, amount: str, action: str):
    """Notifica a un usuario que su contraoferta fue aceptada, rechazada o retirada."""
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
                action_text = "aceptó"
                title = "Oferta aceptada"
                body = f"{sender_name} aceptó tu contraoferta de ${amount}."
            elif action == "reject":
                action_text = "rechazó"
                title = "Oferta rechazada"
                body = f"{sender_name} rechazó tu contraoferta de ${amount}."
            else:
                action_text = "retiró"
                title = "Oferta retirada"
                body = f"{sender_name} retiró la contraoferta de ${amount}."
            
            # Determinar el rol del receptor
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
        logger.warning(f"⚠️ Error en notify_offer_responded: {e}")

def notify_new_offer(db: Session, conversation_id: str, receiver_id: str, sender_id: str, amount: str):
    """Notifica al usuario que recibió una nueva contraoferta en el chat. Agrupa notificaciones pendientes."""
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
        logger.warning(f"⚠️ Error en notify_new_offer: {e}")

def notify_new_message(db: Session, conversation_id: str, sender_id: str, content: str):
    """Notifica al receptor que tiene un nuevo mensaje en el chat."""
    try:
        convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
        if not convo: return
        
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
            # No guardamos mensaje en historial in-app de notificaciones para no saturar,
            # ya que el chat tiene su propia persistencia. Pero se podría si se desea.
    except Exception as e:
        logger.warning(f"⚠️ Error en notify_new_message: {e}")

def notify_payment_made(db: Session, worker_id: str, amount: float, service_title: str, job_id: str = None):
    """Notifica al trabajador que recibió un pago."""
    try:
        worker = db.query(auth_models.User).filter(auth_models.User.id == worker_id).first()
        if worker:
            title = "¡Pago recibido! 💰"
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
        logger.warning(f"⚠️ Error en notify_payment_made: {e}")


def notify_escrow_confirmed(db: Session, worker_id: str, amount: float, service_title: str, job_id: str = None):
    """Notifica al trabajador que el pago está retenido (escrow) y puede comenzar."""
    try:
        worker = db.query(auth_models.User).filter(auth_models.User.id == worker_id).first()
        if worker:
            title = "Pago recibido"
            body = f"El cliente ya realizó el pago por el servicio \"{service_title}\". Puedes comenzar el trabajo."

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
        logger.warning(f"⚠️ Error en notify_escrow_confirmed: {e}")


def notify_client_payment_deadline(db: Session, job: models.Job, payment_due_minutes: int):
    """Notifica al cliente que tiene un plazo para realizar el pago."""
    try:
        client = db.query(auth_models.User).filter(auth_models.User.id == job.client_id).first()
        if client:
            hours = payment_due_minutes // 60
            if hours > 0:
                time_str = f"{hours} horas"
            else:
                time_str = f"{payment_due_minutes} minutos"
            title = "Plazo para realizar el pago"
            body = f"Tienes {time_str} para pagar el trabajo. Si no pagas a tiempo, se cancelará automáticamente."

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
        logger.warning(f"Error en notify_client_payment_deadline: {e}")


def notify_worker_confirmation_deadline(db: Session, job: models.Job, auto_release_minutes: int):
    """Notifica al trabajador que el cliente tiene un plazo para confirmar la finalización."""
    try:
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()
        if worker:
            hours = auto_release_minutes // 60
            if hours > 0:
                time_str = f"{hours} horas"
            else:
                time_str = f"{auto_release_minutes} minutos"
            title = "Esperando confirmación del cliente"
            body = f"Marcaste el trabajo como terminado. El cliente tiene {time_str} para confirmar. Si no responde, el pago se liberará automáticamente."

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
        logger.warning(f"Error en notify_worker_confirmation_deadline: {e}")


def notify_payment_expired(db: Session, job: models.Job):
    """Notifica al cliente y al trabajador que el pago expiró y el trabajo fue cancelado."""
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
                    body="El trabajo fue cancelado porque no se realizó el pago a tiempo.",
                    data={"type": "payment_expired", "job_id": str(job.id), "target_role": "client"}
                )

        if worker:
            create_in_app_notification(
                db=db, user_id=str(worker.id),
                title="Trabajo cancelado por falta de pago",
                body="El cliente no realizó el pago a tiempo. El trabajo ha sido cancelado.",
                notification_type="payment_expired", reference_id=str(job.id),
                target_role="worker"
            )
            if worker.fcm_token:
                send_push_notification(
                    fcm_token=str(worker.fcm_token), title="Trabajo cancelado",
                    body="El cliente no pagó a tiempo. El trabajo fue cancelado.",
                    data={"type": "payment_expired", "job_id": str(job.id), "target_role": "worker"}
                )
    except Exception as e:
        logger.warning(f"Error en notify_payment_expired: {e}")


def notify_auto_released(db: Session, job: models.Job):
    """Notifica al cliente y al trabajador que el pago se liberó automáticamente."""
    try:
        client = db.query(auth_models.User).filter(auth_models.User.id == job.client_id).first()
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()

        if worker:
            create_in_app_notification(
                db=db, user_id=str(worker.id),
                title="Pago liberado automáticamente 💰",
                body="El cliente no respondió a tiempo. El pago ha sido liberado automáticamente.",
                notification_type="auto_released", reference_id=str(job.id),
                target_role="worker"
            )
            if worker.fcm_token:
                send_push_notification(
                    fcm_token=str(worker.fcm_token), title="Pago liberado 💰",
                    body="El cliente no respondió. El pago se liberó automáticamente a tu cuenta.",
                    data={"type": "auto_released", "job_id": str(job.id), "target_role": "worker"}
                )

        if client:
            create_in_app_notification(
                db=db, user_id=str(client.id),
                title="Pago liberado automáticamente",
                body="El pago del trabajo fue liberado automáticamente al trabajador por falta de respuesta.",
                notification_type="auto_released", reference_id=str(job.id),
                target_role="client"
            )
            if client.fcm_token:
                send_push_notification(
                    fcm_token=str(client.fcm_token), title="Pago liberado",
                    body="El pago fue liberado automáticamente al trabajador porque no confirmaste a tiempo.",
                    data={"type": "auto_released", "job_id": str(job.id), "target_role": "client"}
                )
    except Exception as e:
        logger.warning(f"Error en notify_auto_released: {e}")


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
        logger.warning(f"⚠️ Error en notify_job_cancelled: {e}")

# ---------------------------------------------------------
# OTROS MÉTODOS EXISTENTES
# ---------------------------------------------------------

def get_user_notifications(db: Session, user_id: str, role: Optional[str] = None, limit: int = 50):
    query = db.query(models.Notification).filter(models.Notification.user_id == user_id)

    if role:
        query = query.filter(
            (models.Notification.target_role == role) | (models.Notification.target_role.is_(None))
        )

    return query.order_by(models.Notification.created_at.desc()).limit(limit).all()


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

