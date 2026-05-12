from fastapi import APIRouter, Depends, HTTPException, status, Form, File, UploadFile
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from fastapi.responses import JSONResponse
from app.utils.s3 import upload_service_evidence_to_s3
from app.auth.security import check_role, get_current_user
from app.core.roles import Role
from app.db.database import get_db
from app.services import schemas, service
from app.auth import models as auth_models

router = APIRouter()

# =================================================================
# 1. CATEGORÍAS (Rutas /categories)
# =================================================================

@router.post("/categories", response_model=schemas.Category, status_code=status.HTTP_201_CREATED)
def create_category(
    category: schemas.CategoryCreate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    return service.create_category(db, category)

@router.get("/categories", response_model=List[schemas.Category])
def list_categories(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return service.get_categories(db, skip=skip, limit=limit)

@router.put("/categories/{category_id}", dependencies=[Depends(check_role([Role.ADMIN]))])
def update_category(category_id: UUID, category_data: schemas.CategoryUpdate, db: Session = Depends(get_db)):
    return service.update_category(db, category_id, category_data)

@router.delete("/categories/{category_id}")
def delete_category(category_id: str, db: Session = Depends(get_db), current_user = Depends(check_role([Role.ADMIN]))):
    return service.delete_category(db, category_id)


# =================================================================
# 2. SERVICIOS - RUTAS ESTÁTICAS Y DE BÚSQUEDA (Prioridad Alta 🚀)
# =================================================================
# Estas deben ir ANTES que /{service_id} para evitar errores 404.

@router.post("/", response_model=schemas.Service)
async def create_service(
    title: str = Form(...),
    description: str = Form(...),
    category_id: str = Form(...),
    base_price: float = Form(0.0), # Valor por defecto
    summary: Optional[str] = Form(None),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    exact_address: Optional[str] = Form(None),
    files: Optional[List[UploadFile]] = File(None), # ¡Aquí vienen las fotos de Flutter!
    db: Session = Depends(get_db),
    current_user = Depends(check_role([Role.CLIENT, Role.ADMIN]))
):
    # 1. Armamos el esquema MANUALMENTE
    service_data = schemas.ServiceCreate(
        title=title,
        description=description,
        summary=summary,
        base_price=base_price,
        category_id=category_id,
        latitude=latitude,
        longitude=longitude,
        exact_address=exact_address,
        image_urls=[] # Inicialmente vacío
    )

    # 2. Guardamos en la Base de Datos para obtener el ID
    new_service = service.create_service(db, service_data, client_id=current_user.id)

    # 3. Subimos las fotos a AWS S3 (Usando la nueva función que te doy abajo)
    if files and len(files) > 0:
        image_urls = []
        for file in files:
            # Usamos la nueva función adaptada para servicios
            url = await upload_service_evidence_to_s3(file, new_service.id)
            if url:
                image_urls.append(url)
        
        # 4. Actualizamos el servicio en la DB con las URLs
        # (Asegúrate de que Juan Luis tenga este método en su CRUD)
        new_service = service.update_service_images(db, new_service.id, image_urls)

    return new_service

@router.get("/", response_model=List[schemas.Service])
def list_services(
    skip: int = 0, 
    limit: int = 100, 
    include_inactive: bool = False, # 👈 Nuevo parámetro opcional
    db: Session = Depends(get_db)
):
    return service.get_services(db, skip=skip, limit=limit, include_inactive=include_inactive)

@router.get("/top-categories", response_model=List[schemas.Category])
def get_top_categories_route(db: Session = Depends(get_db)):
    """Obtiene las 5 categorías con más servicios publicados."""
    return service.get_top_categories(db, limit=5)

@router.get("/search", response_model=List[schemas.Service])
def search_services_route(query: str, db: Session = Depends(get_db)):
    """Busca servicios por título o descripción."""
    return service.search_services(db, query)

@router.get("/my-requests", response_model=List[schemas.Service])
def read_my_requests(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Obtiene SOLO los servicios creados por el usuario logueado."""
    return service.get_my_services(db, user_id=str(current_user.id))

@router.get("/category/{category_id}", response_model=List[schemas.Service])
def services_by_category(category_id: str, db: Session = Depends(get_db)):
    return service.get_services_by_category(db, category_id)

# =================================================================
# 3. POSTULACIONES (SERVICE REQUESTS)
# =================================================================

@router.post("/service-requests", response_model=schemas.ServiceRequest)
def create_service_request(
    request_data: schemas.ServiceRequestCreate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.WORKER]))
):
    return service.create_service_request(db, request_data, worker_id=current_user.id)

@router.put("/service-requests/{request_id}")
def update_postulation(
    request_id: str, 
    payload: schemas.UpdatePostulationRequest, 
    db: Session = Depends(get_db), 
    current_user_id: str = Depends(get_current_user)
):
    db_request = db.query(models.ServiceRequest).filter(models.ServiceRequest.id == request_id).first()

    if not db_request:
        raise HTTPException(status_code=404, detail="Postulación no encontrada")

    if str(db_request.worker_id) != str(current_user_id):
        raise HTTPException(status_code=403, detail="No tienes permiso para editar esto")

    db_request.description = payload.description
    db_request.proposed_price = payload.proposed_price

    db.commit()
    db.refresh(db_request)
    
    return {"status": "success", "message": "Propuesta actualizada"}

@router.get("/worker/my-applications")
def get_my_applications(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user) # Usamos get_current_user para evitar fallos de roles
):
    try:
        return service.get_worker_applications(db, str(current_user.id))
    except Exception as e:
        # Esto imprimirá el error real en tu terminal de Python
        print(f"🚨 ERROR 500 EN /worker/my-applications: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# =================================================================
# 4. GESTIÓN DE JOBS Y MATCHES (Acciones Específicas)
# =================================================================

@router.post("/accept-postulation/{request_id}")
def accept_worker_postulation(
    request_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    # Ejecutamos la función que guarda en base de datos
    service.accept_postulation(db, request_id, current_user.id)
    
    # 🚀 Forzamos una respuesta 200 OK súper limpia
    return JSONResponse(status_code=200, content={"status": "success", "message": "Trabajo aceptado"})

@router.put("/jobs/{job_id}/complete", response_model=schemas.Job)
def complete_job_status(
    job_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.CLIENT, Role.WORKER, Role.ADMIN]))
):
    try:
        updated_job = service.complete_job(db, job_id, current_user.id)
        return updated_job
    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"🚨 Error inesperado en el router: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/service-requests/{request_id}")
def withdraw_postulation(
    request_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    return service.withdraw_postulation(db, request_id, current_user.id)

@router.put("/jobs/{job_id}/cancel", response_model=schemas.Job)
def cancel_job_status(
    job_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Cancela un Job que ya estaba en 'matched'."""
    return service.cancel_job(db, job_id, current_user.id, current_user.role)

# =================================================================
# 4.5. ADMIN ONLY ENDPOINTS (Jobs & Disputes)
# =================================================================

@router.get("/admin/jobs/all")
def get_all_jobs_admin(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """Devuelve TODOS los jobs (MATCHED, COMPLETED, CANCELLED) con datos extra para el panel admin."""
    from sqlalchemy.orm import joinedload
    jobs = db.query(models.Job).options(
        joinedload(models.Job.request).joinedload(models.ServiceRequest.service).joinedload(models.Service.category)
    ).order_by(models.Job.started_at.desc()).all()
    
    result = []
    for job in jobs:
        # Obtenemos info del cliente y trabajador
        client = db.query(auth_models.User).filter(auth_models.User.id == job.client_id).first()
        worker = db.query(auth_models.User).filter(auth_models.User.id == job.provider_id).first()
        service_obj = job.request.service if job.request else None
        
        # Calculate applicants count
        applicants = 0
        if service_obj:
            applicants = db.query(models.ServiceRequest).filter(models.ServiceRequest.service_id == service_obj.id).count()

        result.append({
            "id": job.id,
            "status": job.status.value,
            "final_price": float(job.final_price) if job.final_price else 0,
            "started_at": job.started_at,
            "completed_at": job.completed_at,
            "client_name": client.full_name if client else "Cliente Desconocido",
            "worker_name": worker.full_name if worker else "Trabajador Desconocido",
            "service_title": service_obj.title if service_obj else "Servicio Borrado",
            "title": service_obj.title if service_obj else "Servicio Borrado",
            "description": service_obj.description if service_obj else "",
            "category": service_obj.category.name if service_obj and service_obj.category else "Sin categoría",
            "location_city": service_obj.exact_address if service_obj and service_obj.exact_address else "Ubicación oculta",
            "image_urls": service_obj.image_urls if service_obj and service_obj.image_urls else [],
            "budget": float(service_obj.base_price) if service_obj and service_obj.base_price else 0,
            "applicants_count": applicants,
            "createdAt": service_obj.created_at.isoformat() if service_obj and service_obj.created_at else job.started_at.isoformat(),
        })
    return result

@router.get("/admin/conversations/all")
def get_all_conversations_admin(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """Devuelve todas las conversaciones para el visor de disputas del admin."""
    from sqlalchemy.orm import joinedload
    conversations = db.query(models.Conversation).order_by(models.Conversation.updated_at.desc()).all()
    
    result = []
    for conv in conversations:
        client = db.query(auth_models.User).filter(auth_models.User.id == conv.client_id).first()
        worker = db.query(auth_models.User).filter(auth_models.User.id == conv.worker_id).first()
        
        result.append({
            "id": conv.id,
            "request_id": conv.request_id,
            "status": conv.status,
            "created_at": conv.created_at,
            "updated_at": conv.updated_at,
            "client_name": client.full_name if client else "Cliente",
            "worker_name": worker.full_name if worker else "Trabajador",
        })
    return result

@router.get("/admin/conversations/{conversation_id}/messages")
def get_conversation_messages_admin(
    conversation_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """Devuelve los mensajes de un chat específico para el visor de disputas del admin."""
    messages = db.query(models.Message).filter(
        models.Message.conversation_id == conversation_id
    ).order_by(models.Message.created_at.asc()).all()
    
    result = []
    for msg in messages:
        sender = db.query(auth_models.User).filter(auth_models.User.id == msg.sender_id).first()
        result.append({
            "id": msg.id,
            "sender_id": msg.sender_id,
            "sender_name": sender.full_name if sender else "Usuario",
            "content": msg.content,
            "message_type": msg.message_type,
            "created_at": msg.created_at
        })
    return result


# =================================================================
# 5. SERVICIOS - RUTAS DINÁMICAS POR ID (Prioridad Baja ⬇️)
# =================================================================

@router.get("/{service_id}/offers", response_model=List[schemas.ServiceRequest])
def get_service_offers(
    service_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Ver ofertas recibidas (Solo dueño o admin)"""
    return service.get_offers_by_service(db, service_id, current_user.id)

@router.get("/{service_id}", response_model=schemas.Service)
def read_service(service_id: str, db: Session = Depends(get_db)):
    """Obtiene el detalle de un servicio específico"""
    db_service = service.get_service_by_id(db, service_id=service_id)
    if db_service is None:
        raise HTTPException(status_code=404, detail="El servicio no existe")
    return db_service

@router.put("/{service_id}", response_model=schemas.Service)
def update_service(
    service_id: str,
    service_data: schemas.ServiceUpdate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user),
):
    return service.update_service(
        db,
        service_id,
        service_data,
        current_user.id,
        current_user.role,
    )

@router.put("/{service_id}/cancel")
def cancel_service(
    service_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Cancela el servicio original (esté en 'open' o 'matched')."""
    return service.cancel_service(db, service_id, current_user.id, current_user.role)

@router.delete("/{service_id}", status_code=status.HTTP_200_OK)
def delete_service(
    service_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """Endpoint para que el ADMIN borre un servicio del mapa."""
    return service.delete_service(db, service_id)


@router.patch("/{service_id}/active", response_model=schemas.Service)
def toggle_service_visibility(
    service_id: str,
    payload: schemas.ServiceActiveUpdate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """Permite al administrador ocultar o mostrar un servicio sin borrarlo"""
    db_service = service.get_service_by_id(db, service_id)
    if not db_service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")
    
    db_service.is_active = payload.is_active
    db.commit()
    db.refresh(db_service)
    
    return db_service