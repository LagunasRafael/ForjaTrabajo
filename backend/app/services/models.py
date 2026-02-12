from sqlalchemy import (
    Column,
    String,
    Text,
    DateTime,
    ForeignKey,
    Enum,
    Boolean,
    Numeric
)
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid
import enum

from app.db.database import Base


# -----------------------------
# ENUMS
# -----------------------------

class JobStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


# -----------------------------
# CATEGORY (OFICIO)
# -----------------------------

class Category(Base):
    __tablename__ = "categories"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)

    services = relationship("Service", back_populates="category")


# -----------------------------
# SERVICE (PUBLICADO POR PRESTADOR)
# -----------------------------

class Service(Base):
    __tablename__ = "services"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String(150), nullable=False)
    description = Column(Text, nullable=False)
    base_price = Column(Numeric(10, 2), nullable=True)

    category_id = Column(String(36), ForeignKey("categories.id"), nullable=False)
    
    # CORRECCIÓN: Agregamos el ForeignKey apuntando a la tabla 'users'
    provider_id = Column(String(36), ForeignKey("users.id"), nullable=False) 

    is_active = Column(Boolean, default=True)
    # Nota: datetime.utcnow está deprecado en Python 3.12+, pero funciona.
    created_at = Column(DateTime, default=datetime.utcnow)

    category = relationship("Category", back_populates="services")
    requests = relationship("ServiceRequest", back_populates="service")
    
    # OPCIONAL: Agrega esto si en tu modelo User tienes back_populates="services"
    owner = relationship("User", back_populates="services")


# -----------------------------
# SERVICE REQUEST (SOLICITUD)
# -----------------------------

class ServiceRequest(Base):
    __tablename__ = "service_requests"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))

    service_id = Column(String(36), ForeignKey("services.id"), nullable=False)
    
    # CORRECCIÓN: Agregamos ForeignKey("users.id")
    client_id = Column(String(36), ForeignKey("users.id"), nullable=False) 

    description = Column(Text, nullable=False)
    status = Column(Enum(JobStatus), default=JobStatus.PENDING)

    created_at = Column(DateTime, default=datetime.utcnow)

    service = relationship("Service", back_populates="requests")
    job = relationship("Job", back_populates="request", uselist=False)


# -----------------------------
# JOB (TRABAJO ACEPTADO)
# -----------------------------

class Job(Base):
    __tablename__ = "jobs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))

    request_id = Column(
        String(36),
        ForeignKey("service_requests.id"),
        nullable=False,
        unique=True
    )

    # CORRECCIÓN: Ambos necesitan ForeignKey("users.id")
    provider_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    client_id = Column(String(36), ForeignKey("users.id"), nullable=False)

    status = Column(Enum(JobStatus), default=JobStatus.ACCEPTED)
    final_price = Column(Numeric(10, 2), nullable=True)

    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)

    request = relationship("ServiceRequest", back_populates="job")