from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.auth.security import check_role, get_current_user
from app.core.roles import Role
from app.auth import models as auth_models
from app.services import schemas
from app.services.posting.moderation_service import update_service, cancel_service, hide_from_history, toggle_service_active

router = APIRouter()


@router.put("/{service_id}", response_model=schemas.Service)
def update_service(
    service_id: str, service_data: schemas.ServiceUpdate, db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user),
):
    return update_service(db, service_id, service_data, current_user.id, current_user.role)


@router.put("/{service_id}/cancel")
def cancel_service_route(service_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    return cancel_service(db, service_id, current_user.id, current_user.role)


@router.post("/{service_id}/hide-from-history")
def hide_service_from_history(service_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    return hide_from_history(db, service_id, str(current_user.id))


@router.patch("/{service_id}/active", response_model=schemas.Service)
def toggle_service_visibility(
    service_id: str, payload: schemas.ServiceActiveUpdate, db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    return toggle_service_active(db, service_id, payload.is_active)
