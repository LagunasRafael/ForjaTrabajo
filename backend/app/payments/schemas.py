from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.payments import models 

# Clase base
class PaymentBase(BaseModel):
    amount: float
    payer_id: str 
    service_id: str
    payment_method: str = "card"

# Para recibir datos (Crear)
class PaymentCreate(PaymentBase):
    pass

# Para devolver datos (Leer)
class PaymentResponse(PaymentBase):
   
    id: str  
    status: str
    provider_payment_id: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
class UserResponse(BaseModel):  
    
    id: str 
    email: str
    full_name: str
    role: str
    is_active: bool
   
    class Config:
        from_attributes = True