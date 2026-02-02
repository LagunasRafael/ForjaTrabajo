from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from uuid import UUID

from app.db.database import get_db
from app.services import schemas, service

router = APIRouter()


# -----------------------------
# CATEGORIES
# -----------------------------

@router.post("/categories", response_model=schemas.Category)
def create_category(
    category: schemas.CategoryCreate,
    db: Session = Depends(get_db)
):
    return service.create_category(db, category)


@router.get("/categories", response_model=list[schemas.Category])
def list_categories(db: Session = Depends(get_db)):
    return service.get_categories(db)


# -----------------------------
# SERVICES
# -----------------------------

@router.post("/services", response_model=schemas.Service)
def create_service(
    service_data: schemas.ServiceCreate,
    db: Session = Depends(get_db)
):
    provider_id = UUID("00000000-0000-0000-0000-000000000000")  # temporal (auth)
    return service.create_service(db, service_data, provider_id)


@router.get("/services", response_model=list[schemas.Service])
def list_services(db: Session = Depends(get_db)):
    return service.get_services(db)


@router.get(
    "/services/category/{category_id}",
    response_model=list[schemas.Service]
)
def services_by_category(
    category_id: UUID,
    db: Session = Depends(get_db)
):
    return service.get_services_by_category(db, category_id)


# -----------------------------
# SERVICE REQUESTS
# -----------------------------

@router.post(
    "/service-requests",
    response_model=schemas.ServiceRequest
)
def create_service_request(
    request_data: schemas.ServiceRequestCreate,
    db: Session = Depends(get_db)
):
    client_id = UUID("00000000-0000-0000-0000-000000000001")  # temporal (auth)
    return service.create_service_request(db, request_data, client_id)
