from sqlalchemy import (
    Column,
    String,
    Text,
    DateTime,
    ForeignKey,
    Enum,
    Boolean,
    Numeric,
    Float, 
    JSON  
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
    OPEN = "open"         
    MATCHED = "matched"  
    WAITING_CONFIRMATION = "waiting_confirmation" 
    COMPLETED = "completed"  
    CANCELLED = "cancelled"
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
    
    summary = Column(String(255), nullable=True)
    
    description = Column(Text, nullable=False)
    base_price = Column(Numeric(10, 2), nullable=True)
    
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    exact_address = Column(Text, nullable=True)
    image_urls = Column(JSON, default=list)
    category_id = Column(String(36), ForeignKey("categories.id"), nullable=False)
    client_id = Column(String(36), ForeignKey("users.id"), nullable=False) 
    status = Column(Enum(JobStatus), default=JobStatus.OPEN)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    category = relationship("Category", back_populates="services")
    requests = relationship("ServiceRequest", back_populates="service")
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

    @property
    def request_id(self):
        """Devuelve el request_id del Job activo asociado si lo hay."""
        for request in self.requests:
            if request.job and request.job.status != JobStatus.CANCELLED:
                return str(request.id)
        return None

    @property
    def worker_name(self):
        for request in self.requests:
            if request.job and request.job.status != JobStatus.CANCELLED:
                if request.worker and request.worker.full_name:
                    return request.worker.full_name
        return None

    @property
    def worker_image_url(self):
        for request in self.requests:
            if request.job and request.job.status != JobStatus.CANCELLED:
                if request.worker and request.worker.profile_picture_url:
                    return request.worker.profile_picture_url
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
    
    # 🚀 AQUÍ ESTÁ EL HILO QUE FALTABA PARA CONECTAR CON EL CHAT
    conversation = relationship("Conversation", back_populates="request", uselist=False)

    @property
    def worker_name(self):
        if self.worker and self.worker.full_name:
            return self.worker.full_name
        return "Trabajador Interesado"

    @property
    def author_image_url(self):
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
    
# -----------------------------
# CHATS Y NEGOCIACIÓN
# -----------------------------
class ConversationStatus(str, enum.Enum):
    OPEN = "open"
    CLOSED = "closed" 

class MessageType(str, enum.Enum):
    TEXT = "text" 
    OFFER = "offer" 
    SYSTEM = "system" 

class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    request_id = Column(String(36), ForeignKey("service_requests.id"), unique=True, nullable=False, index=True)
    client_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    worker_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    
    status = Column(String(20), default=ConversationStatus.OPEN.value)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    is_archived = Column(Boolean, default=False)
    is_deleted_by_client = Column(Boolean, default=False)
    is_deleted_by_worker = Column(Boolean, default=False)

    request = relationship("ServiceRequest", back_populates="conversation")
    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan")

class Message(Base):
    __tablename__ = "messages"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    conversation_id = Column(String(36), ForeignKey("conversations.id"), nullable=False, index=True)
    sender_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True) 
    content = Column(Text, nullable=False) 
    message_type = Column(String(20), default="text")
    
    status = Column(String(20), default="pending") 
    
    created_at = Column(DateTime, default=datetime.utcnow)
    conversation = relationship("Conversation", back_populates="messages")