from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

# Corregimos el typo de 'segurity' a 'security' y limpiamos imports
from app.auth import schemas
from app.auth import service
from app.auth import models
from app.db.database import get_db
from app.auth.security import create_access_token, get_current_user
from app.core.roles import Role # Para forzar el rol en el registro

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # SEGURIDAD FASE 2: Forzamos que el registro público sea siempre 'user'
    # Así, aunque envíen "role": "admin" en el JSON, se ignora.
    user_data = user.model_dump()
    user_data["role"] = Role.CLIENT 
    
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
        "token_type": "bearer"
    }

@router.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user