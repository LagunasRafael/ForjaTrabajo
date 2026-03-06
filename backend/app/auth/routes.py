from fastapi import APIRouter, Depends, HTTPException, status,UploadFile,File
from sqlalchemy.orm import Session
from typing import List
# Corregimos el typo de 'segurity' a 'security' y limpiamos imports
from app.auth import schemas
from app.auth import service
from app.auth import models
from app.db.database import get_db
from app.auth.security import create_access_token, create_refresh_token, get_current_user, SECRET_KEY, ALGORITHM
from app.core.roles import Role # Para forzar el rol en el registro
from app.utils.s3 import upload_file_to_s3, delete_old_file_from_s3
from app.utils.email import generate_verification_code, send_verification_email
from jose import jwt, JWTError
from fastapi import APIRouter, Request, BackgroundTasks

from app.core.rate_limit import limiter

router = APIRouter()

@router.post("/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("3/minute")
def register(request: Request, user: schemas.UserCreate, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
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
    
    # 2. Verificar que el teléfono tampoco exista
    if user.phone:
        db_phone = service.get_user_by_phone(db, phone=user.phone)
        if db_phone:
            raise HTTPException(
                status_code=400, 
                detail="El número de teléfono ya está en uso"
            )
            
    # 3. Generar código de 6 dígitos
    verification_code = generate_verification_code()
    
    # 4. Crear el usuario en la BD (is_email_verified=False inicial)
    new_user = service.create_user(db, user_data, verification_code=verification_code)
    
    # 5. Enviar el correo usando Resend en segundo plano
    background_tasks.add_task(send_verification_email, new_user.email, verification_code)
    
    return new_user

@router.post("/verify-code")
def verify_email_code(data: schemas.VerifyCodeRequest, db: Session = Depends(get_db)):
    user = service.get_user_by_email(db, email=data.email)
    
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
    if user.is_email_verified:
        return {"status": "success", "message": "El correo ya estaba verificado"}
        
    if user.verification_code != data.code:
        raise HTTPException(status_code=400, detail="Código de verificación incorrecto")
        
    # Verificar, limpiar el código y guardar
    user.is_email_verified = True
    user.verification_code = None
    db.commit()
    
    return {"status": "success", "message": "Correo verificado exitosamente"}

@router.post("/resend-code")
@limiter.limit("3/minute")
def resend_verification_code(request: Request, data: schemas.ResendCodeRequest, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = service.get_user_by_email(db, email=data.email)
    
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
    if user.is_email_verified:
        raise HTTPException(status_code=400, detail="El correo ya está verificado")
        
    # Generar un nuevo código
    new_code = generate_verification_code()
    user.verification_code = new_code
    db.commit()
    
    # Reenviar el correo por Resend
    background_tasks.add_task(send_verification_email, user.email, new_code)
    
    return {"status": "success", "message": "Nuevo código enviado"}

@router.post("/login", response_model=schemas.Token)
@limiter.limit("5/minute")
def login(request: Request, data: schemas.UserLogin, db: Session = Depends(get_db)):
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
    refresh_token = create_refresh_token({"sub": str(user.id)})

    return {
        "access_token": token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": user
    }

@router.post("/refresh", response_model=schemas.Token)
def refresh_token(data: schemas.TokenRefresh, db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token de refresco inválido o expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(data.refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        
        if user_id is None or token_type != "refresh":
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None or not user.is_active:
        raise credentials_exception

    # Generamos nuevos tokens
    new_access_token = create_access_token({"sub": str(user.id)})
    new_refresh_token = create_refresh_token({"sub": str(user.id)})

    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
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
    if user_data.full_name is not None:
        db_user.full_name = user_data.full_name
    if user_data.role is not None:
        db_user.role = user_data.role
    if user_data.phone is not None:
        db_user.phone = user_data.phone
    
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

@router.put("/update-location/{user_id}")
def update_location(
    user_id: str, 
    location_data: schemas.LocationUpdate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    # 🔍 VALIDACIÓN DE PROPIEDAD: 
    # ¿El ID del token es el mismo que el ID que queremos editar?
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

@router.put("/fcm-token")
def update_fcm_token(
    data: schemas.FcmTokenUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    current_user.fcm_token = data.fcm_token
    db.commit()
    return {"status": "success", "message": "FCM token actualizado"}

# ============================================================
# 🛡️ ENDPOINT PROTEGIDO: Solo un admin puede crear usuarios
# ============================================================
@router.post("/admin/create-user", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def admin_create_user(
    user_data: schemas.AdminCreateUser,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    # 1. Verificar que el que llama sea admin
    if current_user.role.value != "admin" and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los administradores pueden crear usuarios desde el panel."
        )

    # 2. Verificar que el email no exista
    existing = service.get_user_by_email(db, email=user_data.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El correo '{user_data.email}' ya está registrado."
        )

    # 3. Verificar que el teléfono no exista (si se proporcionó)
    if user_data.phone:
        existing_phone = service.get_user_by_phone(db, phone=user_data.phone)
        if existing_phone:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El número de teléfono ya está en uso."
            )

    # 4. Hashear la contraseña de forma segura
    from app.auth.security import hash_password
    hashed_pw = hash_password(user_data.password)

    # 5. Crear el usuario (verificado automáticamente — no necesita código de email)
    import uuid
    new_user = models.User(
        id=str(uuid.uuid4()),
        full_name=user_data.full_name,
        email=user_data.email,
        phone=user_data.phone,
        hashed_password=hashed_pw,
        role=user_data.role,
        is_email_verified=True,
        is_active=True,
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user