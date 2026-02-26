from sqlalchemy.orm import Session
from app.services import models, schemas
from uuid import UUID
from fastapi import HTTPException, status
from datetime import datetime
from sqlalchemy import func, and_
from app.core.roles import Role

# -------------------------------------------------------------------------
# CATEGORIES 
# -------------------------------------------------------------------------

def create_category(db: Session, category: schemas.CategoryCreate):
    existing_category = db.query(models.Category).filter(
        models.Category.name == category.name
    ).first()

    if existing_category:
        if existing_category.is_active:
            raise HTTPException(status_code=400, detail="La categoría ya existe y está activa.")
        existing_category.is_active = True
        existing_category.description = category.description
        db.commit()
        db.refresh(existing_category)
        return existing_category

    db_category = models.Category(**category.dict())
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category

def get_categories(db: Session, skip: int = 0, limit: int = 100):
    return (
        db.query(models.Category)
        .filter(models.Category.is_active == True)
        .offset(skip)
        .limit(limit)
        .all()
    )

def update_category(db: Session, category_id: UUID, data: schemas.CategoryUpdate):
    category = db.query(models.Category).filter(
        models.Category.id == str(category_id)
    ).first()
    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    if data.name is not None:
        category.name = data.name
    if data.description is not None:
        category.description = data.description
    db.commit()
    db.refresh(category)
    return category

def delete_category_hard(db: Session, category_id: str):
    category = db.query(models.Category).filter(
        models.Category.id == category_id
    ).first()
    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    db.delete(category)
    db.commit()
    return {"message": "Categoría eliminada correctamente"}


# -------------------------------------------------------------------------
# SERVICES
# -------------------------------------------------------------------------

def create_service(db: Session, service_data: schemas.ServiceCreate, client_id: UUID):
    category = db.query(models.Category).filter(models.Category.id == str(service_data.category_id)).first()
    if not category:
        raise HTTPException(status_code=400, detail="Error: El ID de categoría no existe o es inválido.")

    db_service = models.Service(
        title=service_data.title,
        summary=service_data.summary,
        description=service_data.description,
        base_price=service_data.base_price,
        category_id=str(service_data.category_id),
        client_id=str(client_id),
        latitude=service_data.latitude,
        longitude=service_data.longitude,
        exact_address=service_data.exact_address,
        image_urls=service_data.image_urls,
        status=models.JobStatus.OPEN 
    )
    db.add(db_service)
    db.commit()
    db.refresh(db_service)
    return db_service

