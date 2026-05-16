from pydantic import BaseModel
from typing import Optional
from decimal import Decimal
from datetime import datetime

class ServiceRequestCreate(BaseModel):
    service_id: str
    description: str  
    proposed_price: Optional[Decimal] = None 

class ServiceRequest(BaseModel):
    id: str
    service_id: str
    worker_id: str  
    status: str
    created_at: datetime

    description: str
    proposed_price: Optional[Decimal] = None
    worker_name: Optional[str] = "Trabajador"  
    author_image_url: Optional[str] = None 

    class Config:
        from_attributes = True

class UpdatePostulationRequest(BaseModel):
    description: str
    proposed_price: float

    class Config:
        from_attributes = True