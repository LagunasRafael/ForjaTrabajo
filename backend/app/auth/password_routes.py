from fastapi import APIRouter, Depends, HTTPException, Request, BackgroundTasks
from sqlalchemy.orm import Session
from app.auth import schemas, service
from app.db.database import get_db
from app.auth.security import hash_password
from app.utils.email import generate_verification_code, send_password_reset_email
from app.core.rate_limit import limiter
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/forgot-password")
@limiter.limit("3/minute")
def forgot_password(request: Request, data: schemas.ForgotPasswordRequest, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = service.get_user_by_email(db, email=data.email)
    
    if not user:
        return {"status": "success", "message": "Si el correo está registrado, recibirás un código de recuperación."}
    
    code = generate_verification_code()
    user.verification_code = code
    db.commit()
    
    background_tasks.add_task(send_password_reset_email, user.email, code)
    
    return {"status": "success", "message": "Si el correo está registrado, recibirás un código de recuperación."}


@router.post("/verify-reset-code")
@limiter.limit("5/minute")
def verify_reset_code(request: Request, data: schemas.VerifyCodeRequest, db: Session = Depends(get_db)):
    user = service.get_user_by_email(db, email=data.email)
    
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    if user.verification_code != data.code:
        raise HTTPException(status_code=400, detail="Código incorrecto")
    
    return {"status": "success", "message": "Código verificado correctamente"}


@router.post("/reset-password")
@limiter.limit("5/minute")
def reset_password(request: Request, data: schemas.ResetPasswordRequest, db: Session = Depends(get_db)):
    user = service.get_user_by_email(db, email=data.email)
    
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    if user.verification_code != data.code:
        raise HTTPException(status_code=400, detail="Código de recuperación incorrecto")
    
    user.hashed_password = hash_password(data.new_password)
    user.verification_code = None
    db.commit()
    
    return {"status": "success", "message": "Contraseña actualizada exitosamente"}
