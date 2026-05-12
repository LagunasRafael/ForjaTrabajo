from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.auth.security import get_current_user
from app.auth import models as auth_models
from . import schemas, models
import app.payments.services as services

router = APIRouter()


# --- CONTRATOS ---

@router.post("/contracts", response_model=schemas.ContractResponse, status_code=201)
def create_contract(contract: schemas.ContractCreate, db: Session = Depends(get_db)):
    import uuid
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


@router.get("/contracts", response_model=List[schemas.ContractResponse])
def get_contracts(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Obtiene los contratos filtrados según el rol del usuario."""
    return services.get_contracts_by_role(db=db, current_user=current_user)


# --- PAGOS CLÁSICOS ---

@router.post("/", response_model=schemas.PaymentResponse, status_code=201)
def create_payment(payment: schemas.PaymentCreate, db: Session = Depends(get_db)):
    """Pago directo (sin Stripe escrow). Mantiene compatibilidad."""
    return services.create_payment(db=db, payment=payment)


@router.get("/", response_model=List[schemas.PaymentResponse])
def get_payments(
    db: Session = Depends(get_db), 
    current_user: auth_models.User = Depends(get_current_user)
):
    """Historial de pagos filtrado por rol."""
    return services.get_payments_by_role(db=db, current_user=current_user)


# --- STRIPE ESCROW ---

@router.post("/create-intent", response_model=schemas.CreateIntentResponse)
def create_payment_intent(
    data: schemas.CreateIntentRequest,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """
    Crea un PaymentIntent en Stripe con capture_method='manual'.
    Retiene los fondos sin cobrar definitivamente.
    
    Retorna el client_secret para que Flutter confirme con el SDK de Stripe.
    """
    return services.create_payment_intent(
        db=db,
        job_id=data.job_id,
        amount=data.amount
    )


@router.post("/confirm-escrow", response_model=schemas.PaymentResponse)
def confirm_escrow(
    data: schemas.ConfirmEscrowRequest,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """
    Endpoint llamado desde Flutter DESPUÉS de que el SDK de Stripe
    confirma que el pago fue autorizado exitosamente.
    Actualiza el estado del pago a 'held_in_escrow'.
    """
    return services.confirm_escrow(db=db, payment_intent_id=data.payment_intent_id)