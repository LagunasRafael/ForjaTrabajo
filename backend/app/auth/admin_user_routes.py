from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.auth import schemas, models, service
from app.auth.security import hash_password, get_current_user
from app.db.database import get_db
import uuid
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/admin/create-user", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def admin_create_user(
    user_data: schemas.AdminCreateUser,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role.value != "admin" and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los administradores pueden crear usuarios desde el panel."
        )

    existing = service.get_user_by_email(db, email=user_data.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El correo '{user_data.email}' ya está registrado."
        )

    if user_data.phone:
        existing_phone = service.get_user_by_phone(db, phone=user_data.phone)
        if existing_phone:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El número de teléfono ya está en uso."
            )

    hashed_pw = hash_password(user_data.password)

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
