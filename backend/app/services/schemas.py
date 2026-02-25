from pydantic import BaseModel
from typing import Optional, List
from decimal import Decimal
from datetime import datetime
from enum import Enum

# -----------------------------
# ENUMS
# -----------------------------

class JobStatus(str, Enum):
    open = "open"
    matched = "matched"
    completed = "completed"
    cancelled = "cancelled"

# -----------------------------
# CATEGORIES 
# -----------------------------

class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None
    
class CategoryCreate(CategoryBase):
    pass

class Category(CategoryBase):
    id: str  # Manejado como String para el UUID
    is_active: bool

    class Config:
        orm_mode = True

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None         


# -----------------------------
# SERVICES
# -----------------------------

class ServiceBase(BaseModel):
    title: str
    summary: Optional[str] = None          # ✅ AÑADIDO
    description: str
    base_price: Optional[Decimal] = None
    category_id: str  # Recibe el UUID como string
    latitude: Optional[float] = None       # ✅ AÑADIDO
    longitude: Optional[float] = None      # ✅ AÑADIDO
    exact_address: Optional[str] = None    # ✅ AÑADIDO
    image_urls: Optional[List[str]] = []   # ✅ AÑADIDO


class ServiceCreate(ServiceBase):
    pass


class Service(ServiceBase):
    id: str
    client_id: str  # Ahora es el cliente quien es dueño de la publicación
    status: JobStatus
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True


# -----------------------------
# SERVICE REQUESTS 
# -----------------------------

class ServiceRequestCreate(BaseModel):
    service_id: str
    description: str  # Mensaje de propuesta del worker

class ServiceRequest(BaseModel):
    id: str
    service_id: str
    worker_id: str  # Quién se postula
    status: str
    created_at: datetime

    class Config:
        orm_mode = True


# -----------------------------
# JOBS
# -----------------------------

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
        orm_mode = True