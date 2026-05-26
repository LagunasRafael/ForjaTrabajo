from sqlalchemy.orm import Session, joinedload
from app.services import models
from fastapi import HTTPException
from typing import Optional
import logging

logger = logging.getLogger(__name__)


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
        raise HTTPException(status_code=400, detail="Limite de evidencias alcanzado (8 maximas)")

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
        logger.warning(f"No se pudo eliminar de S3: {e}")

    db.delete(evidence)
    db.commit()
    return {"status": "deleted"}
