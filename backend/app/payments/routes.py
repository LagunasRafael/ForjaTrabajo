from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
import uuid
from . import schemas, models, services  # Importamos tu service.py
from app.auth.security import get_current_user
from . import schemas, models
import app.payments.services as services
from app.auth import models as auth_models

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
    # Delegamos la creación y validación al service para mantener limpio el router
    return services.create_payment(db=db, payment=payment)

# --- RUTAS PROTEGIDAS Y FILTRADAS POR ROL ---

@router.get("/contracts", response_model=List[schemas.ContractResponse])
def get_contracts(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user) # Obtenemos el usuario del token
):
    """
    Obtiene los contratos filtrados según el rol del usuario.
    """
    # Usamos la función de filtrado que agregamos al service
    return services.get_contracts_by_role(db=db, current_user=current_user)


@router.get("/", response_model=List[schemas.PaymentResponse])
def get_payments(
    db: Session = Depends(get_db), 
    current_user: auth_models.User = Depends(get_current_user) # Cambiado aquí
):
    """
    Obtiene el historial de pagos filtrado por rol (Admin ve todo, Cliente solo lo suyo).
    """
    # Llamamos a la lógica de filtrado del service
    return services.get_payments_by_role(db=db, current_user=current_user)