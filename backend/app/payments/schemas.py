from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from .models import PaymentStatus

# Creacion de un pago
class PaymentCreate(BaseModel):
    amount: float
    service_id: int
    payee_id: int
    payment_method: str = "card"

# Respuesta de un pago
class PaymentResponse(BaseModel):
    id: int
    amount: float
    status: PaymentStatus
    created_at: datetime
    service_id: int

    class Config:
        from_attributes = True