import uuid
from sqlalchemy import Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base
import enum

class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"

class Payment(Base):
    __tablename__ = "payments"
    
    # ID como UUID (String)
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    amount = Column(Float, nullable=False)
    status = Column(String, default=PaymentStatus.PENDING)
    payment_method = Column(String, default="card")
    provider_payment_id = Column(String, nullable=True)

    payer_id = Column(Integer, ForeignKey("users.id")) 
    
    payee_id = Column(Integer, nullable=True) 

    service_id = Column(String, ForeignKey("services.id"), nullable=True)

    # Relaciones
    payer = relationship("User")
    service = relationship("Service") 

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())