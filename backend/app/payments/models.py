from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from app.db.database import Base
import enum

class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"

class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    amount = Column(Float, nullable=False)
    status = Column(String, default=PaymentStatus.PENDING)
    payment_method = Column(String, default="card")
    provider_payment_id = Column(String, nullable=True)
    
    # 👇 IMPORTANTE: Estas líneas NO deben tener '#' al inicio
    payer_id = Column(Integer, nullable=True)
    payee_id = Column(Integer, nullable=True)
    service_id = Column(Integer, nullable=True)

    # 👇 Fechas (Asegúrate de que estén aquí)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())