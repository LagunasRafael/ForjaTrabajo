from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from uuid import UUID
from fastapi import HTTPException

# 🚀 Ajusta esta importación si tus schemas están en otro lado
from app.services import models, schemas 

def create_category(db: Session, category: schemas.CategoryCreate):
    existing_category = db.query(models.Category).filter(
        models.Category.name == category.name
    ).first()

    if existing_category:
        if existing_category.is_active:
            raise HTTPException(status_code=400, detail="La categoría ya existe y está activa.")
        existing_category.is_active = True
        existing_category.description = category.description
        db.commit()
        db.refresh(existing_category)
        return existing_category

    db_category = models.Category(**category.dict())
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category

def get_categories(db: Session, skip: int = 0, limit: int = 100):
    return (
        db.query(models.Category)
        .filter(models.Category.is_active == True)
        .offset(skip)
        .limit(limit)
        .all()
    )

def update_category(db: Session, category_id: UUID, data: schemas.CategoryUpdate):
    category = db.query(models.Category).filter(
        models.Category.id == str(category_id)
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

def delete_category_hard(db: Session, category_id: str):
    category = db.query(models.Category).filter(
        models.Category.id == category_id
    ).first()
    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    db.delete(category)
    db.commit()
    return {"message": "Categoría eliminada correctamente"}

def get_top_categories(db: Session, limit: int = 5):
    return (
        db.query(models.Category)
        .outerjoin(
            models.Service,
            and_(
                models.Category.id == models.Service.category_id,
                models.Service.is_active == True
            )
        )
        .group_by(models.Category.id)
        .order_by(func.count(models.Service.id).desc())
        .limit(limit)
        .all()
    )