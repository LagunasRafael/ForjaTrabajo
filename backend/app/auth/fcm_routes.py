from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.auth import schemas, models
from app.db.database import get_db
from app.auth.security import get_current_user
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


@router.put("/fcm-token")
def update_fcm_token(
    data: schemas.FcmTokenUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    try:
        token = data.fcm_token if data.fcm_token else ""
        if token:
            db.query(models.User).filter(
                models.User.fcm_token == token,
                models.User.id != current_user.id
            ).update({"fcm_token": ""}, synchronize_session=False)

        current_user.fcm_token = token
        db.commit()

        return {"status": "success", "message": "FCM token actualizado"}
    except Exception as e:
        db.rollback()
        return {"status": "error", "message": str(e)}
