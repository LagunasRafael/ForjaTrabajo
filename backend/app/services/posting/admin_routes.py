from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.auth.security import check_role
from app.core.roles import Role
from app.auth import models as auth_models
from app.services.posting.moderation_service import delete_service, get_reported_services

router = APIRouter()


@router.get("/admin/reported-services")
def get_reported_services_route(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    return get_reported_services(db)


@router.delete("/{service_id}", status_code=status.HTTP_200_OK)
def delete_service_route(service_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(check_role([Role.ADMIN]))):
    return delete_service(db, service_id)
