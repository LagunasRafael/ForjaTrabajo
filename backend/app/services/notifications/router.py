from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional

from app.db.database import get_db
from app.auth.security import get_current_user
from app.auth.models import User
from app.services.notifications import service, schemas

router = APIRouter(prefix="/notifications")

@router.get("/", response_model=List[schemas.NotificationResponse])
def get_notifications(
    role: Optional[str] = None,
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    """Obtiene el historial de notificaciones del usuario actual."""
    return service.get_user_notifications(db=db, user_id=str(current_user.id), role=role)


@router.put("/{notification_id}/read", response_model=schemas.NotificationResponse)
def mark_read(notification_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Marca una notificación específica como leída."""
    return service.mark_notification_as_read(db=db, notification_id=notification_id, user_id=str(current_user.id))

@router.put("/read-all")
def mark_all_read(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Marca todas las notificaciones del usuario como leídas."""
    return service.mark_all_as_read(db=db, user_id=str(current_user.id))
