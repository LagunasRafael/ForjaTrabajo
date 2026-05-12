from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class ContractCreate(BaseModel):
    job_id: str
    client_id: str

class ContractResponse(BaseModel):
    id: str
    job_id: str
    client_id: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class ContractList(BaseModel):
    contracts: list[ContractResponse]

class PaymentCreate(BaseModel):
    contract_id: str
    payment_method: Optional[str] = "card"
    amount: float

class PaymentResponse(BaseModel):
    id: str
    contract_id: str
    amount: float
    amount_cents: int = 0
    status: str
    payment_method: str
    stripe_payment_intent_id: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

# --- Stripe Escrow Schemas ---

class CreateIntentRequest(BaseModel):
    job_id: str
    amount: float  # Monto en pesos/dólares (ej. 250.00)

class CreateIntentResponse(BaseModel):
    client_secret: str
    payment_intent_id: str
    amount_cents: int
    payment_id: str  # ID del Payment en nuestra BD

class ConfirmEscrowRequest(BaseModel):
    payment_intent_id: str