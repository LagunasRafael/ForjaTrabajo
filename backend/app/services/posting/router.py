from fastapi import APIRouter, Depends, HTTPException, status, Form, File, UploadFile
from sqlalchemy.orm import Session
from typing import List, Optional

from app.db.database import get_db
from app.auth.security import check_role, get_current_user
from app.core.roles import Role
from app.auth import models as auth_models
from app.utils.s3 import upload_service_evidence_to_s3

# Importamos los schemas, models globales y el servicio local
from app.services import schemas, models
from app.services.posting import service

router = APIRouter()

@router.post("/", response_model=schemas.Service)
async def create_service(
    title: str = Form(...),
    description: str = Form(...),
    category_id: str = Form(...),
    base_price: float = Form(0.0),
    summary: Optional[str] = Form(None),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    exact_address: Optional[str] = Form(None),
    files: Optional[List[UploadFile]] = File(None), 
    db: Session = Depends(get_db),
    current_user = Depends(check_role([Role.CLIENT, Role.ADMIN]))
):
    service_data = schemas.ServiceCreate(
        title=title, description=description, summary=summary,
        base_price=base_price, category_id=category_id,
        latitude=latitude, longitude=longitude, exact_address=exact_address,
        image_urls=[] 
    )

    new_service = service.create_service(db, service_data, client_id=current_user.id)

    if files and len(files) > 0:
        image_urls = []
        for file in files:
            url = await upload_service_evidence_to_s3(file, new_service.id)
            if url: image_urls.append(url)
        new_service = service.update_service_images(db, new_service.id, image_urls)

    return new_service

@router.get("/", response_model=List[schemas.Service])
def list_services(skip: int = 0, limit: int = 100, include_inactive: bool = False, db: Session = Depends(get_db)):
    return service.get_services(db, skip=skip, limit=limit, include_inactive=include_inactive)

@router.get("/search", response_model=List[schemas.Service])
def search_services_route(query: str, db: Session = Depends(get_db)):
    return service.search_services(db, query)

@router.get("/my-requests", response_model=List[schemas.Service])
def read_my_requests(db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    services = service.get_my_services(db, user_id=str(current_user.id))
    result = []
    for svc in services:
        svc_dict = {
            "id": svc.id,
            "title": svc.title,
            "summary": svc.summary,
            "description": svc.description,
            "base_price": float(svc.base_price) if svc.base_price else 0.0,
            "category_id": svc.category_id,
            "client_id": svc.client_id,
            "latitude": svc.latitude,
            "longitude": svc.longitude,
            "exact_address": svc.exact_address,
            "image_urls": svc.image_urls or [],
            "status": svc.status.value if hasattr(svc.status, 'value') else str(svc.status),
            "is_active": svc.is_active,
            "created_at": svc.created_at,
            "author_name": svc.author_name,
            "author_image_url": svc.author_image_url,
            "request_id": svc.request_id,
            "worker_name": svc.worker_name,
            "worker_image_url": svc.worker_image_url,
            "worker_id": getattr(svc, 'worker_id', None),
            "already_reviewed": getattr(svc, 'already_reviewed', False),
        }
        print(f"🔍 Service {svc.id}: already_reviewed={svc_dict['already_reviewed']}, request_id={svc.request_id}")
        result.append(svc_dict)
    return result

@router.get("/category/{category_id}", response_model=List[schemas.Service])
def services_by_category(category_id: str, db: Session = Depends(get_db)):
    return service.get_services_by_category(db, category_id)

@router.get("/{service_id}", response_model=schemas.Service)
def read_service(service_id: str, db: Session = Depends(get_db)):
    db_service = service.get_service_by_id(db, service_id=service_id)
    if db_service is None:
        raise HTTPException(status_code=404, detail="El servicio no existe")
    return db_service

@router.put("/{service_id}", response_model=schemas.Service)
def update_service(
    service_id: str, service_data: schemas.ServiceUpdate, db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user),
):
    return service.update_service(db, service_id, service_data, current_user.id, current_user.role)

@router.put("/{service_id}/cancel")
def cancel_service(service_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    return service.cancel_service(db, service_id, current_user.id, current_user.role)

@router.delete("/{service_id}", status_code=status.HTTP_200_OK)
def delete_service(service_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(check_role([Role.ADMIN]))):
    return service.delete_service(db, service_id)

@router.patch("/{service_id}/active", response_model=schemas.Service)
def toggle_service_visibility(
    service_id: str, payload: schemas.ServiceActiveUpdate, db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    db_service = service.get_service_by_id(db, service_id)
    if not db_service: raise HTTPException(status_code=404, detail="Servicio no encontrado")
    db_service.is_active = payload.is_active
    db.commit()
    db.refresh(db_service)
    return db_service

    