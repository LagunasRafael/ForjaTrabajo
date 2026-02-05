from datetime import datetime  # <--- 1. NUEVA IMPORTACIÓN IMPORTANTE
from sqlalchemy.orm import Session
from app.payments import models, schemas

def create_payment(db: Session, payment: schemas.PaymentCreate, payer_id: int):
    # 2. Generamos la fecha aquí mismo en Python
    fecha_ahora = datetime.now()

    # 3. Se la pasamos al modelo directamente
    db_payment = models.Payment(
        amount=payment.amount,
        service_id=payment.service_id,
        payer_id=payer_id,
        payee_id=payment.payee_id,
        payment_method=payment.payment_method,
        created_at=fecha_ahora  # <--- ¡ESTO SOLUCIONA EL PROBLEMA!
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
    
    # Actualizamos el estado y simulamos el ID de Stripe
    db_payment.status = models.PaymentStatus.COMPLETED
    db_payment.provider_payment_id = f"txn_stripe_fake_{payment_id}_xyz"
    
    db.commit()
    db.refresh(db_payment)
    
    return db_payment