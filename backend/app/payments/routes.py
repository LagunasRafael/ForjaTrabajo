from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from . import schemas, services

router = APIRouter()

@router.post("/", response_model=schemas.PaymentResponse)
def create_payment(
    payment_data: schemas.PaymentCreate, 
    db: Session = Depends(get_db)
):
    # Simular el ID del usuario
    fake_user_id = 1 
    return services.create_payment(db=db, payment=payment_data, payer_id=fake_user_id)

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