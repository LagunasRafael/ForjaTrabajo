from fastapi import APIRouter, Depends, UploadFile, File
from sqlalchemy.orm import Session
from app.auth import schemas, models
from app.auth.verification_service import (
    create_verification,
    get_verification_status,
    get_pending_verifications_admin,
    approve_verification_admin,
    reject_verification_admin
)
from app.db.database import get_db
from app.auth.security import get_current_user, check_role
from app.core.roles import Role
from app.admin.ws_manager import recalculate_and_broadcast
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/verify-identity", response_model=dict)
async def upload_identity_verification(
    ine_front: UploadFile = File(...),
    ine_back: UploadFile = File(...),
    selfie: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    result = create_verification(
        db, str(current_user.id),
        ine_front, ine_back, selfie
    )
    recalculate_and_broadcast(db)
    return result


@router.get("/verification-status", response_model=dict)
def read_verification_status(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    return get_verification_status(db, str(current_user.id))


@router.get("/admin/verifications", response_model=list[dict])
def list_pending_verifications(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_role([Role.ADMIN]))
):
    return get_pending_verifications_admin(db)


@router.post("/admin/verifications/{verification_id}/approve", response_model=dict)
def approve_verification(
    verification_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_role([Role.ADMIN]))
):
    result = approve_verification_admin(db, verification_id, str(current_user.id))
    recalculate_and_broadcast(db)
    return result


@router.post("/admin/verifications/{verification_id}/reject", response_model=dict)
def reject_verification(
    verification_id: str,
    payload: schemas.RejectVerificationRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(check_role([Role.ADMIN]))
):
    result = reject_verification_admin(db, verification_id, str(current_user.id), payload.reason)
    recalculate_and_broadcast(db)
    return result
