import enum
import uuid
from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, Enum, Float, DateTime
from app.db.database import Base
from sqlalchemy.orm import relationship

# Definimos los roles como una clase Enum de Python
class UserRole(str, enum.Enum):
    CLIENT = "client"
    WORKER = "worker"
    ADMIN = "admin"

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=True)
    profile_picture_url = Column(String, nullable=True)
    phone = Column(String, unique=True, nullable=True) # Hacemos el teléfono único
    city = Column(String, nullable=True)     # "Zitácuaro, Mich."
    fcm_token = Column(String, nullable=True) # Token para notificaciones Push
    is_email_verified = Column(Boolean, default=False)
    verification_code = Column(String(6), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Usamos el Enum aquí. SQLite lo manejará como String, 
    # pero SQLAlchemy validará los valores por ti.
    role = Column(Enum(UserRole), default=UserRole.CLIENT, nullable=False)
    
    is_active = Column(Boolean, default=True)

    services = relationship("Service", back_populates="owner")
    #payments = relationship("Payment", back_populates="payer")