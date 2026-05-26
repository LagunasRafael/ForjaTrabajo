from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from typing import Optional, List
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.auth.security import get_current_user
from app.auth import models as auth_models
from app.services import models
from app.services.contracts import schemas as contracts_schemas
from app.services.contracts.evidence_service import get_evidences, create_evidence, delete_evidence
from app.utils.s3 import upload_service_evidence_to_s3

router = APIRouter()


@router.get("/{service_id}/evidences", response_model=List[contracts_schemas.WorkEvidenceResponse])
def list_evidences(
    service_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user),
):
    return get_evidences(db, service_id, str(current_user.id), str(current_user.role))


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

    return create_evidence(db, service_id, worker_id, image_url, description)


@router.delete("/{service_id}/evidences/{evidence_id}")
def remove_evidence(
    service_id: str,
    evidence_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user),
):
    return delete_evidence(db, evidence_id, service_id, str(current_user.id))
