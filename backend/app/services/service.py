from sqlalchemy.orm import Session
from app.services import models, schemas
from uuid import UUID
from sqlalchemy.orm import Session
from app.services.models import Category



from fastapi import HTTPException

# -----------------------------
# CATEGORIES
# -----------------------------

def create_category(db: Session, category: schemas.CategoryCreate):
    # 1. Buscamos si ya existe una categoría con ese nombre (activa o inactiva)
    # Nota: Es recomendable usar .lower() si quieres evitar "Carpinteria" vs "carpinteria"
    existing_category = db.query(models.Category).filter(
        models.Category.name == category.name
    ).first()

    if existing_category:
        if existing_category.is_active:
            # Si ya está activa, lanzamos el error de que ya existe
            raise HTTPException(status_code=400, detail="La categoría ya existe y está activa.")
        
        # 🚀 RE-ACTIVACIÓN: Si existe pero estaba oculta (is_active=False)
        existing_category.is_active = True
        existing_category.description = category.description
        db.commit()
        db.refresh(existing_category)
        return existing_category

    # 2. Si realmente no existe en la base de datos, la creamos normal
    db_category = models.Category(**category.dict())
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category


def get_categories(
    db: Session,
    skip: int = 0,
    limit: int = 100
):
    return (
        db.query(models.Category)
        .filter(models.Category.is_active == True)  # 🔑 ESTA LÍNEA
        .offset(skip)
        .limit(limit)
        .all()
    )



def update_category(db: Session, category_id: UUID, data: schemas.CategoryUpdate):
    category = db.query(models.Category).filter(
        models.Category.id == str(category_id)  # ✅ AQUÍ
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


def delete_category(db: Session, category_id: str):
    category = db.query(models.Category).filter(
        models.Category.id == category_id
    ).first()

    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")

    category.is_active = False
    db.commit()
    return {"message": "Categoría desactivada"}



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


def get_services(db: Session, skip: int = 0, limit: int = 100):
    return (
        db.query(models.Service)
        .filter(models.Service.is_active == True)
        .offset(skip)
        .limit(limit)
        .all()
    )

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
