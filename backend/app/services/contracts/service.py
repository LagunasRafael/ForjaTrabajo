from sqlalchemy.orm import Session
from app.services import models, schemas
from fastapi import HTTPException
from datetime import datetime
from sqlalchemy import or_
from app.core.roles import Role
from app.auth import models as auth_models
from app.services.notifications import service as notif_service
import logging

logger = logging.getLogger(__name__)

def accept_postulation(db: Session, request_id: str, current_user_id: str):
    postulation = db.query(models.ServiceRequest).filter(models.ServiceRequest.id == request_id).first()
    if not postulation:
        raise HTTPException(status_code=404, detail="La postulación no existe")

    service_entry = postulation.service
    
    if str(service_entry.client_id) != str(current_user_id):
        raise HTTPException(status_code=403, detail="No tienes permiso")

    if service_entry.status != models.JobStatus.OPEN:
        raise HTTPException(status_code=400, detail="Servicio no disponible")

    try:
        final_price = postulation.proposed_price if postulation.proposed_price else service_entry.base_price
        service_entry.status = models.JobStatus.MATCHED
        service_entry.base_price = final_price  # 👈 Sincronizar precio pactado en el Servicio
        postulation.status = "accepted"
        
        new_job = models.Job(
            request_id=postulation.id,
            provider_id=postulation.worker_id,
            client_id=service_entry.client_id,
            status=models.JobStatus.MATCHED,
            final_price=final_price,
            started_at=datetime.utcnow()
        )
        
        db.add(new_job)
        db.commit()

        # 🔔 Notificar al trabajador que fue aceptado (Migrado)
        notif_service.notify_job_accepted(db, new_job, service_entry.title)
        
        return {"status": "success", "message": "Aceptado correctamente"}

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

def complete_job(db: Session, job_id: str, user_id: str):
    job = db.query(models.Job).join(models.ServiceRequest).filter(
        or_(
            models.Job.id == job_id,
            models.ServiceRequest.id == job_id,
            models.ServiceRequest.service_id == job_id
        ),
        models.Job.status.in_([models.JobStatus.MATCHED, models.JobStatus.WAITING_CONFIRMATION])
    ).first()

    if not job:
        raise HTTPException(status_code=404, detail="Trabajo no encontrado o ya finalizado")

    is_client = str(job.client_id) == str(user_id)
    is_worker = str(job.provider_id) == str(user_id)

    if not (is_client or is_worker):
        raise HTTPException(status_code=403, detail="No tienes permiso para modificar este trabajo")

    if is_worker:
        if job.status == models.JobStatus.WAITING_CONFIRMATION:
            return job 
        
        job.status = models.JobStatus.WAITING_CONFIRMATION
        if job.request and job.request.service:
            job.request.service.status = models.JobStatus.WAITING_CONFIRMATION
            
        db.commit()
        db.refresh(job)
        return job

    elif is_client:
        job.status = models.JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        
        if job.request and job.request.service:
            job.request.service.status = models.JobStatus.COMPLETED
            job.request.service.is_active = False

        db.commit()
        db.refresh(job)

        # 🔔 Notificar al trabajador que el trabajo fue finalizado (Migrado)
        notif_service.notify_job_completed(db, job)

        return job

def cancel_job(db: Session, job_id: str, user_id: str, user_role: str):
    job = db.query(models.Job).join(models.ServiceRequest).filter(
        or_(
            models.Job.id == job_id,
            models.ServiceRequest.service_id == job_id
        )
    ).first()

    if not job:
        raise HTTPException(status_code=404, detail="Trabajo no encontrado")

    is_worker = str(job.provider_id) == str(user_id)
    is_client = str(job.client_id) == str(user_id)
    is_admin = user_role == Role.ADMIN

    if not (is_worker or is_client or is_admin):
        raise HTTPException(status_code=403, detail="No tienes permiso para cancelar")

    job.status = models.JobStatus.CANCELLED
    
    if job.request and job.request.service:
        if is_worker:
            job.request.service.status = models.JobStatus.OPEN
        else:
            job.request.service.status = models.JobStatus.CANCELLED

    db.commit()
    db.refresh(job)
    return job