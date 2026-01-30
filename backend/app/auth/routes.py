from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth import schemas, service
from app.db.database import get_db

router = APIRouter()

@router.post("/register", response_model=schemas.UserResponse)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    return service.create_user(db, user)
