from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ReportCreate(BaseModel):
    reported_user_id: Optional[str] = None
    reported_service_id: Optional[str] = None
    reason: str
    description: Optional[str] = None


class ReportRespond(BaseModel):
    action: str = Field(..., description="ban_user | ban_service | dismiss")
    admin_note: Optional[str] = None


class ReportResponse(BaseModel):
    id: str
    reporter_id: str
    reported_user_id: Optional[str] = None
    reported_service_id: Optional[str] = None
    reason: str
    description: Optional[str] = None
    status: str
    admin_id: Optional[str] = None
    admin_note: Optional[str] = None
    created_at: datetime
    resolved_at: Optional[datetime] = None

    reporter_name: Optional[str] = None
    reported_user_name: Optional[str] = None
    admin_name: Optional[str] = None

    class Config:
        from_attributes = True
