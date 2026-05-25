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
    WAITING_CONFIRMATION = "waiting_confirmation"
    completed = "completed"
    cancelled = "cancelled"
    disputed = "disputed"

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
        from_attributes = True

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
    worker_id: Optional[str] = None

    already_reviewed: bool = False
    has_paid: bool = False
    payment_due_at: Optional[datetime] = None
    auto_release_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# -----------------------------
# SERVICE REQUESTS 
# -----------------------------

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
    
    # 👇 1. AGREGA ESTA LÍNEA
    author_image_url: Optional[str] = None 

    class Config:
        from_attributes = True

class UpdatePostulationRequest(BaseModel):
    description: str
    proposed_price: float

    class Config:
        from_attributes = True
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
    work_started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class ServiceActiveUpdate(BaseModel):
    is_active: bool

# -----------------------------
# REVIEWS AND PROFILES
# -----------------------------

class ReviewCreate(BaseModel):
    rating: int # 1 to 5
    comment: Optional[str] = None

class ReviewResponse(BaseModel):
    id: str
    job_id: str
    reviewer_id: str
    reviewee_id: str
    rating: int
    comment: Optional[str] = None
    created_at: datetime
    
    reviewer_name: Optional[str] = None
    reviewer_image_url: Optional[str] = None

    class Config:
        from_attributes = True

class JobSummarySchema(BaseModel):
    id: str
    title: str
    status: str
    base_price: float = 0.0
    final_price: Optional[float] = None
    completed_at: Optional[datetime] = None
    other_party_name: Optional[str] = None
    other_party_image_url: Optional[str] = None
    role_in_job: str = "client"

class UserProfileResponse(BaseModel):
    id: str
    full_name: str
    profile_picture_url: Optional[str] = None
    role: str
    created_at: datetime
    average_rating: float = 0.0
    total_reviews: int = 0
    is_identity_verified: bool = False
    completed_jobs: List[JobSummarySchema] = []
    bio: Optional[str] = None
    categories: Optional[List[Category]] = []