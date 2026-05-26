from sqlalchemy.orm import Session
from typing import Optional
from app.services import models
from fastapi import HTTPException
import logging

logger = logging.getLogger(__name__)


def create_in_app_notification(
    db: Session,
    user_id: str,
    title: str,
    body: str,
    notification_type: str,
    reference_id: str = None,
    target_role: str = None
):
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
        logger.error("Error guardando notificacion en BD: %s", e)
        db.rollback()
        return None


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
        raise HTTPException(status_code=404, detail="Notificacion no encontrada")
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
    return {"status": "success", "message": "Todas las notificaciones marcadas como leidas"}


def delete_notification(db: Session, notification_id: str, user_id: str):
    notification = db.query(models.Notification).filter(
        models.Notification.id == notification_id,
        models.Notification.user_id == user_id
    ).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notificacion no encontrada")
    db.delete(notification)
    db.commit()
    return {"status": "success", "message": "Notificacion eliminada"}


def delete_all_notifications(db: Session, user_id: str):
    db.query(models.Notification).filter(
        models.Notification.user_id == user_id
    ).delete()
    db.commit()
    return {"status": "success", "message": "Todas las notificaciones eliminadas"}
