from fastapi import APIRouter, Depends, HTTPException, status, Form, File, UploadFile
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from app.utils.s3 import upload_service_evidence_to_s3

from app.auth.security import check_role, get_current_user
from app.core.roles import Role
from app.db.database import get_db
from app.services import schemas, service
from app.auth import models as auth_models

router = APIRouter()

# -----------------------------
# CATEGORIES
# -----------------------------

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

# -----------------------------
# SERVICES
# -----------------------------

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
def list_services(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return service.get_services(db, skip=skip, limit=limit)

@router.get("/category/{category_id}", response_model=List[schemas.Service])
def services_by_category(category_id: str, db: Session = Depends(get_db)):
    return service.get_services_by_category(db, category_id)

@router.get("/{service_id}", response_model=schemas.Service) # schemas.Service es tu modelo de salida
def read_service(service_id: str, db: Session = Depends(get_db)):
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

@router.delete("/{service_id}", status_code=status.HTTP_200_OK)
def delete_service(
    service_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN])) # ✅ SOLO ADMIN
):
    """
    Endpoint para que el ADMIN borre un servicio del mapa.
    """
    return service.delete_service(db, service_id)

# -----------------------------
# SERVICE REQUESTS (POSTULACIONES)
# -----------------------------

@router.post("/service-requests", response_model=schemas.ServiceRequest)
def create_service_request(
    request_data: schemas.ServiceRequestCreate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.WORKER]))
):
    return service.create_service_request(db, request_data, worker_id=current_user.id)

@router.get("/my-requests", response_model=List[schemas.Service])
def read_my_requests(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Obtiene SOLO los servicios creados por el usuario logueado (Abiertos, Matched, etc.)"""
    return service.get_my_services(db, user_id=str(current_user.id))

# -----------------------------
# FLUJO DE SELECCIÓN (CLIENTE)
# -----------------------------

@router.get("/{service_id}/offers", response_model=List[schemas.ServiceRequest])
def get_service_offers(
    service_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Ver ofertas recibidas (Solo dueño o admin)"""
    return service.get_offers_by_service(db, service_id, current_user.id)

# -----------------------------
# MATCH & JOB MANAGEMENT
# -----------------------------

@router.post("/accept-postulation/{request_id}", response_model=schemas.Job)
def accept_worker_postulation(
    request_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """El cliente acepta al trabajador: Crea el Match y el Job"""
    return service.accept_postulation(db, request_id, current_user.id)

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
    """
    NUEVO ENDPOINT: Cancela un Job que ya estaba en 'matched'.
    Permitido para: ADMIN, el WORKER asignado o el CLIENTE dueño.
    """
    return service.cancel_job(db, job_id, current_user.id, current_user.role)

@router.put("/{service_id}/cancel")
def cancel_service(
    service_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """
    MODIFICADO: Cancela el servicio original (esté en 'open' o 'matched').
    ✅ ADMIN, WORKER y CLIENT pueden usarlo.
    """
    return service.cancel_service(db, service_id, current_user.id, current_user.role)

# -----------------------------
# NUEVOS ENDPOINTS DE BÚSQUEDA
# -----------------------------

@router.get("/top-categories", response_model=List[schemas.Category])
def get_top_categories_route(db: Session = Depends(get_db)):
    """Obtiene las 5 categorías con más servicios publicados."""
    return service.get_top_categories(db, limit=5)

@router.get("/search", response_model=List[schemas.Service])
def search_services_route(
    query: str, 
    db: Session = Depends(get_db)
):
    """Busca servicios por título o descripción."""
    return service.search_services(db, query)