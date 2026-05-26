from fastapi import APIRouter, Depends, HTTPException, status, Request, BackgroundTasks
from sqlalchemy.orm import Session, joinedload
from jose import jwt, JWTError
from app.auth import schemas, service, models
from app.db.database import get_db
from app.auth.security import create_access_token, create_refresh_token, get_current_user, SECRET_KEY, ALGORITHM
from app.utils.email import generate_verification_code, send_verification_email
from app.core.rate_limit import limiter
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("3/minute")
def register(request: Request, user: schemas.UserCreate, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user_data = user.model_dump()
    
    db_user = service.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(
            status_code=400, 
            detail="El correo ya está registrado"
        )
    
    if user.phone:
        db_phone = service.get_user_by_phone(db, phone=user.phone)
        if db_phone:
            raise HTTPException(
                status_code=400, 
                detail="El número de teléfono ya está en uso"
            )
            
    verification_code = generate_verification_code()

    new_user = service.create_user(db, user_data, verification_code=verification_code)
    
    background_tasks.add_task(send_verification_email, new_user.email, verification_code)
    
    from app.admin.ws_manager import recalculate_and_broadcast
    recalculate_and_broadcast(db)
    
    return new_user


@router.post("/verify-code")
def verify_email_code(data: schemas.VerifyCodeRequest, db: Session = Depends(get_db)):
    user = service.get_user_by_email(db, email=data.email)
    
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
    if user.is_email_verified:
        token = create_access_token({"sub": str(user.id)})
        refresh_token = create_refresh_token({"sub": str(user.id)})
        return {
            "status": "success",
            "message": "El correo ya estaba verificado",
            "access_token": token,
            "refresh_token": refresh_token,
            "user": schemas.UserResponse.model_validate(user).model_dump()
        }
        
    if user.verification_code != data.code:
        raise HTTPException(status_code=400, detail="Código de verificación incorrecto")
        
    user.is_email_verified = True
    user.verification_code = None
    db.commit()
    
    token = create_access_token({"sub": str(user.id)})
    refresh_token = create_refresh_token({"sub": str(user.id)})
    
    return {
        "status": "success",
        "message": "Correo verificado exitosamente",
        "access_token": token,
        "refresh_token": refresh_token,
        "user": schemas.UserResponse.model_validate(user).model_dump()
    }


@router.post("/resend-code")
@limiter.limit("3/minute")
def resend_verification_code(request: Request, data: schemas.ResendCodeRequest, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = service.get_user_by_email(db, email=data.email)
    
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
    if user.is_email_verified:
        raise HTTPException(status_code=400, detail="El correo ya está verificado")
        
    new_code = generate_verification_code()
    user.verification_code = new_code
    db.commit()
    
    background_tasks.add_task(send_verification_email, user.email, new_code)
    
    return {"status": "success", "message": "Nuevo código enviado"}


@router.post("/login", response_model=schemas.Token)
@limiter.limit("5/minute")
def login(request: Request, data: schemas.UserLogin, db: Session = Depends(get_db)):
    user = service.authenticate_user(db, data.identifier, data.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Correo electrónico, teléfono o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active or getattr(user, "is_banned", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tu cuenta ha sido desactivada o baneada por moderación.",
        )

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

    new_access_token = create_access_token({"sub": str(user.id)})
    new_refresh_token = create_refresh_token({"sub": str(user.id)})

    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer",
        "user": user
    }


@router.get("/me", response_model=schemas.UserResponse)
def get_me(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_with_cats = db.query(models.User)\
        .options(joinedload(models.User.categories))\
        .filter(models.User.id == current_user.id)\
        .first()
        
    return user_with_cats if user_with_cats else current_user
