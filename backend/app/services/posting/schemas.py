from pydantic import BaseModel
from typing import Optional, List
from decimal import Decimal
from datetime import datetime

# 🚀 Importamos el Enum compartido
from app.modules.services.schemas import JobStatus

class ServiceBase(BaseModel):
    title: str
    summary: Optional[str] = None
    description: str
    base_price: Optional[Decimal] = None
    category_id: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    exact_address: Optional[str] = None
    image_urls: Optional[List[str]] = []

class ServiceCreate(ServiceBase):
    pass

class ServiceUpdate(BaseModel):
    title: Optional[str] = None
    summary: Optional[str] = None
    description: Optional[str] = None
    base_price: Optional[Decimal] = None
    category_id: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    exact_address: Optional[str] = None
    image_urls: Optional[List[str]] = None

class Service(ServiceBase):
    id: str
    client_id: str
    status: JobStatus
    is_active: bool
    created_at: datetime

    author_name: Optional[str] = "Usuario Cliente"
    author_image_url: Optional[str] = None

    request_id: Optional[str] = None
    worker_name: Optional[str] = None
    worker_image_url: Optional[str] = None

    already_reviewed: bool = False

    class Config:
        from_attributes = True

class ServiceActiveUpdate(BaseModel):
    is_active: bool