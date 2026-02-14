from sqlalchemy.orm import Session
from fastapi import HTTPException, status 
from app.payments import models, schemas
from app.services.models import Service 

def create_payment(db: Session, payment: schemas.PaymentCreate):
    # Buscamos el servicio (el ID ya es string en el esquema, así que esto funciona)
    service_found = db.query(Service).filter(Service.id == payment.service_id).first()

    if not service_found:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail=f"El servicio con id {payment.service_id} no existe. No se puede procesar el pago."
        )

    db_payment = models.Payment(
        amount=payment.amount,
        service_id=payment.service_id, 
        payer_id=payment.payer_id,
        payee_id=service_found.provider_id, 
        status=models.PaymentStatus.PENDING 
    )

    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)
    return db_payment

def get_payment(db: Session, payment_id: str):
    return db.query(models.Payment).filter(models.Payment.id == payment_id).first()

def complete_payment(db: Session, payment_id: str):
    # Buscamos el pago usando la función de arriba (que ya acepta str)
    db_payment = get_payment(db, payment_id)
    
    if not db_payment:
        return None
    
    # Actualizamos el estado
    db_payment.status = models.PaymentStatus.COMPLETED
    # Simulamos el ID de transacción (funciona igual con strings)
    db_payment.provider_payment_id = f"txn_stripe_fake_{payment_id}_xyz"
    
    db.commit()
    db.refresh(db_payment)
    
    return db_payment