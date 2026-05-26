from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

# --- SCHEMAS DE MENSAJES ---
class MessageCreate(BaseModel):
    content: str
    message_type: str = "text" 

class MessageResponse(BaseModel):
    id: str
    conversation_id: str
    sender_id: str
    content: str
    message_type: Optional[str] = "text"
    created_at: datetime
    status: Optional[str] = "pending"

    class Config:
        from_attributes = True

# --- SCHEMAS DE CONVERSACIONES ---
class ConversationResponse(BaseModel):
    id: str
    request_id: str
    client_id: str
    worker_id: str
    status: str
    created_at: datetime
    updated_at: datetime
    last_message: Optional[MessageResponse] = None

    class Config:
        from_attributes = True

class OfferCreate(BaseModel):
    conversation_id: str
    amount: float

class OfferAction(BaseModel):
    action: str # "accept" o "reject"

