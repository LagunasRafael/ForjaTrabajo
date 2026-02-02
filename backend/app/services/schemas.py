from pydantic import BaseModel
from typing import Optional
from decimal import Decimal
from datetime import datetime
from enum import Enum


# -----------------------------
# ENUMS
# -----------------------------

class JobStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    in_progress = "in_progress"
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
    id: str  # antes era UUID
    is_active: bool

    class Config:
        orm_mode = True


# -----------------------------
# SERVICES
# -----------------------------

class ServiceBase(BaseModel):
    title: str
    description: str
    base_price: Optional[Decimal] = None
    category_id: str  # antes era UUID


class ServiceCreate(ServiceBase):
    pass


class Service(ServiceBase):
    id: str  # antes UUID
    provider_id: str  # antes UUID
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True


# -----------------------------
# SERVICE REQUESTS
# -----------------------------

class ServiceRequestCreate(BaseModel):
    service_id: str  # antes UUID
    description: str


class ServiceRequest(BaseModel):
    id: str  # antes UUID
    service_id: str
    client_id: str  # antes UUID
    status: JobStatus
    created_at: datetime

    class Config:
        orm_mode = True


# -----------------------------
# JOBS
# -----------------------------

class Job(BaseModel):
    id: str  # antes UUID
    request_id: str
    provider_id: str
    client_id: str
    status: JobStatus
    final_price: Optional[Decimal]

    class Config:
        orm_mode = True
