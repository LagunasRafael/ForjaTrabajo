from sqlalchemy.orm import Session
from sqlalchemy import or_
from fastapi import HTTPException
from app.services import models
from app.services.schemas import ReviewCreate
from datetime import datetime
import uuid


def create_review(db: Session, job_id: str, user_id: str, user_full_name: str, user_profile_picture_url: str, review_data: ReviewCreate):
    job = db.query(models.Job).join(models.ServiceRequest).filter(
        or_(
            models.Job.id == job_id,
            models.ServiceRequest.id == job_id,
            models.ServiceRequest.service_id == job_id
        )
    ).first()

    if not job:
        raise HTTPException(status_code=404, detail="Trabajo no encontrado")

    if job.status.value not in ["completed", "waiting_confirmation"]:
        raise HTTPException(status_code=400, detail="Solo puedes calificar un trabajo que haya sido completado.")

    if str(user_id) not in [job.client_id, job.provider_id]:
        raise HTTPException(status_code=403, detail="No tienes permiso para calificar este trabajo.")

    reviewee_id = job.provider_id if str(user_id) == job.client_id else job.client_id

    existing_review = db.query(models.Review).filter(
        models.Review.job_id == job.id,
        models.Review.reviewer_id == str(user_id)
    ).first()
    if existing_review:
        raise HTTPException(status_code=400, detail="Ya has calificado este trabajo.")

    new_review = models.Review(
        id=str(uuid.uuid4()),
        job_id=job.id,
        reviewer_id=str(user_id),
        reviewee_id=reviewee_id,
        rating=review_data.rating,
        comment=review_data.comment,
        created_at=datetime.utcnow()
    )
    db.add(new_review)
    db.commit()
    db.refresh(new_review)

    return {
        "id": new_review.id,
        "job_id": new_review.job_id,
        "reviewer_id": new_review.reviewer_id,
        "reviewee_id": new_review.reviewee_id,
        "rating": new_review.rating,
        "comment": new_review.comment,
        "created_at": new_review.created_at,
        "reviewer_name": user_full_name,
        "reviewer_image_url": user_profile_picture_url
    }
