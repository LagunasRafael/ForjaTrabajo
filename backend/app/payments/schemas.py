from ast import List
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

class PaymentCreate(BaseModel):
    contract_id: str  # Ya no pedimos payer_id
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
class ContractList(BaseModel):
    contracts: list[ContractResponse]
class PaymentResponse(BaseModel):
    id: str
    contract_id: str
    amount: float
    status: str
    payment_method: str
    created_at: datetime

    class Config:
        from_attributes = True