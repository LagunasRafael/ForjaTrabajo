from pydantic import BaseModel, EmailStr
from typing import Optional

class SiteConfigBase(BaseModel):
    site_name: str
    support_email: EmailStr
    maintenance_mode: bool
    commission_rate: float

class SiteConfigUpdate(BaseModel):
    site_name: Optional[str] = None
    support_email: Optional[EmailStr] = None
    maintenance_mode: Optional[bool] = None
    commission_rate: Optional[float] = None

class SiteConfigResponse(SiteConfigBase):
    id: str

    class Config:
        from_attributes = True
