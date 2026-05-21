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
    service_title: Optional[str] = None
    service_description: Optional[str] = None
    service_category: Optional[str] = None

    class Config:
        from_attributes = True

# --- Stripe Destination Charge ---

class CreateIntentRequest(BaseModel):
    amount_mxn: float
    worker_id: str

class CreateIntentResponse(BaseModel):
    client_secret: str
    payment_intent_id: str


class ConfirmPaymentRequest(BaseModel):
    payment_intent_id: str
    worker_id: str
    amount_mxn: float
    job_id: str

class ConfirmEscrowRequest(BaseModel):
    payment_intent_id: str


# --- Worker Stripe Connect Schemas ---

class StripeSetupRequest(BaseModel):
    user_id: str

class StripeSetupResponse(BaseModel):
    url: str

class StripeStatusResponse(BaseModel):
    has_stripe_account: bool = False
    onboarding_completed: bool = False
    charges_enabled: bool = False
    payouts_enabled: bool = False