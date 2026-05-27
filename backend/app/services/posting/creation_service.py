from sqlalchemy.orm import Session
from app.services import models, schemas
from uuid import UUID
from fastapi import HTTPException


def create_service(db: Session, service_data: schemas.ServiceCreate, client_id: UUID):
    category = db.query(models.Category).filter(models.Category.id == str(service_data.category_id)).first()
    if not category:
        raise HTTPException(status_code=400, detail="Error: El ID de categoria no existe o es invalido.")

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


def update_service_images(db: Session, service_id: str, image_urls: list[str]):
    db_service = db.query(models.Service).filter(models.Service.id == service_id).first()
    if db_service:
        db_service.image_urls = image_urls
        db.commit()
        db.refresh(db_service)
    return db_service
