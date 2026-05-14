from sqlalchemy.orm import Session, joinedload
from app.services import models, schemas
from uuid import UUID
from fastapi import HTTPException
from app.core.roles import Role

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

def get_services(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    include_inactive: bool = False
):
    """Devuelve servicios para el marketplace o el panel de administración."""
    query = db.query(models.Service).options(joinedload(models.Service.owner))

    if not include_inactive:
        query = query.filter(
            models.Service.is_active == True,
            models.Service.status == models.JobStatus.OPEN
        )

    return (
        query
        .order_by(models.Service.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    
def get_service_by_id(db: Session, service_id: str):
    return (
        db.query(models.Service)
        .options(joinedload(models.Service.owner))
        .filter(models.Service.id == service_id)
        .first()
    )

def get_my_services(db: Session, user_id: str):
    """Devuelve todos los servicios creados por el usuario logueado."""
    from app.services.models import ServiceRequest, Job, Review

    services = (
        db.query(models.Service)
        .filter(
            models.Service.client_id == user_id,
        )
        .order_by(models.Service.created_at.desc())
        .all()
    )

    result = []
    for service_obj in services:
        already_reviewed = False

        for request in service_obj.requests:
            if request.job and request.job.status != models.JobStatus.CANCELLED:
                existing_review = db.query(Review).filter(
                    Review.job_id == request.job.id,
                    Review.reviewer_id == user_id
                ).first()
                if existing_review:
                    already_reviewed = True
                break

        setattr(service_obj, 'already_reviewed', already_reviewed)
        result.append(service_obj)

    return result

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

    db.query(models.ServiceRequest).filter(models.ServiceRequest.service_id == service_id).delete()
    db.query(models.Job).filter(models.Job.client_id == service_entry.client_id).delete() 

    db.delete(service_entry)
    db.commit()
    return {"message": "Servicio eliminado físicamente por completo de la base de datos"}

def search_services(db: Session, search_query: str):
    query_clean = search_query.strip().lower()
    search_term = f"%{query_clean}%" 
    return (
        db.query(models.Service)
        .filter(
            (models.Service.title.ilike(search_term)) | 
            (models.Service.description.ilike(search_term))
        )
        .filter(models.Service.status == models.JobStatus.OPEN) 
        .all()
    )

def update_service_images(db: Session, service_id: str, image_urls: list[str]):
    db_service = db.query(models.Service).filter(models.Service.id == service_id).first()
    if db_service:
        db_service.image_urls = image_urls
        db.commit()            
        db.refresh(db_service) 
    return db_service