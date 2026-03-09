from pydantic import BaseModel
from typing import Optional
from decimal import Decimal
from datetime import datetime

# 🚀 Importamos el Enum compartido
from app.modules.services.schemas import JobStatus

class Job(BaseModel):
    id: str
    request_id: str
    provider_id: str
    client_id: str
    status: JobStatus
    final_price: Optional[Decimal] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True