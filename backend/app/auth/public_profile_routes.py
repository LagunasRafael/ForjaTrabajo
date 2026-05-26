from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from sqlalchemy import func
from app.auth import schemas, models
from app.db.database import get_db
from app.services import models as service_models
from app.services import schemas as service_schemas
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/users/{user_id}/profile", response_model=service_schemas.UserProfileResponse)
def get_user_profile(user_id: str, db: Session = Depends(get_db)):
    """Devuelve el perfil público de un usuario, sus estadísticas de reseñas y trabajos completados."""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
    stats = db.query(
        func.count(service_models.Review.id).label("total"),
        func.avg(service_models.Review.rating).label("average")
    ).filter(service_models.Review.reviewee_id == user_id).first()
    
    total_reviews = stats.total if stats and stats.total else 0
    average_rating = round(stats.average, 1) if stats and stats.average else 0.0

    completed_jobs = []
    jobs_as_client = db.query(service_models.Job)\
        .filter(service_models.Job.client_id == user_id, service_models.Job.status == service_models.JobStatus.COMPLETED)\
        .order_by(service_models.Job.completed_at.desc()).limit(10).all()
    
    for job in jobs_as_client:
        req = job.request
        srv = req.service if req else None
        worker_name = None
        worker_image = None
        if req and req.worker:
            worker_name = req.worker.full_name
            worker_image = req.worker.profile_picture_url
        completed_jobs.append({
            "id": job.id,
            "title": srv.title if srv else "Sin título",
            "status": job.status.value,
            "base_price": float(srv.base_price) if srv and srv.base_price else 0.0,
            "final_price": float(job.final_price) if job.final_price else 0.0,
            "completed_at": job.completed_at,
            "other_party_name": worker_name,
            "other_party_image_url": worker_image,
            "role_in_job": "client",
        })

    jobs_as_worker = db.query(service_models.Job)\
        .filter(service_models.Job.provider_id == user_id, service_models.Job.status == service_models.JobStatus.COMPLETED)\
        .order_by(service_models.Job.completed_at.desc()).limit(10).all()
    
    for job in jobs_as_worker:
        req = job.request
        srv = req.service if req else None
        client_name = None
        client_image = None
        if srv and srv.owner:
            client_name = srv.owner.full_name
            client_image = srv.owner.profile_picture_url
        completed_jobs.append({
            "id": job.id,
            "title": srv.title if srv else "Sin título",
            "status": job.status.value,
            "base_price": float(srv.base_price) if srv and srv.base_price else 0.0,
            "final_price": float(job.final_price) if job.final_price else 0.0,
            "completed_at": job.completed_at,
            "other_party_name": client_name,
            "other_party_image_url": client_image,
            "role_in_job": "worker",
        })

    completed_jobs.sort(key=lambda j: j.get("completed_at") or datetime.min, reverse=True)
    
    return {
        "id": user.id,
        "full_name": user.full_name or "Usuario Anónimo",
        "profile_picture_url": user.profile_picture_url,
        "role": user.role.value if hasattr(user.role, 'value') else str(user.role),
        "created_at": user.created_at,
        "average_rating": average_rating,
        "total_reviews": total_reviews,
        "is_identity_verified": bool(user.is_identity_verified),
        "completed_jobs": completed_jobs[:10],
        "bio": user.bio,
        "categories": user.categories
    }


@router.get("/users/{user_id}/reviews", response_model=List[service_schemas.ReviewResponse])
def get_user_reviews(user_id: str, skip: int = 0, limit: int = 15, db: Session = Depends(get_db)):
    """Devuelve la lista de reseñas que otros usuarios han dejado sobre este usuario."""
    reviews = db.query(service_models.Review)\
                .filter(service_models.Review.reviewee_id == user_id)\
                .order_by(service_models.Review.created_at.desc())\
                .offset(skip).limit(limit).all()
                
    result = []
    for r in reviews:
        reviewer = db.query(models.User).filter(models.User.id == r.reviewer_id).first()
        result.append({
            "id": r.id,
            "job_id": r.job_id,
            "reviewer_id": r.reviewer_id,
            "reviewee_id": r.reviewee_id,
            "rating": r.rating,
            "comment": r.comment,
            "created_at": r.created_at,
            "reviewer_name": reviewer.full_name if reviewer else "Usuario Anónimo",
            "reviewer_image_url": reviewer.profile_picture_url if reviewer else None
        })
    return result
