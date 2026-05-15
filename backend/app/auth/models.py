import enum
import uuid
from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, Enum, Float, DateTime, Text, ForeignKey
from app.db.database import Base
from sqlalchemy.orm import relationship

class UserRole(str, enum.Enum):
    CLIENT = "client"
    WORKER = "worker"
    ADMIN = "admin"

class VerificationStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=True)
    profile_picture_url = Column(String, nullable=True)
    phone = Column(String, unique=True, nullable=True)
    city = Column(String, nullable=True)
    fcm_token = Column(String, nullable=True)
    is_email_verified = Column(Boolean, default=False)
    verification_code = Column(String(6), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    role = Column(Enum(UserRole), default=UserRole.CLIENT, nullable=False)
    
    is_active = Column(Boolean, default=True)
    is_identity_verified = Column(Boolean, default=False)

    services = relationship("Service", back_populates="owner")

class IdentityVerification(Base):
    __tablename__ = "identity_verifications"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    ine_front_url = Column(String, nullable=False)
    ine_back_url = Column(String, nullable=False)
    selfie_url = Column(String, nullable=False)
    status = Column(Enum(VerificationStatus), default=VerificationStatus.PENDING, nullable=False)
    rejection_reason = Column(Text, nullable=True)
    reviewed_by = Column(String(36), ForeignKey("users.id"), nullable=True)
    face_similarity = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    reviewed_at = Column(DateTime, nullable=True)

    user = relationship("User", foreign_keys=[user_id], backref="identity_verifications")
    reviewer = relationship("User", foreign_keys=[reviewed_by])