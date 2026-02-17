from fastapi import APIRouter, Depends, HTTPException, status,UploadFile,File
from sqlalchemy.orm import Session
from typing import List
# Corregimos el typo de 'segurity' a 'security' y limpiamos imports
from app.auth import schemas
from app.auth import service
from app.auth import models
from app.db.database import get_db
from app.auth.security import create_access_token, get_current_user
from app.core.roles import Role # Para forzar el rol en el registro
from app.utils.s3 import upload_file_to_s3, delete_old_file_from_s3

router = APIRouter(tags=["Authentication"])

@router.post("/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # SEGURIDAD FASE 2: Forzamos que el registro público sea siempre 'user'
    # Así, aunque envíen "role": "admin" en el JSON, se ignora.
    user_data = user.model_dump()
     
    
    # Verificamos si el usuario ya existe para dar un error claro
    db_user = service.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(
            status_code=400, 
            detail="El correo ya está registrado"
        )
    
    return service.create_user(db, user_data)

@router.post("/login", response_model=schemas.Token)
def login(data: schemas.UserLogin, db: Session = Depends(get_db)):
    user = service.authenticate_user(db, data.email, data.password)

    if not user:
        # Usamos la constante de FastAPI para mayor claridad
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Credenciales inválidas",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # El 'sub' (subject) del JWT debe ser el identificador único
    token = create_access_token({"sub": str(user.id)})

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": user
    }

@router.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user

@router.get("/users", response_model=List[schemas.UserResponse])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = db.query(models.User).offset(skip).limit(limit).all()
    return users

@router.put("/users/{user_id}", response_model=schemas.UserResponse)
def update_user(
    user_id: str, 
    user_data: schemas.UserUpdate, # O UserUpdate si creaste un esquema específico
    db: Session = Depends(get_db)
):
    # 1. Buscamos al usuario en la base de datos
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    
    if not db_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    
    # 2. Actualizamos los campos
    db_user.full_name = user_data.full_name
    db_user.role = user_data.role
    
    # Si estás manejando is_active, descomenta esta línea:
    # db_user.is_active = user_data.is_active 

    # 3. Guardamos los cambios
    db.commit()
    db.refresh(db_user)
    
    return db_user

# ----------------------------------------------------
# 🔴 ELIMINAR USUARIO (DELETE)
# ----------------------------------------------------
@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: str, 
    db: Session = Depends(get_db)
):
    # 1. Buscamos al usuario
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    
    if not db_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    
    # 2. Lo eliminamos
    db.delete(db_user)
    db.commit()
    
    return None

@router.post("/{user_id}/profile-picture", response_model=schemas.UserResponse)
async def upload_profile_picture(
    user_id: str, 
    file: UploadFile = File(...), 
    db: Session = Depends(get_db)
):
    # 1. Verificamos que el usuario exista
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    if user.profile_picture_url:
        delete_old_file_from_s3(user.profile_picture_url)

    # 2. Comprimimos y subimos a AWS S3
    try:
        file_url = await upload_file_to_s3(file) 
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al subir a S3: {str(e)}")

    # 3. Guardamos la URL en la base de datos
    user.profile_picture_url = file_url
    db.commit()
    db.refresh(user)

    # 4. Devolvemos el usuario actualizado
    return user