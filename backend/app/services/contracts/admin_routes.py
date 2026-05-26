from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session, joinedload
from app.db.database import get_db
from app.auth.security import check_role
from app.core.roles import Role
from app.auth import models as auth_models
from app.services import models

router = APIRouter()


@router.get("/admin/jobs/all")
def get_all_jobs_admin(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
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
            "category": service_obj.category.name if service_obj and service_obj.category else "Sin categoria",
            "location_city": service_obj.exact_address if service_obj and service_obj.exact_address else "Ubicacion oculta",
            "image_urls": service_obj.image_urls if service_obj and service_obj.image_urls else [],
            "budget": float(service_obj.base_price) if service_obj and service_obj.base_price else 0,
            "applicants_count": applicants,
            "createdAt": service_obj.created_at.isoformat() if service_obj and service_obj.created_at else job.started_at.isoformat(),
        })
    return result
