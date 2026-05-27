from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.auth.security import get_current_user
from app.auth import models as auth_models
from app.services.expiration import process_expired_payments
from app.services.posting.history_service import get_my_services, build_my_services_response

router = APIRouter()


@router.get("/my-requests")
def read_my_requests(db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    process_expired_payments(db)
    services = get_my_services(db, user_id=str(current_user.id))
    return build_my_services_response(db, services)
