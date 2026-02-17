from sqlalchemy.orm import Session
from fastapi import HTTPException, status 
from app.payments import models, schemas
from app.services.models import Job, Service 

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
    # 1. Buscamos el pago (como ya lo hacías)
    db_payment = get_payment(db, payment_id)
    if not db_payment:
        return None
    
    db_payment.status = models.PaymentStatus.COMPLETED
    contract = db_payment.contract 
    
    #if contract and contract.job_id:
     #   # 4. Buscamos el Job de tu compañero
      #  job_found = db.query(Job).filter(Job.id == contract.job_id).first()
       # if job_found:
        #    job_found.status = "PAID" 

    db.commit()
    db.refresh(db_payment)
    return db_payment
