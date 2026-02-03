from sqlalchemy.orm import Session
from app.auth import models, schemas
from app.auth.security import hash_password, verify_password 
from app.core.roles import Role

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def get_user_by_id(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.id == user_id).first()

def create_user(db: Session, user_data: dict):
    db_user = models.User(
        email=user_data["email"],
        hashed_password=hash_password(user_data["password"]),
        full_name=user_data.get("full_name"),
        role=user_data.get("role", Role.CLIENT)
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def authenticate_user(db: Session, email: str, password: str):
    user = get_user_by_email(db, email)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user