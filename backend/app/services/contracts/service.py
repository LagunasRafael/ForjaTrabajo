from sqlalchemy.orm import Session
from app.services import models, schemas
from fastapi import HTTPException
from datetime import datetime, timedelta
from sqlalchemy import or_
from sqlalchemy.orm import joinedload
from typing import Optional
from app.core.roles import Role
from app.auth import models as auth_models
from app.services.notifications import service as notif_service

from app.payments.services import capture_payment
import logging

from app.core.config import PAYMENT_DUE_MINUTES, AUTO_RELEASE_MINUTES

logger = logging.getLogger(__name__)

def accept_postulation(db: Session, request_id: str, current_user_id: str):
    postulation = db.query(models.ServiceRequest).filter(models.ServiceRequest.id == request_id).first()
    if not postulation:
        raise HTTPException(status_code=404, detail="La postulación no existe")

    service_entry = postulation.service
    
    if str(service_entry.client_id) != str(current_user_id):
        raise HTTPException(status_code=403, detail="No tienes permiso")

    if service_entry.status != models.JobStatus.OPEN:
        # Si ya está MATCHED, verificar si es por esta misma postulación
        existing_job = db.query(models.Job).filter(models.Job.request_id == request_id).first()
        if existing_job:
            return {
                "status": "success", 
                "message": "Ya aceptado previamente",
                "job_id": str(existing_job.id)
            }
        raise HTTPException(status_code=400, detail="Este servicio ya ha sido asignado a otro trabajador.")

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
            started_at=datetime.utcnow(),
            payment_due_at=datetime.utcnow() + timedelta(minutes=PAYMENT_DUE_MINUTES)
        )
        
        db.add(new_job)
        db.commit()

        # 🔔 Notificar al trabajador que fue aceptado y al cliente sobre el plazo de pago
        notif_service.notify_job_accepted(db, new_job, service_entry.title)
        notif_service.notify_client_payment_deadline(db, new_job, PAYMENT_DUE_MINUTES)
        
        return {
            "status": "success", 
            "message": "Aceptado correctamente",
            "job_id": str(new_job.id)
        }

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
        job.auto_release_at = datetime.utcnow() + timedelta(minutes=AUTO_RELEASE_MINUTES)
        if job.request and job.request.service:
            job.request.service.status = models.JobStatus.WAITING_CONFIRMATION
            
        db.commit()
        db.refresh(job)

        notif_service.notify_worker_confirmation_deadline(db, job, AUTO_RELEASE_MINUTES)

        return job

    elif is_client:
        job.status = models.JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        job.auto_release_at = None  # Cliente confirmó, cancelar auto-liberación
        
        if job.request and job.request.service:
            job.request.service.status = models.JobStatus.COMPLETED
            job.request.service.is_active = False

        db.commit()
        db.refresh(job)

        # Liberar pago retenido en Stripe (escrow → released)
        try:
            capture_payment(db, str(job.id))
        except Exception as e:
            logger.warning(f"No se pudo liberar el pago automaticamente: {e}")

        # 🔔 Notificar al trabajador que el trabajo fue finalizado (Migrado)
        notif_service.notify_job_completed(db, job)

        return job

def get_evidences(db: Session, service_id: str, current_user_id: str, current_user_role: str):
    service = db.query(models.Service).options(
        joinedload(models.Service.requests)
    ).filter(models.Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    is_owner = str(service.client_id) == str(current_user_id)
    is_worker = str(service.worker_id) == str(current_user_id) if service.worker_id else False
    is_admin = str(current_user_role).lower() == "admin"

    if not (is_owner or is_worker or is_admin):
        raise HTTPException(status_code=403, detail="No tienes permiso para ver estas evidencias")

    return db.query(models.WorkEvidence).filter(
        models.WorkEvidence.service_id == service_id
    ).order_by(models.WorkEvidence.created_at.desc()).all()

def create_evidence(db: Session, service_id: str, worker_id: str, image_url: str, description: Optional[str] = None):
    count = db.query(models.WorkEvidence).filter(
        models.WorkEvidence.service_id == service_id
    ).count()
    if count >= 8:
        raise HTTPException(status_code=400, detail="Límite de evidencias alcanzado (8 máximas)")

    evidence = models.WorkEvidence(
        service_id=service_id,
        worker_id=worker_id,
        image_url=image_url,
        description=description,
    )
    db.add(evidence)
    db.commit()
    db.refresh(evidence)
    return evidence

def delete_evidence(db: Session, evidence_id: str, service_id: str, current_user_id: str):
    evidence = db.query(models.WorkEvidence).filter(
        models.WorkEvidence.id == evidence_id,
        models.WorkEvidence.service_id == service_id,
    ).first()
    if not evidence:
        raise HTTPException(status_code=404, detail="Evidencia no encontrada")

    service = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    if str(current_user_id) != str(evidence.worker_id) and str(current_user_id) != str(service.client_id):
        raise HTTPException(status_code=403, detail="No tienes permiso para eliminar esta evidencia")

    if service.status in [models.JobStatus.COMPLETED, models.JobStatus.CANCELLED]:
        raise HTTPException(status_code=400, detail="No puedes eliminar evidencias de un trabajo finalizado o cancelado")

    try:
        from app.utils.s3 import delete_old_file_from_s3
        delete_old_file_from_s3(evidence.image_url)
    except Exception as e:
        print(f"⚠️ No se pudo eliminar de S3: {e}")

    db.delete(evidence)
    db.commit()
    return {"status": "deleted"}

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