from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class ContractCreate(BaseModel):
    service_id: str
    client_id: str

class ContractResponse(BaseModel):
    id: str
    service_id: str
    client_id: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class PaymentCreate(BaseModel):
    contract_id: str  # Ya no pedimos payer_id
    amount: float
    payment_method: Optional[str] = "card"

class PaymentResponse(BaseModel):
    id: str
    contract_id: str
    amount: float
    status: str
    payment_method: str
    created_at: datetime

    class Config:
        from_attributes = True