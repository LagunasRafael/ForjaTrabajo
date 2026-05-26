from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.auth.security import check_role, get_current_user
from app.core.roles import Role
from app.auth import models as auth_models
from app.services import schemas
from app.services.contracts.lifecycle_service import accept_postulation, complete_job, cancel_job
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/accept-postulation/{request_id}")
def accept_worker_postulation(request_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    result = accept_postulation(db, request_id, str(current_user.id))
    return result


@router.put("/jobs/{job_id}/complete", response_model=schemas.Job)
def complete_job_status(job_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(check_role([Role.CLIENT, Role.WORKER, Role.ADMIN]))):
    try:
        return complete_job(db, job_id, str(current_user.id))
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.exception(f"Error inesperado en complete_job: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/jobs/{job_id}/cancel", response_model=schemas.Job)
def cancel_job_status(job_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    return cancel_job(db, job_id, str(current_user.id), str(current_user.role))
