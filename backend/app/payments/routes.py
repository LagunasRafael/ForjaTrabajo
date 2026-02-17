from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
import uuid
from app.services.models import Job 
from . import schemas, models

router = APIRouter()

@router.post("/contracts", response_model=schemas.ContractResponse, status_code=201)
def create_contract(contract: schemas.ContractCreate, db: Session = Depends(get_db)):
    new_contract = models.Contract(
        id=str(uuid.uuid4()),
        job_id=contract.job_id,
        client_id=contract.client_id,
        status=models.ContractStatus.PENDING
    )
    db.add(new_contract)
    db.commit()
    db.refresh(new_contract)
    return new_contract

@router.post("/", response_model=schemas.PaymentResponse, status_code=201)
def create_payment(payment: schemas.PaymentCreate, db: Session = Depends(get_db)):
    # 1. Buscamos el contrato
    db_contract = db.query(models.Contract).filter(models.Contract.id == payment.contract_id).first()
    
    # Bloqueamos si ya está pagado O si fue cancelado
    if db_contract.status in ["in_progress", "cancelled"]:
        raise HTTPException(
            status_code=400, 
            detail=f"No se puede procesar el pago. El contrato está {db_contract.status}."
        )
    
    if not db_contract:
        raise HTTPException(status_code=404, detail="Contrato no encontrado")
    if db_contract.status == "in_progress":
        raise HTTPException(
            status_code=400, 
            detail="Error: Este contrato ya fue pagado y está en progreso."
        )
    new_payment = models.Payment(
        id=str(uuid.uuid4()),
        contract_id=payment.contract_id,
        amount=payment.amount,
        payment_method=payment.payment_method,
        status=models.PaymentStatus.COMPLETED
    )
    
    # 3. Actualizamos el contrato y guardamos
    db_contract.status = "in_progress"
    db.add(new_payment)
    db.commit()
    db.refresh(new_payment)
    
    return new_payment

@router.get("/contracts", response_model=List[schemas.ContractResponse])
def get_contracts(db: Session = Depends(get_db)):
    contracts = db.query(models.Contract).all()
    return contracts

@router.get("/", response_model=List[schemas.PaymentResponse])
def get_payments(db: Session = Depends(get_db)):
    # Traemos todos los pagos de la base de datos
    payments = db.query(models.Payment).all()
    return payments


