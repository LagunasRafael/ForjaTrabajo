from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.auth.security import get_current_user
from app.auth import models as auth_models
from app.services import schemas
from app.services.contracts.review_service import create_review

router = APIRouter()


@router.post("/jobs/{job_id}/review", response_model=schemas.ReviewResponse)
def leave_review(
    job_id: str,
    review_data: schemas.ReviewCreate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    return create_review(
        db, job_id, str(current_user.id),
        current_user.full_name, current_user.profile_picture_url,
        review_data,
    )
