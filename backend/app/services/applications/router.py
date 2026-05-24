from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.auth.security import check_role, get_current_user
from app.core.roles import Role
from app.auth import models as auth_models

from app.services import schemas
from app.services.applications import service
from app.services.expiration import process_expired_payments

router = APIRouter()

@router.post("/service-requests", response_model=schemas.ServiceRequest)
def create_service_request(
    request_data: schemas.ServiceRequestCreate, db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.WORKER]))
):
    return service.create_service_request(db, request_data, worker_id=current_user.id)

@router.put("/service-requests/{request_id}")
def update_postulation(
    request_id: str, payload: schemas.UpdatePostulationRequest, 
    db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)
):
    # Usamos la función del service para mantener el router limpio
    service.update_service_request(db, request_id, payload.description, payload.proposed_price)
    return {"status": "success", "message": "Propuesta actualizada"}

@router.delete("/service-requests/{request_id}")
def withdraw_postulation(request_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    return service.withdraw_postulation(db, request_id, str(current_user.id))

@router.get("/worker/my-applications")
def get_my_applications(db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    try:
        return service.get_worker_applications(db, str(current_user.id))
    except Exception as e:
        print(f"🚨 ERROR 500 EN /worker/my-applications: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{service_id}/offers", response_model=List[schemas.ServiceRequest])
def get_service_offers(service_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    """Ver ofertas recibidas (Solo dueño o admin)"""
    process_expired_payments(db)
    is_admin = current_user.role.value == 'admin' if hasattr(current_user.role, 'value') else current_user.role == 'admin'
    return service.get_offers_by_service(db, service_id, str(current_user.id), is_admin=is_admin)