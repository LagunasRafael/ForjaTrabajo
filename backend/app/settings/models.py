from sqlalchemy import Column, String, Boolean, Float, Integer
from app.db.database import Base
import uuid

class SiteConfig(Base):
    __tablename__ = "site_config"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    site_name = Column(String(100), default="Forja Trabajo")
    support_email = Column(String(100), default="soporte@forjatrabajo.com")
    maintenance_mode = Column(Boolean, default=False)
    commission_rate = Column(Float, default=10.0)
