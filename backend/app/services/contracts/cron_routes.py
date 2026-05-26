from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.auth.security import get_current_user
from app.core.roles import Role
from app.auth import models as auth_models

router = APIRouter()


@router.post("/cron/check-expirations")
def check_expirations(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    if current_user.role != Role.ADMIN:
        raise HTTPException(status_code=403, detail="Solo admin")

    from app.services.expiration import process_expired_payments
    results = process_expired_payments(db)
    return results
