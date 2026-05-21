from sqlalchemy.orm import Session
from sqlalchemy.orm import joinedload 
from app.services import models, schemas
from uuid import UUID
from fastapi import HTTPException, status
from datetime import datetime
from sqlalchemy import func, and_
from app.core.roles import Role
from sqlalchemy import or_
from app.auth import models as auth_models
from app.services.notifications import service as notif_service
import logging

logger = logging.getLogger(__name__)
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
        existing_category.is_active = True  # type: ignore
        existing_category.description = category.description  # type: ignore
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
        category.name = data.name  # type: ignore
    if data.description is not None:
        category.description = data.description  # type: ignore
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

    # 🟢 Lógica para el Marketplace (Usuario normal)
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
    return (
        db.query(models.Service)
        .options(
            joinedload(models.Service.requests)
            .joinedload(models.ServiceRequest.job)
        )
        .options(
            joinedload(models.Service.requests)
            .joinedload(models.ServiceRequest.worker)
        )
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
        category = db.query(models.Category).filter(models.Category.id == str(data.category_id)).first()  # type: ignore
        if not category:
            raise HTTPException(status_code=400, detail="La categoría no existe")
        service_entry.category_id = str(data.category_id)  # type: ignore

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
        active_job = db.query(models.Job).join(models.ServiceRequest).filter(
            models.ServiceRequest.service_id == service_entry.id,
            models.Job.status == models.JobStatus.MATCHED
        ).first()
        if active_job and str(active_job.provider_id) == str(user_id):
            is_assigned_worker = True

    if not (is_owner or is_admin or is_assigned_worker):
        raise HTTPException(status_code=403, detail="No tienes permiso para cancelar")
        
    service_entry.status = models.JobStatus.CANCELLED  # type: ignore
    db.commit()
    db.refresh(service_entry)
    return {"message": "Servicio cancelado correctamente", "status": "cancelled"}

def delete_service(db: Session, service_id: str):
    service_entry = db.query(models.Service).filter(models.Service.id == service_id).first()
    
    if not service_entry:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    # 1. Obtener IDs de las solicitudes (ServiceRequests) de este servicio
    request_ids_query = db.query(models.ServiceRequest.id).filter(models.ServiceRequest.service_id == service_id).all()
    request_ids = [r[0] for r in request_ids_query]
    
    # 2. Borrar los Jobs asociados a esas solicitudes
    if request_ids:
        db.query(models.Job).filter(models.Job.request_id.in_(request_ids)).delete(synchronize_session=False)

    # 3. Borrar las solicitudes
    db.query(models.ServiceRequest).filter(models.ServiceRequest.service_id == service_id).delete(synchronize_session=False)
    
    # 4. Borrar el servicio
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

    # 🔔 Notificar al cliente sobre la nueva postulación (Migrado)
    service_entry = db.query(models.Service).filter(models.Service.id == str(request_data.service_id)).first()
    worker = db.query(auth_models.User).filter(auth_models.User.id == str(worker_id)).first()
    if worker and service_entry:
        notif_service.notify_new_application(db, service_entry, worker)

    return db_request

def get_offers_by_service(db: Session, service_id: str, client_id: str, is_admin: bool = False):
    from sqlalchemy.orm import joinedload
    db_service = db.query(models.Service)\
        .options(joinedload(models.Service.requests).joinedload(models.ServiceRequest.worker))\
        .filter(models.Service.id == service_id).first()
    if not db_service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    if is_admin or str(db_service.client_id) == str(client_id):
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

    postulation.description = description  # type: ignore
    postulation.proposed_price = proposed_price  # type: ignore

    db.commit()
    db.refresh(postulation)
    
    return postulation

def get_worker_applications(db: Session, worker_id: str):
    try:
        unique_results = {}

        # 1. JOBS ACTIVOS: cargamos todo en UNA sola query con joinedload
        jobs = (
            db.query(models.Job)
            .options(
                joinedload(models.Job.request).joinedload(models.ServiceRequest.service)
            )
            .filter(models.Job.provider_id == worker_id)
            .all()
        )

        for job in jobs:
            req = job.request
            srv = req.service if req else None

            if not srv:
                continue

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

        # 2. POSTULACIONES PENDIENTES: una sola query con JOIN (ya estaba bien)
        postulations = (
            db.query(models.ServiceRequest, models.Service)
            .join(models.Service, models.ServiceRequest.service_id == models.Service.id)
            .filter(
                models.ServiceRequest.worker_id == worker_id,
                models.ServiceRequest.status == "pending",
                models.Service.is_active == True,
            )
            .all()
        )

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

# -------------------------------------------------------------------------
# JOBS & MATCH
# -------------------------------------------------------------------------

def accept_postulation(db: Session, request_id: str, current_user_id: str):
    postulation = db.query(models.ServiceRequest).filter(models.ServiceRequest.id == request_id).first()
    if not postulation:
        raise HTTPException(status_code=404, detail="La postulación no existe")

    service_entry = postulation.service
    
    if str(service_entry.client_id) != str(current_user_id):
        raise HTTPException(status_code=403, detail="No tienes permiso")

    if service_entry.status != models.JobStatus.OPEN:
        raise HTTPException(status_code=400, detail="Servicio no disponible")

    try:
        # 3. Actualizar estados
        service_entry.status = models.JobStatus.MATCHED  # type: ignore
        postulation.status = "accepted"  # type: ignore
        
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

        # 🚀 Crear o buscar la conversación automáticamente al aceptar
        from app.services.chats import service as chat_service
        convo = chat_service.get_or_create_conversation(db, str(postulation.id), str(current_user_id))

        # 🔔 Notificar al trabajador que fue aceptado (Con ID de chat para navegación directa)
        notif_service.notify_job_accepted(db, new_job, service_entry.title, str(convo.id))
        
        return {
            "status": "success", 
            "message": "Aceptado correctamente", 
            "conversation_id": str(convo.id),
            "job_id": str(new_job.id)
        }

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

    is_client = str(job.client_id) == str(user_id)
    is_worker = str(job.provider_id) == str(user_id)

    if not (is_client or is_worker):
        raise HTTPException(status_code=403, detail="No tienes permiso para modificar este trabajo")

    if is_worker:
        if job.status == models.JobStatus.WAITING_CONFIRMATION:
            return job 
        
        job.status = models.JobStatus.WAITING_CONFIRMATION  # type: ignore
        
        if job.request and job.request.service:
            job.request.service.status = models.JobStatus.WAITING_CONFIRMATION  # type: ignore
            
        db.commit()
        db.refresh(job)

        # 🔔 Notificar al cliente que el trabajo quedó listo para confirmar
        notif_service.notify_job_waiting_confirmation(db, job)

        return job

    elif is_client:
        job.status = models.JobStatus.COMPLETED  # type: ignore
        job.completed_at = datetime.utcnow()  # type: ignore
        
        if job.request and job.request.service:
            job.request.service.status = models.JobStatus.COMPLETED  # type: ignore
            job.request.service.is_active = False  # type: ignore

    if is_worker or is_client:
        # Si ya está completado, no hacemos nada
        if job.status == models.JobStatus.COMPLETED:
            return job

        # pyrefly: ignore [bad-assignment]
        job.status = models.JobStatus.COMPLETED
        # pyrefly: ignore [bad-assignment, deprecated]
        job.completed_at = datetime.utcnow()
        
        if job.request and job.request.service:
            job.request.service.status = models.JobStatus.COMPLETED
            job.request.service.is_active = False
            
        db.commit()
        db.refresh(job)

        # 🔔 Notificar a la otra parte
        if is_worker:
            notif_service.notify_job_completed(db, job) # 🚀 Ahora enviamos notificación de fin total
        else:
            notif_service.notify_job_completed(db, job)

        # 🔒 BLOQUEAR EL CHAT: Al finalizar el trabajo, se cierra la conversación
        try:
            convo = db.query(models.Conversation).filter(models.Conversation.request_id == str(job.request_id)).first()
            if convo:
                convo.status = models.ConversationStatus.CLOSED.value # type: ignore
                db.commit()
        except Exception as e:
            logger.warning(f"⚠️ No se pudo cerrar el chat al finalizar el trabajo: {e}")

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
    # is_admin = user_role == Role.ADMIN # Role might be different now

    if not (is_worker or is_client):
        raise HTTPException(status_code=403, detail="No tienes permiso para cancelar")

    job.status = models.JobStatus.CANCELLED  # type: ignore
    
    if job.request and job.request.service:
        if is_worker:
            job.request.service.status = models.JobStatus.OPEN  # type: ignore
            print(f"♻️ Servicio {job.request.service.id} re-abierto porque el trabajador canceló.")
        else:
            job.request.service.status = models.JobStatus.CANCELLED  # type: ignore

    db.commit()
    db.refresh(job)

    # 🔒 BLOQUEAR EL CHAT: Al cancelar el trabajo, se cierra la conversación
    try:
        convo = db.query(models.Conversation).filter(models.Conversation.request_id == str(job.request_id)).first()
        if convo:
            convo.status = models.ConversationStatus.CLOSED.value # type: ignore
            db.commit()
    except Exception as e:
        logger.warning(f"⚠️ No se pudo cerrar el chat al cancelar el trabajo: {e}")

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
    db_service = db.query(models.Service).filter(models.Service.id == service_id).first()
    if db_service:
        db_service.image_urls = image_urls  # type: ignore
        db.commit()            # Guardamos cambios
        db.refresh(db_service) # Refrescamos el objeto
        
    return db_service
