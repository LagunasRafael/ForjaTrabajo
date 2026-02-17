from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from . import models, schemas

def create_payment(db: Session, payment: schemas.PaymentCreate):
    # 1. Buscamos el contrato
    db_contract = db.query(models.Contract).filter(models.Contract.id == payment.contract_id).first()

    if not db_contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"El contrato {payment.contract_id} no existe. No se puede procesar el pago."
        )

    # 2. Validación de seguridad que hicimos antes
    if db_contract.status in ["in_progress", "cancelled"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Error: Este contrato ya fue pagado o está cancelado."
        )
    precio_real = db_contract.job.final_price

    db_payment = models.Payment(
        contract_id=payment.contract_id,
        amount=precio_real, # El sistema cobra lo justo automáticamente
        payment_method=payment.payment_method,
        status=models.PaymentStatus.COMPLETED
    )

    # 5. Actualizamos el estado del contrato
    db_contract.status = "in_progress"

    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)
    
    return db_payment

def get_payment(db: Session, payment_id: str):
    return db.query(models.Payment).filter(models.Payment.id == payment_id).first()