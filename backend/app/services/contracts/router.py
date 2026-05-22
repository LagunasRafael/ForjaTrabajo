from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import Optional, List

from app.db.database import get_db
from app.auth.security import check_role, get_current_user
from app.core.roles import Role
from app.auth import models as auth_models

from app.services import schemas, models
from app.services.contracts import service as contracts_service
from app.services.contracts import schemas as contracts_schemas
from app.utils.s3 import upload_service_evidence_to_s3
from sqlalchemy.orm import joinedload

router = APIRouter()

@router.post("/accept-postulation/{request_id}")
def accept_worker_postulation(request_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    result = contracts_service.accept_postulation(db, request_id, str(current_user.id))
    return result

@router.put("/jobs/{job_id}/complete", response_model=schemas.Job)
def complete_job_status(job_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(check_role([Role.CLIENT, Role.WORKER, Role.ADMIN]))):
    try:
        return contracts_service.complete_job(db, job_id, str(current_user.id))
    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"🚨 Error inesperado en el router: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/jobs/{job_id}/cancel", response_model=schemas.Job)
def cancel_job_status(job_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    """Cancela un Job que ya estaba en 'matched'."""
    return contracts_service.cancel_job(db, job_id, str(current_user.id), str(current_user.role))

# =================================================================
# WORK EVIDENCES
# =================================================================
@router.get("/{service_id}/evidences", response_model=List[contracts_schemas.WorkEvidenceResponse])
def list_evidences(
    service_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user),
):
    return contracts_service.get_evidences(db, service_id, str(current_user.id), str(current_user.role))

@router.post("/{service_id}/evidences", response_model=contracts_schemas.WorkEvidenceResponse)
async def upload_evidence(
    service_id: str,
    file: UploadFile = File(...),
    description: Optional[str] = Form(None),
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user),
):
    service = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    worker_id = str(service.worker_id)
    if str(current_user.id) != worker_id:
        raise HTTPException(status_code=403, detail="Solo el trabajador asignado puede subir evidencias")

    if service.status not in [models.JobStatus.MATCHED, models.JobStatus.WAITING_CONFIRMATION]:
        raise HTTPException(status_code=400, detail="No puedes subir evidencias en un trabajo cancelado o finalizado")

    image_url = await upload_service_evidence_to_s3(file, service_id)
    if not image_url:
        raise HTTPException(status_code=500, detail="Error al subir la imagen a S3")

    return contracts_service.create_evidence(db, service_id, worker_id, image_url, description)

@router.delete("/{service_id}/evidences/{evidence_id}")
def remove_evidence(
    service_id: str,
    evidence_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user),
):
    return contracts_service.delete_evidence(db, evidence_id, service_id, str(current_user.id))

# =================================================================
# ADMIN JOBS
# =================================================================
@router.get("/admin/jobs/all")
def get_all_jobs_admin(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """Devuelve TODOS los jobs (MATCHED, COMPLETED, CANCELLED) con datos extra para el panel admin."""
    jobs = db.query(models.Job).options(
        joinedload(models.Job.request).joinedload(models.ServiceRequest.service).joinedload(models.Service.category)
    ).order_by(models.Job.started_at.desc()).all()
    
    result = []
    for job in jobs:
        client = db.query(auth_models.User).filter(auth_models.User.id == job.client_id).first()
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()
        service_obj = job.request.service if job.request else None
        
        applicants = 0
        if service_obj:
            applicants = db.query(models.ServiceRequest).filter(models.ServiceRequest.service_id == service_obj.id).count()

        result.append({
            "id": job.id,
            "status": job.status.value,
            "final_price": float(str(job.final_price)) if job.final_price else 0.0,
            "started_at": job.started_at,
            "completed_at": job.completed_at,
            "client_name": client.full_name if client else "Cliente Desconocido",
            "worker_name": worker.full_name if worker else "Trabajador Desconocido",
            "service_title": service_obj.title if service_obj else "Servicio Borrado",
            "title": service_obj.title if service_obj else "Servicio Borrado",
            "description": service_obj.description if service_obj else "",
            "category": service_obj.category.name if service_obj and service_obj.category else "Sin categoría",
            "location_city": service_obj.exact_address if service_obj and service_obj.exact_address else "Ubicación oculta",
            "image_urls": service_obj.image_urls if service_obj and service_obj.image_urls else [],
            "budget": float(service_obj.base_price) if service_obj and service_obj.base_price else 0,
            "applicants_count": applicants,
            "createdAt": service_obj.created_at.isoformat() if service_obj and service_obj.created_at else job.started_at.isoformat(),
        })
    return result

# =================================================================
# REVIEWS
# =================================================================
@router.post("/jobs/{job_id}/review", response_model=schemas.ReviewResponse)
def leave_review(
    job_id: str,
    review_data: schemas.ReviewCreate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Permite al cliente o al trabajador dejar una reseña mutua una vez que el trabajo está completado."""
    from sqlalchemy import or_
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
        
    # Verificar que el usuario sea parte del trabajo
    if str(current_user.id) not in [job.client_id, job.provider_id]:
        raise HTTPException(status_code=403, detail="No tienes permiso para calificar este trabajo.")
        
    # Determinar quién es el evaluado
    reviewee_id = job.provider_id if str(current_user.id) == job.client_id else job.client_id
    
    # Verificar si ya dejó reseña
    existing_review = db.query(models.Review).filter(
        models.Review.job_id == job.id,
        models.Review.reviewer_id == str(current_user.id)
    ).first()
    if existing_review:
        raise HTTPException(status_code=400, detail="Ya has calificado este trabajo.")
        
    # Crear reseña
    import uuid
    from datetime import datetime
    new_review = models.Review(
        id=str(uuid.uuid4()),
        job_id=job.id,
        reviewer_id=str(current_user.id),
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
        "reviewer_name": current_user.full_name,
        "reviewer_image_url": current_user.profile_picture_url
    }
