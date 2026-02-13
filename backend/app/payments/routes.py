from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.payments import schemas, services

router = APIRouter(
    prefix="/payments",
    tags=["Payments"]
)

@router.post("/", response_model=schemas.PaymentResponse)
def create_payment(payment: schemas.PaymentCreate, db: Session = Depends(get_db)):
    return services.create_payment(db=db, payment=payment)


@router.get("/{payment_id}", response_model=schemas.PaymentResponse)
def read_payment(payment_id: str, db: Session = Depends(get_db)):
    db_payment = services.get_payment(db, payment_id=payment_id)
    if db_payment is None:
        raise HTTPException(status_code=404, detail="Payment not found")
    return db_payment

@router.patch("/{payment_id}/complete", response_model=schemas.PaymentResponse)
def complete_payment_route(payment_id: str, db: Session = Depends(get_db)):
    db_payment = services.complete_payment(db, payment_id=payment_id)
    if not db_payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    return db_payment