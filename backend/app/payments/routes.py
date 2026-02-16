from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
import uuid

from . import schemas, models

router = APIRouter(
    prefix="/payments",
    tags=["Contracts & Payments"]
)

@router.post("/contracts", response_model=schemas.ContractResponse, status_code=201)
def create_contract(contract: schemas.ContractCreate, db: Session = Depends(get_db)):
    new_contract = models.Contract(
        id=str(uuid.uuid4()),
        service_id=contract.service_id,
        client_id=contract.client_id,
        status=models.ContractStatus.PENDING
    )
    db.add(new_contract)
    db.commit()
    db.refresh(new_contract)
    return new_contract


@router.post("/", response_model=schemas.PaymentResponse, status_code=201)
def create_payment(payment: schemas.PaymentCreate, db: Session = Depends(get_db)):
    # Verificamos que el contrato exista antes de cobrar
    contract = db.query(models.Contract).filter(models.Contract.id == payment.contract_id).first()
    if not contract:
        raise HTTPException(status_code=404, detail="El contrato no existe")

    new_payment = models.Payment(
        id=str(uuid.uuid4()),
        contract_id=payment.contract_id,    
        amount=payment.amount,
        payment_method=payment.payment_method,
        status=models.PaymentStatus.COMPLETED
    )
    
    # Al pagar, el contrato pasa a estar En Progreso
    contract.status = models.ContractStatus.IN_PROGRESS

    db.add(new_payment)
    db.commit()
    db.refresh(new_payment)
    return new_payment
