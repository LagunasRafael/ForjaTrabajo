from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from . import models, schemas
from sqlalchemy.orm import Session, joinedload
from . import models
from . import schemas, models, services

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
def get_payments_by_role(db: Session, current_user):
    """
    Filtra el historial de pagos según el rol del usuario logueado.
    """
    # 1. El Administrador tiene acceso total
    if current_user.role == "admin":
        return db.query(models.Payment).all()

    # 2. El Cliente solo ve los pagos de SUS contratos
    # Hacemos un JOIN con Contract para validar el client_id
    if current_user.role == "client":
        return db.query(models.Payment)\
            .join(models.Contract)\
            .filter(models.Contract.client_id == current_user.id)\
            .all()

    # 3. El Worker (opcional) ve los pagos de trabajos que él realizó
    if current_user.role == "worker":
        # Aquí filtramos por la relación que tengan con el Job o Contract
        return db.query(models.Payment)\
            .join(models.Contract)\
            .filter(models.Contract.worker_id == current_user.id)\
            .all()

    return []

def get_contracts_by_role(db: Session, current_user):
    """
    Obtiene contratos con la información del Job cargada de golpe.
    """
    # Iniciamos la consulta base con joinedload para traer el Job asociado
    query = db.query(models.Contract).options(joinedload(models.Contract.job))

    if current_user.role == "admin":
        return query.all()
    
    # Si es cliente, filtramos por su ID antes de traer los resultados
    return query.filter(models.Contract.client_id == current_user.id).all()