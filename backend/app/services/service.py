from sqlalchemy.orm import Session
from sqlalchemy.orm import joinedload  # 👈 AÑADE ESTO ARRIBA
from app.services import models, schemas
from uuid import UUID
from fastapi import HTTPException, status
from datetime import datetime
from sqlalchemy import func, and_
from app.core.roles import Role
from sqlalchemy import or_
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

def get_services(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    include_inactive: bool = False
):
    """Devuelve servicios para el marketplace o el panel de administración."""
    query = db.query(models.Service).options(joinedload(models.Service.owner))

<<<<<<< HEAD
    if not include_inactive:
        query = query.filter(models.Service.is_active == True)

    query = query.filter(models.Service.status == models.JobStatus.OPEN)
=======
    # 🟢 Lógica para el Marketplace (Usuario normal)
    if not include_inactive:
        query = query.filter(
            models.Service.is_active == True,
            models.Service.status == models.JobStatus.OPEN
        )
    
    # 🟢 Lógica para el Administrador (include_inactive == True)
    # Al no entrar en el 'if' anterior, el administrador recibirá 
    # TODO: OPEN, MATCHED, CANCELLED, etc.
>>>>>>> 589898e546c3d0d41ed3aee83f29299f899f4c36

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
        .options(joinedload(models.Service.owner)) # 👈 AÑADE ESTA LÍNEA AQUÍ
        .filter(models.Service.id == service_id)
        .first()
    )

def get_my_services(db: Session, user_id: str):
    """Devuelve todos los servicios creados por el usuario logueado."""
    return (
        db.query(models.Service)
        .filter(
            models.Service.client_id == user_id,
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

    db.query(models.ServiceRequest).filter(models.ServiceRequest.service_id == service_id).delete()
    
    db.query(models.Job).filter(
        models.Job.client_id == service_entry.client_id,
    ).delete() 

    db.delete(service_entry)
    db.commit()
    
    return {"message": "Servicio eliminado físicamente por completo de la base de datos"}

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

        # 1. BUSCAMOS LOS JOBS ACTIVOS (Los que ya te aceptaron)
        jobs = db.query(models.Job).filter(models.Job.provider_id == worker_id).all()

        for job in jobs:
            req = job.request
            srv = req.service if req else None
            
            if not srv: continue
            
            fecha_buscada = job.started_at.isoformat() if job.started_at else None
            precio_mosca = req.proposed_price if req else srv.base_price

            service_id_str = str(srv.id) # 🚀 CREAMOS LA VARIABLE
            
            unique_results[service_id_str] = {
                "id": service_id_str, # MANDAMOS EL ID DEL SERVICIO
                "request_id": str(req.id) if req else None, # MANDAMOS EL ID DE LA SOLICITUD
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
            service_id_str = str(srv.id) # 🚀 AQUÍ FALTABA ESTA LÍNEA
            
            if service_id_str not in unique_results:
                unique_results[service_id_str] = {
                    "id": service_id_str, # MANDAMOS EL ID DEL SERVICIO
                    "request_id": str(req.id), # MANDAMOS EL ID DE LA SOLICITUD
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

# -------------------------------------------------------------------------
# JOBS & MATCH
# -------------------------------------------------------------------------

def accept_postulation(db: Session, request_id: str, current_user_id: str):
    postulation = db.query(models.ServiceRequest).filter(models.ServiceRequest.id == request_id).first()
    if not postulation:
        raise HTTPException(status_code=404, detail="La postulación no existe")

    service_entry = postulation.service
    
    # 2. Castear IDs a string para comparar sin errores de tipo UUID
    if str(service_entry.client_id) != str(current_user_id):
        raise HTTPException(status_code=403, detail="No tienes permiso")

    if service_entry.status != models.JobStatus.OPEN:
        raise HTTPException(status_code=400, detail="Servicio no disponible")

    try:
        # 3. Actualizar estados
        service_entry.status = models.JobStatus.MATCHED
        postulation.status = "accepted"
        
        # 4. Crear el Job
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
        
        # 5. RETORNAR DICCIONARIO (JSON) PARA FLUTTER
        return {"status": "success", "message": "Aceptado correctamente"}

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

    # 2. Verificación de identidad (Seguridad total)
    is_client = str(job.client_id) == str(user_id)
    is_worker = str(job.provider_id) == str(user_id)

    if not (is_client or is_worker):
        raise HTTPException(status_code=403, detail="No tienes permiso para modificar este trabajo")

    if is_worker:
        if job.status == models.JobStatus.WAITING_CONFIRMATION:
            return job 
        
        job.status = models.JobStatus.WAITING_CONFIRMATION
        
        if job.request and job.request.service:
            job.request.service.status = models.JobStatus.WAITING_CONFIRMATION
            
        db.commit()
        db.refresh(job)
        return job

    elif is_client:
        job.status = models.JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        
        if job.request and job.request.service:
            job.request.service.status = models.JobStatus.COMPLETED
            job.request.service.is_active = False

        db.commit()
        db.refresh(job)
        return job

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
            print(f"♻️ Servicio {job.request.service.id} re-abierto porque el trabajador canceló.")
        else:
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
    """
    Busca el servicio recién creado y le inyecta las URLs de AWS S3
    """
    # 1. Buscamos el servicio en la base de datos
    db_service = db.query(models.Service).filter(models.Service.id == service_id).first()
    
    # 2. Si existe, actualizamos su arreglo de imágenes
    if db_service:
        db_service.image_urls = image_urls
        db.commit()            # Guardamos cambios
        db.refresh(db_service) # Refrescamos el objeto
        
    return db_service
