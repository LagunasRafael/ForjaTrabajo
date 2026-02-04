from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends, HTTPException, status
from app.payments import models, schemas 
from app.services.models import Service
from app.db.database import get_db
from app.payments import services


router = APIRouter()

@router.post("/", response_model=schemas.PaymentResponse)
def create_payment(
    payment_data: schemas.PaymentCreate, 
    db: Session = Depends(get_db)
):
    return services.create_payment(db=db, payment=payment_data)

@router.get("/{payment_id}", response_model=schemas.PaymentResponse)
def read_payment(payment_id: int, db: Session = Depends(get_db)): 

    payment = services.get_payment(db, payment_id)
    if payment is None:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    return payment

@router.patch("/{payment_id}/complete", response_model=schemas.PaymentResponse)
def update_payment_status(payment_id: int, db: Session = Depends(get_db)):
    payment = services.complete_payment(db, payment_id=payment_id)
    
    if payment is None:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
        
    return payment