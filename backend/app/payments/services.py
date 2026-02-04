from datetime import datetime
from http.client import HTTPException
import stat  
from sqlalchemy.orm import Session
from app.payments import models, schemas
from app.services.models import Service

def create_payment(db: Session, payment: schemas.PaymentCreate):
    
    service_found = db.query(Service).filter(Service.id == payment.service_id).first()

    if not service_found:
        raise HTTPException(
            status_code=stat.HTTP_404_NOT_FOUND,
            detail=f"El servicio con id {payment.service_id} no existe. No se puede procesar el pago."
        )

    db_payment = models.Payment(
        amount=payment.amount,
        service_id=payment.service_id, 
        payer_id=payment.payer_id,
        payee_id=service_found.provider_id, 
        status="pending"
    )

    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)
    return db_payment

def get_payment(db: Session, payment_id: int):
    return db.query(models.Payment).filter(models.Payment.id == payment_id).first()

def complete_payment(db: Session, payment_id: int):
    # Buscamos el pago
    db_payment = get_payment(db, payment_id)
    
    if not db_payment:
        return None
    
    # Actualizamos el estado y simulamos el ID
    db_payment.status = models.PaymentStatus.COMPLETED
    db_payment.provider_payment_id = f"txn_stripe_fake_{payment_id}_xyz"
    
    db.commit()
    db.refresh(db_payment)
    
    return db_payment