from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
    
from uuid import UUID

from fastapi import status
from app.auth.security import check_role
from app.core.roles import Role

from app.auth.security import check_role
from app.core.roles import Role

from app.db.database import get_db
from app.services import schemas, service
from app.auth import models as auth_models

from app.auth.security import get_current_user 

router = APIRouter()

# -----------------------------
# CATEGORIES
# -----------------------------

@router.post(
    "/categories",
    response_model=schemas.Category,
    status_code=status.HTTP_201_CREATED
)
def create_category(
    category: schemas.CategoryCreate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(
        check_role([Role.ADMIN])
    )
):
    return service.create_category(db, category)



@router.get("/categories", response_model=List[schemas.Category])
def list_categories(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db)
):
    # Agregué paginación básica (skip/limit) por buenas prácticas
    return service.get_categories(db, skip=skip, limit=limit)


@router.put(
    "/categories/{category_id}",
    dependencies=[Depends(check_role([Role.ADMIN]))]
)
def update_category(
    category_id: UUID,
    category_data: schemas.CategoryUpdate,
    db: Session = Depends(get_db),
):
    return service.update_category(db, category_id, category_data)


@router.delete("/categories/{category_id}")
def delete_category(
    category_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(check_role([Role.ADMIN]))
):
    return service.delete_category(db, category_id)



# -----------------------------
# SERVICES
# -----------------------------

@router.post("/", response_model=schemas.Service)
def create_service(
    service_data: schemas.ServiceCreate,
    db: Session = Depends(get_db),
    current_user = Depends(
        check_role([Role.CLIENT, Role.ADMIN])
    )
):
    return service.create_service(
        db,
        service_data,
        provider_id=current_user.id
    )



@router.get("/", response_model=List[schemas.Service])
def list_services(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db)
):
    return service.get_services(db, skip=skip, limit=limit)


@router.get("/services/category/{category_id}", response_model=List[schemas.Service])
def services_by_category(
    category_id: str, # Cambié UUID por str para evitar errores de casting si la URL viene como texto
    db: Session = Depends(get_db)
):
    return service.get_services_by_category(db, category_id)


# -----------------------------
# SERVICE REQUESTS
# -----------------------------

@router.post("/service-requests", response_model=schemas.ServiceRequest)
def create_service_request(
    request_data: schemas.ServiceRequestCreate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    # Aquí el 'client_id' es quien está logueado haciendo la petición
    return service.create_service_request(db, request_data, client_id=current_user.id)