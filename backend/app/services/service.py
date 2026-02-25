from sqlalchemy.orm import Session
from app.services import models, schemas
from uuid import UUID
from fastapi import HTTPException, status
from datetime import datetime
from sqlalchemy import func
from app.core.roles import Role # Importante para validar el Admin

# -------------------------------------------------------------------------
# CATEGORIES 
# -------------------------------------------------------------------------

def create_category(db: Session, category: schemas.CategoryCreate):
    # 1. Buscamos si ya existe una categoría con ese nombre (activa o inactiva)
    # Nota: Es recomendable usar .lower() si quieres evitar "Carpinteria" vs "carpinteria"
    existing_category = db.query(models.Category).filter(
        models.Category.name == category.name
    ).first()

    if existing_category:
        if existing_category.is_active:
            # Si ya está activa, lanzamos el error de que ya existe
            raise HTTPException(status_code=400, detail="La categoría ya existe y está activa.")
        
        # 🚀 RE-ACTIVACIÓN: Si existe pero estaba oculta (is_active=False)
        existing_category.is_active = True
        existing_category.description = category.description
        db.commit()
        db.refresh(existing_category)
        return existing_category

    # 2. Si realmente no existe en la base de datos, la creamos normal
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
    
    # 🚨 NUEVA VALIDACIÓN ESTRICTA: Verificamos que la categoría sea real
    # Buscamos en la tabla de categorías si ese ID existe
    category = db.query(models.Category).filter(models.Category.id == str(service_data.category_id)).first()
    
    if not category:
        # Si no existe (o mandaron el campo vacío/inventado), bloqueamos la creación
        raise HTTPException(status_code=400, detail="Error: El ID de categoría no existe o es inválido.")

    # Si pasó la prueba de arriba, ahora sí lo guardamos
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
    return (
        db.query(models.Service)
        .filter(models.Service.is_active == True)
        .offset(skip)
        .limit(limit)
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

def cancel_service(db: Session, service_id: str, user_id: str, user_role: str):
    """
    MODIFICADO: Solo el dueño, el worker asignado o un Admin pueden cancelar.
    """
    service_entry = db.query(models.Service).filter(models.Service.id == service_id).first()
    
    if not service_entry:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")
    
    # 1. ¿Es Admin?
    is_admin = user_role == Role.ADMIN
    # 2. ¿Es el Cliente dueño?
    is_owner = service_entry.client_id == str(user_id)
    # 3. ¿Es el Worker asignado? (Solo si ya hay match)
    is_assigned_worker = False
    if service_entry.status == models.JobStatus.MATCHED:
        active_job = db.query(models.Job).filter(
            models.Job.client_id == service_entry.client_id, # Filtro por el cliente
            models.Job.status == models.JobStatus.MATCHED
        ).first() # Nota: esto es una simplificación, lo ideal es por request_id
        if active_job and str(active_job.provider_id) == str(user_id):
            is_assigned_worker = True

    if not (is_owner or is_admin or is_assigned_worker):
        raise HTTPException(status_code=403, detail="No tienes permiso para cancelar")
        
    service_entry.status = models.JobStatus.CANCELLED
    db.commit()
    db.refresh(service_entry)
    return {"message": "Servicio cancelado correctamente", "status": "cancelled"}

def delete_service(db: Session, service_id: str):
    """
    ELIMINAR SERVICIO: Solo el Admin puede ejecutar esto.
    Realiza un borrado lógico para mantener integridad referencial.
    """
    service_entry = db.query(models.Service).filter(
        models.Service.id == service_id
    ).first()

    if not service_entry:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    # Borrado lógico: lo hacemos invisible
    service_entry.is_active = False
    
    # Si tiene un Job asociado, también lo desactivamos
    if service_entry.status == models.JobStatus.MATCHED:
        # Buscamos el job y lo cancelamos por seguridad
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
    db_request = models.ServiceRequest(
        service_id=str(request_data.service_id),
        description=request_data.description,
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

    if str(db_service.client_id) != str(client_id):
        raise HTTPException(status_code=403, detail="No tienes permiso")

    return db_service.requests


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
            final_price=service_entry.base_price,
            started_at=datetime.utcnow()
        )
        db.add(new_job)
        db.commit()
        db.refresh(new_job)
        return new_job
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

def complete_job(db: Session, job_id: str, user_id: str):
    job = db.query(models.Job).filter(models.Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="No existe")
    if job.provider_id != str(user_id):
        raise HTTPException(status_code=403, detail="Solo el worker finaliza")

    job.status = models.JobStatus.COMPLETED
    job.completed_at = datetime.utcnow()
    job.request.service.status = models.JobStatus.COMPLETED
    db.commit()
    db.refresh(job)
    return job

def cancel_job(db: Session, job_id: str, user_id: str, user_role: str):
    """
    NUEVA: Cancela un Job activo. Sincroniza Service y Job a CANCELLED.
    Permitido para: CLIENTE, WORKER asignado y ADMIN.
    """
    job = db.query(models.Job).filter(models.Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job no encontrado")

    is_admin = user_role == Role.ADMIN
    is_client = str(job.client_id) == str(user_id)
    is_worker = str(job.provider_id) == str(user_id)

    if not (is_admin or is_client or is_worker):
        raise HTTPException(status_code=403, detail="No tienes permiso para cancelar este trabajo")

    job.status = models.JobStatus.CANCELLED
    # Sincronizamos el servicio padre a Cancelado también
    job.request.service.status = models.JobStatus.CANCELLED
    
    db.commit()
    db.refresh(job)
    return job

# ==========================================
# Busquedas y top categorias
# ==========================================
def get_top_categories(db: Session, limit: int = 5):
    """
    Busca todas las categorías, las cruza con los servicios,
    cuenta cuántos servicios tiene cada una y las ordena de mayor a menor.
    """
    top_categories = (
        db.query(models.Category)
        .outerjoin(models.Service, models.Category.id == models.Service.category_id)
        .group_by(models.Category.id)
        .order_by(func.count(models.Service.id).desc())
        .limit(limit)
        .all()
    )
    return top_categories

def search_services(db: Session, search_query: str):
    """
    Busca la palabra clave tanto en el título como en la descripción del servicio.
    Usa 'ilike' para que no importe si escriben con mayúsculas o minúsculas.
    """
    # Los % son comodines de SQL para decir "que contenga esta palabra en cualquier parte"
    search_term = f"%{search_query}%" 
    
    services = (
        db.query(models.Service)
        .filter(
            (models.Service.title.ilike(search_term)) | 
            (models.Service.description.ilike(search_term))
        )
        .all()
    )
    return services