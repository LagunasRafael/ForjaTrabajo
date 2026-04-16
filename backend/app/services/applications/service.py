from sqlalchemy.orm import Session
from uuid import UUID
from fastapi import HTTPException

from app.services import models, schemas

def create_service_request(db: Session, request_data: schemas.ServiceRequestCreate, worker_id: UUID):
    existing_request = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.service_id == str(request_data.service_id),
        models.ServiceRequest.worker_id == str(worker_id)
    ).first()

    if existing_request:
        raise HTTPException(status_code=400, detail="Ya enviaste una propuesta a este trabajo.")

    db_request = models.ServiceRequest(
        service_id=str(request_data.service_id),
        description=request_data.description,
        proposed_price=request_data.proposed_price, 
        worker_id=str(worker_id),
        status="pending"
    )
    db.add(db_request)
    db.commit()
    db.refresh(db_request)
    return db_request

def get_offers_by_service(db: Session, service_id: str, client_id: str):
    db_service = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not db_service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    if str(db_service.client_id) == str(client_id):
        return db_service.requests

    my_requests = [
        req for req in db_service.requests 
        if str(req.worker_id) == str(client_id)
    ]
    return my_requests

def update_service_request(db: Session, request_id: str, description: str, proposed_price: float):
    postulation = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.id == request_id
    ).first()

    if not postulation:
        raise HTTPException(status_code=404, detail="Postulación no encontrada")

    postulation.description = description
    postulation.proposed_price = proposed_price

    db.commit()
    db.refresh(postulation)
    return postulation

def get_worker_applications(db: Session, worker_id: str):
    try:
        unique_results = {}

        # 1. BUSCAMOS LOS JOBS ACTIVOS
        jobs = db.query(models.Job).filter(models.Job.provider_id == worker_id).all()

        for job in jobs:
            req = job.request
            srv = req.service if req else None
            if not srv: continue
            
            fecha_buscada = job.started_at.isoformat() if job.started_at else None
            precio_mosca = req.proposed_price if req else srv.base_price
            service_id_str = str(srv.id)
            
            unique_results[service_id_str] = {
                "id": service_id_str, 
                "request_id": str(req.id) if req else None, 
                "title": srv.title,
                "description": srv.description, 
                "base_price": float(precio_mosca) if precio_mosca else 0.0,
                "category_id": str(srv.category_id),
                "client_id": str(job.client_id),
                "latitude": srv.latitude,
                "longitude": srv.longitude,
                "exact_address": srv.exact_address,
                "status": job.status.value if hasattr(job.status, 'value') else str(job.status),
                "is_active": srv.is_active,
                "created_at": fecha_buscada, 
                "image_urls": srv.image_urls if srv.image_urls else [], 
            }

        # 2. BUSCAMOS LAS POSTULACIONES PENDIENTES
        postulations = db.query(models.ServiceRequest, models.Service).join(
            models.Service, models.ServiceRequest.service_id == models.Service.id
        ).filter(
            models.ServiceRequest.worker_id == worker_id,
            models.ServiceRequest.status == "pending",
            models.Service.is_active == True
        ).all()

        for req, srv in postulations:
            service_id_str = str(srv.id)
            if service_id_str not in unique_results:
                unique_results[service_id_str] = {
                    "id": service_id_str, 
                    "request_id": str(req.id), 
                    "title": srv.title,
                    "description": req.description, 
                    "base_price": float(req.proposed_price) if req.proposed_price else 0.0,
                    "category_id": str(srv.category_id),
                    "client_id": str(srv.client_id),
                    "latitude": srv.latitude,
                    "longitude": srv.longitude,
                    "exact_address": srv.exact_address,
                    "status": "open", 
                    "is_active": srv.is_active,
                    "created_at": req.created_at.isoformat() if req.created_at else None,
                    "image_urls": srv.image_urls if srv.image_urls else [], 
                }
                
        return list(unique_results.values())
        
    except Exception as e:
        print(f"🚨 Error real en get_worker_applications: {e}")
        raise e

def withdraw_postulation(db: Session, request_id: str, user_id: str):
    postulation = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.id == request_id,
        models.ServiceRequest.worker_id == user_id 
    ).first()

    if not postulation:
        raise HTTPException(status_code=404, detail="Postulación no encontrada o no tienes permiso")

    db.delete(postulation)
    db.commit()
    return {"message": "Postulación retirada con éxito"}