from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.db.database import get_db
from app.auth.security import check_role
from app.core.roles import Role
from app.auth import models as auth_models

# Importamos los schemas globales y el servicio local
from app.services import schemas
from app.services.categories import service

router = APIRouter()

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

@router.get("/top-categories", response_model=List[schemas.Category])
def get_top_categories_route(db: Session = Depends(get_db)):
    """Obtiene las 5 categorías con más servicios publicados."""
    return service.get_top_categories(db, limit=5)

@router.put("/categories/{category_id}", dependencies=[Depends(check_role([Role.ADMIN]))])
def update_category(category_id: UUID, category_data: schemas.CategoryUpdate, db: Session = Depends(get_db)):
    return service.update_category(db, category_id, category_data)

@router.delete("/categories/{category_id}")
def delete_category(category_id: str, db: Session = Depends(get_db), current_user = Depends(check_role([Role.ADMIN]))):
    return service.delete_category_hard(db, category_id) # Usamos delete_category_hard como lo definimos en service