def get_services(db: Session, skip: int = 0, limit: int = 100):
    """Devuelve los servicios abiertos para la Home/Marketplace."""
    return (
        db.query(models.Service)
        .filter(
            models.Service.is_active == True,
            models.Service.status == models.JobStatus.OPEN
        )
        .order_by(models.Service.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

def get_service_by_id(db: Session, service_id: str):
    """
    🚀 SOLUCIÓN AL ERROR: Esta función faltaba y es necesaria 
    para ver los detalles de un servicio específico.
    """
    return db.query(models.Service).filter(models.Service.id == service_id).first()

def get_my_services(db: Session, user_id: str):
    """Devuelve todos los servicios creados por el usuario logueado."""
    return (
        db.query(models.Service)
        .filter(
            models.Service.client_id == user_id,
            models.Service.is_active == True
        )
        .order_by(models.Service.created_at.desc())
        .all()
    )

def get_services_by_category(db: Session, category_id: str):
    return (
        db.query(models.Service)
        .filter(
            models.Service.category_id == category_id,
            models.Service.is_active == True,
            models.Service.status == models.JobStatus.OPEN
        )
        .all()
    )

def update_service(db: Session, service_id: str, data: schemas.ServiceUpdate, user_id: str, user_role: str):
    service_entry = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service_entry:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    is_admin = user_role == Role.ADMIN
    is_owner = str(service_entry.client_id) == str(user_id)

    if not (is_admin or is_owner):
        raise HTTPException(status_code=403, detail="No tienes permiso")

    if service_entry.status != models.JobStatus.OPEN:
        raise HTTPException(status_code=400, detail="No puedes editar un servicio que ya fue tomado o finalizado")

    if data.category_id is not None:
        category = db.query(models.Category).filter(models.Category.id == str(data.category_id)).first()
        if not category:
            raise HTTPException(status_code=400, detail="La categoría no existe")
        service_entry.category_id = str(data.category_id)

    fields = ["title", "summary", "description", "base_price", "latitude", "longitude", "exact_address", "image_urls"]
    for field in fields:
        value = getattr(data, field, None)
        if value is not None:
            setattr(service_entry, field, value)

    db.commit()
    db.refresh(service_entry)
    return service_entry

def cancel_service(db: Session, service_id: str, user_id: str, user_role: str):
    service_entry = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service_entry:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")
    
    is_admin = user_role == Role.ADMIN
    is_owner = service_entry.client_id == str(user_id)
    is_assigned_worker = False
    
    if service_entry.status == models.JobStatus.MATCHED:
        active_job = db.query(models.Job).filter(
            models.Job.client_id == service_entry.client_id,
            models.Job.status == models.JobStatus.MATCHED
        ).first()
        if active_job and str(active_job.provider_id) == str(user_id):
            is_assigned_worker = True

    if not (is_owner or is_admin or is_assigned_worker):
        raise HTTPException(status_code=403, detail="No tienes permiso para cancelar")
        
    service_entry.status = models.JobStatus.CANCELLED
    db.commit()
    db.refresh(service_entry)
    return {"message": "Servicio cancelado correctamente", "status": "cancelled"}

def delete_service(db: Session, service_id: str):
    service_entry = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service_entry:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    service_entry.is_active = False
    if service_entry.status == models.JobStatus.MATCHED:
        job = db.query(models.Job).filter(
            models.Job.client_id == service_entry.client_id,
            models.Job.status == models.JobStatus.MATCHED
        ).first()
        if job:
            job.status = models.JobStatus.CANCELLED

    db.commit()
    return {"message": "Servicio eliminado (desactivado) por el Administrador"}


# -------------------------------------------------------------------------
# SERVICE REQUESTS (OFERTAS)
# -------------------------------------------------------------------------

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


# -------------------------------------------------------------------------
# JOBS & MATCH
# -------------------------------------------------------------------------

def accept_postulation(db: Session, request_id: str, current_user_id: str):
    postulation = db.query(models.ServiceRequest).filter(models.ServiceRequest.id == request_id).first()
    if not postulation:
        raise HTTPException(status_code=404, detail="Postulación no encontrada")

    service_entry = postulation.service
    if service_entry.client_id != str(current_user_id):
        raise HTTPException(status_code=403, detail="Solo el dueño elige")

    if service_entry.status != models.JobStatus.OPEN:
        raise HTTPException(status_code=400, detail="Servicio no disponible")

    try:
        service_entry.status = models.JobStatus.MATCHED
        postulation.status = "accepted"
        
        new_job = models.Job(
            request_id=postulation.id,
            provider_id=postulation.worker_id,
            client_id=service_entry.client_id,
            status=models.JobStatus.MATCHED,
            final_price=postulation.proposed_price if postulation.proposed_price else service_entry.base_price,
            started_at=datetime.utcnow()
        )
        db.add(new_job)
        db.commit()
        # Ya no hacemos db.refresh ni return new_job para evitar problemas
        return True
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

def complete_job(db: Session, job_id: str, user_id: str):
    job = db.query(models.Job).join(models.ServiceRequest).filter(
        models.ServiceRequest.service_id == job_id,
        models.Job.status == models.JobStatus.MATCHED
    ).first()

    if not job:
        job = db.query(models.Job).filter(models.Job.id == job_id).first()

    if not job:
        raise HTTPException(status_code=404, detail="No existe el trabajo activo")

    is_client = str(job.client_id) == str(user_id)
    is_worker = str(job.provider_id) == str(user_id)

    if not (is_client or is_worker):
        raise HTTPException(status_code=403, detail="No tienes permiso")

    job.status = models.JobStatus.COMPLETED
    job.completed_at = datetime.utcnow()
    
    if job.request and job.request.service:
        job.request.service.status = models.JobStatus.COMPLETED

    db.commit()
    db.refresh(job)
    return job

def cancel_job(db: Session, job_id: str, user_id: str, user_role: str):
    job = db.query(models.Job).filter(models.Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job no encontrado")

    is_admin = user_role == Role.ADMIN
    is_client = str(job.client_id) == str(user_id)
    is_worker = str(job.provider_id) == str(user_id)

    if not (is_admin or is_client or is_worker):
        raise HTTPException(status_code=403, detail="No tienes permiso")

    job.status = models.JobStatus.CANCELLED
    if job.request and job.request.service:
        job.request.service.status = models.JobStatus.CANCELLED
    
    db.commit()
    db.refresh(job)
    return job

# -------------------------------------------------------------------------
# Busquedas y Stats
# -------------------------------------------------------------------------

def get_top_categories(db: Session, limit: int = 5):
    return (
        db.query(models.Category)
        .outerjoin(
            models.Service,
            and_(
                models.Category.id == models.Service.category_id,
                models.Service.is_active == True
            )
        )
        .group_by(models.Category.id)
        .order_by(func.count(models.Service.id).desc())
        .limit(limit)
        .all()
    )

def search_services(db: Session, search_query: str):
    search_term = f"%{search_query}%" 
    return (
        db.query(models.Service)
        .filter(
            (models.Service.title.ilike(search_term)) | 
            (models.Service.description.ilike(search_term))
        )
        .filter(models.Service.status == models.JobStatus.OPEN) 
        .all()
    )