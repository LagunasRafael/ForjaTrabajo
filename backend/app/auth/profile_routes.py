from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
from app.auth import schemas, models
from app.db.database import get_db
from app.auth.security import get_current_user
from app.utils.s3 import upload_file_to_s3, delete_old_file_from_s3
from app.services.models import Category as DBCategory
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/users", response_model=List[schemas.UserResponse])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = db.query(models.User).offset(skip).limit(limit).all()
    return users


@router.put("/users/{user_id}", response_model=schemas.UserResponse)
def update_user(
    user_id: str, 
    user_data: schemas.UserUpdate,
    db: Session = Depends(get_db)
):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    
    if not db_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    
    if user_data.full_name is not None:
        db_user.full_name = user_data.full_name
    if user_data.phone is not None:
        db_user.phone = user_data.phone
    if user_data.is_active is not None:
        db_user.is_active = user_data.is_active
        if user_data.is_active:
            db_user.is_banned = False
    if user_data.is_banned is not None:
        db_user.is_banned = user_data.is_banned
        if user_data.is_banned:
            db_user.is_active = False
    if user_data.bio is not None:
        db_user.bio = user_data.bio
    if user_data.category_ids is not None:
        if len(user_data.category_ids) > 5:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Solo puedes seleccionar hasta 5 categorías"
            )
        categories_to_add = db.query(DBCategory).filter(DBCategory.id.in_(user_data.category_ids)).all()
        db_user.categories = categories_to_add

    db.commit()
    db.refresh(db_user)
    
    return db_user


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: str, 
    db: Session = Depends(get_db)
):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    
    if not db_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    
    db.delete(db_user)
    db.commit()
    
    return None


@router.post("/{user_id}/profile-picture", response_model=schemas.UserResponse)
async def upload_profile_picture(
    user_id: str, 
    file: UploadFile = File(...), 
    db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    if user.profile_picture_url:
        delete_old_file_from_s3(user.profile_picture_url)

    try:
        file_url = await upload_file_to_s3(file)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al subir a S3: {str(e)}")

    user.profile_picture_url = file_url
    db.commit()
    db.refresh(user)

    return user


@router.put("/update-location/{user_id}")
def update_location(
    user_id: str, 
    location_data: schemas.LocationUpdate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para actualizar la ubicación de otro usuario"
        )
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    user.latitude = location_data.latitude
    user.longitude = location_data.longitude
    user.city = location_data.city
    
    db.commit()
    return {"status": "success", "city": user.city}
