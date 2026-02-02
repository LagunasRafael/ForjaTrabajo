from sqlalchemy.orm import Session
from app.services import models, schemas
from uuid import UUID

from fastapi import HTTPException

# -----------------------------
# CATEGORIES
# -----------------------------

def create_category(db: Session, category: schemas.CategoryCreate):
    db_category = models.Category(**category.dict())
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category


def get_categories(db: Session):
    return db.query(models.Category).filter(models.Category.is_active == True).all()


# -----------------------------
# SERVICES
# -----------------------------

def create_service(
    db: Session,
    service_data: schemas.ServiceCreate,
    provider_id: UUID
):
    db_service = models.Service(
        title=service_data.title,
        description=service_data.description,
        base_price=service_data.base_price,
        category_id=str(service_data.category_id),  # Convert UUID a string
        provider_id=str(provider_id)               # Convert UUID a string
    )

    db.add(db_service)
    db.commit()
    db.refresh(db_service)
    return db_service


def get_services(db: Session):
    return db.query(models.Service).filter(models.Service.is_active == True).all()


def get_services_by_category(db: Session, category_id: UUID):
    return (
        db.query(models.Service)
        .filter(
            models.Service.category_id == str(category_id),  # Convert UUID a string
            models.Service.is_active == True
        )
        .all()
    )


# -----------------------------
# SERVICE REQUESTS
# -----------------------------

def create_service_request(
    db: Session,
    request_data: schemas.ServiceRequestCreate,
    client_id: UUID
):
    db_request = models.ServiceRequest(
        service_id=str(request_data.service_id),  # Convert UUID a string
        description=request_data.description,
        client_id=str(client_id)                  # Convert UUID a string
    )
    db.add(db_request)
    db.commit()
    db.refresh(db_request)
    return db_request
