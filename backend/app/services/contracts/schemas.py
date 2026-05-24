from pydantic import BaseModel
from typing import Optional
from decimal import Decimal
from datetime import datetime

from app.services.models import JobStatus

class Job(BaseModel):
    id: str
    request_id: str
    provider_id: str
    client_id: str
    status: JobStatus
    final_price: Optional[Decimal] = None
    started_at: Optional[datetime] = None
    work_started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class WorkEvidenceResponse(BaseModel):
    id: str
    service_id: str
    worker_id: str
    image_url: str
    description: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
