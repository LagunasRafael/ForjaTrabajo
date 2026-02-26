from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from fastapi.responses import JSONResponse # Pon esto arriba si no lo tienes
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
def create_service(
    service_data: schemas.ServiceCreate,
    db: Session = Depends(get_db),
    current_user = Depends(check_role([Role.CLIENT, Role.ADMIN]))
):
    return service.create_service(db, service_data, client_id=current_user.id)

@router.get("/", response_model=List[schemas.Service])
def list_services(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return service.get_services(db, skip=skip, limit=limit)

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


# =================================================================
# 4. GESTIÓN DE JOBS Y MATCHES (Acciones Específicas)
# =================================================================


# 👇 Fíjate que le quité el response_model=schemas.Job. Esto evita el crash.
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
    current_user: auth_models.User = Depends(check_role([Role.CLIENT, Role.ADMIN]))
):
    """El trabajador marca como terminado"""
    return service.complete_job(db, job_id, current_user.id)

@router.put("/jobs/{job_id}/cancel", response_model=schemas.Job)
def cancel_job_status(
    job_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Cancela un Job que ya estaba en 'matched'."""
    return service.cancel_job(db, job_id, current_user.id, current_user.role)


# =================================================================
# 5. SERVICIOS - RUTAS DINÁMICAS POR ID (Prioridad Baja ⬇️)
# =================================================================
# ¡CUIDADO! Estas rutas capturan todo lo que venga después de /services/
# Por eso deben ir AL FINAL del archivo.

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