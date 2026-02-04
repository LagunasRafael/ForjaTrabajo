from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class PaymentBase(BaseModel):
    amount: float
    service_id: str 
    payer_id: int
    payment_method: str = "card"

class PaymentCreate(PaymentBase):
    pass

class Payment(PaymentBase):
    id: int 
    status: str
    provider_payment_id: Optional[str] = None
    payee_id: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True

PaymentResponse = Payment