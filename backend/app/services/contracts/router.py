from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.auth.security import check_role, get_current_user
from app.core.roles import Role
from app.auth import models as auth_models

from app.services import schemas
from app.services.contracts import service

router = APIRouter()

@router.post("/accept-postulation/{request_id}")
def accept_worker_postulation(request_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    service.accept_postulation(db, request_id, str(current_user.id))
    return JSONResponse(status_code=200, content={"status": "success", "message": "Trabajo aceptado"})

@router.put("/jobs/{job_id}/complete", response_model=schemas.Job)
def complete_job_status(job_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(check_role([Role.CLIENT, Role.WORKER, Role.ADMIN]))):
    try:
        return service.complete_job(db, job_id, str(current_user.id))
    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"🚨 Error inesperado en el router: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/jobs/{job_id}/cancel", response_model=schemas.Job)
def cancel_job_status(job_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    """Cancela un Job que ya estaba en 'matched'."""
    return service.cancel_job(db, job_id, str(current_user.id), current_user.role)