from sqlalchemy import (
    Column,
    String,
    Text,
    DateTime,
    ForeignKey,
    Enum,
    Boolean,
    Numeric,
    Float, # ✅ AÑADIDO: Para las coordenadas
    JSON   # ✅ AÑADIDO: Para la lista de imágenes
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
    OPEN = "open"            # Cliente publica, esperando workers
    MATCHED = "matched"  
    WAITING_CONFIRMATION = "waiting_confirmation"  # Confirmación mutua (inicio de trabajo/chat)
    COMPLETED = "completed"  # Trabajo finalizado
    CANCELLED = "cancelled"  # Cancelación por alguna parte

# -----------------------------
# CATEGORY 
# -----------------------------

class Category(Base):
    __tablename__ = "categories"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)

    services = relationship("Service", back_populates="category")


# -----------------------------
# SERVICE (PUBLICA EL CLIENTE - OPCIÓN B)
# -----------------------------

class Service(Base):
    """
    Aquí el CLIENTE o ADMIN publican la necesidad (ej. Tubo roto).
    Mantenemos todos tus campos originales.
    """
    __tablename__ = "services"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String(150), nullable=False)
    
    # ✅ NUEVOS CAMPOS AÑADIDOS
    summary = Column(String(255), nullable=True)
    
    description = Column(Text, nullable=False)
    base_price = Column(Numeric(10, 2), nullable=True) # Presupuesto estimado del cliente
    
    # ✅ NUEVOS CAMPOS DE UBICACIÓN Y MULTIMEDIA
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    exact_address = Column(Text, nullable=True)
    image_urls = Column(JSON, default=list)

    category_id = Column(String(36), ForeignKey("categories.id"), nullable=False)
    
    # CAMBIO CRUCIAL: provider_id ahora es client_id porque el cliente es el dueño
    client_id = Column(String(36), ForeignKey("users.id"), nullable=False) 

    status = Column(Enum(JobStatus), default=JobStatus.OPEN)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    category = relationship("Category", back_populates="services")
    # Cambiamos el nombre de la relación para que sea más claro: Postulaciones de Workers
    requests = relationship("ServiceRequest", back_populates="service")
    
    # Mantenemos la relación con User (ahora apunta al cliente creador)
    owner = relationship("User", back_populates="services")

    @property
    def author_name(self):
        """
        Si existe el usuario dueño (owner), devuelve su nombre real.
        Si no, devuelve un texto por defecto.
        """
        if self.owner and self.owner.full_name:
            return self.owner.full_name
        return "Usuario Cliente"

    @property
    def author_image_url(self):
        """Devuelve la foto de perfil del dueño del servicio"""
        if self.owner and hasattr(self.owner, 'profile_picture_url') and self.owner.profile_picture_url:
            return self.owner.profile_picture_url
        return None


# -----------------------------
# SERVICE REQUEST (POSTULACIÓN DEL WORKER)  
# -----------------------------

class ServiceRequest(Base):
    """
    Aquí los WORKERS se postulan al Service del cliente.
    """
    __tablename__ = "service_requests"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    service_id = Column(String(36), ForeignKey("services.id"), nullable=False)
    
    worker_id = Column(String(36), ForeignKey("users.id"), nullable=False) 

    description = Column(Text, nullable=False) 
    proposed_price = Column(Numeric(10, 2), nullable=True) 
    
    status = Column(String(20), default="pending") 

    created_at = Column(DateTime, default=datetime.utcnow)

    service = relationship("Service", back_populates="requests")
    job = relationship("Job", back_populates="request", uselist=False)

    worker = relationship("User", foreign_keys=[worker_id])

    @property
    def worker_name(self):
        """Devuelve el nombre real del trabajador que se postuló"""
        if self.worker and self.worker.full_name:
            return self.worker.full_name
        return "Trabajador Interesado"

    @property
    def author_image_url(self):
        """Devuelve la URL de la foto de perfil del trabajador"""
        # (Nota: Asumo que en tu modelo User la foto se llama 'profile_picture_url'. 
        # Si se llama distinto, cámbialo aquí)
        if self.worker and self.worker.profile_picture_url: 
            return self.worker.profile_picture_url
        return None


# -----------------------------
# JOB (TRABAJO EN MARCHA)
# -----------------------------

class Job(Base):
    """
    Se crea cuando el cliente ACEPTA una postulación (MATCHED).
    """
    __tablename__ = "jobs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))

    request_id = Column(
        String(36),
        ForeignKey("service_requests.id"),
        nullable=False,
        unique=True
    )

    # IDs de referencia rápida
    provider_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    client_id = Column(String(36), ForeignKey("users.id"), nullable=False)

    status = Column(Enum(JobStatus), default=JobStatus.MATCHED)
    final_price = Column(Numeric(10, 2), nullable=True)

    started_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)

    request = relationship("ServiceRequest", back_populates="job")