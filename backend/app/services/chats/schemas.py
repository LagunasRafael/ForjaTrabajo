from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

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
    status: Optional[str] = "pending" # 👈 ¡NUEVO! Salvavidas para la amnesia

    class Config:
        from_attributes = True

# --- SCHEMAS DE NEGOCIACIÓN (NUEVOS) ---
class OfferCreate(BaseModel):
    conversation_id: str
    amount: float

class OfferAction(BaseModel):
    action: str  # Solo permitiremos "accept" o "reject"

# --- SCHEMAS DE CONVERSACIÓN ---
class ConversationCreate(BaseModel):
    request_id: str

class ConversationResponse(BaseModel):
    id: str
    request_id: str
    client_id: str
    worker_id: str
    status: str
    created_at: datetime
    updated_at: datetime
    messages: List[MessageResponse] = []

    class Config:
        from_attributes = True

# --- SCHEMAS DE DISPUTAS ---
class DisputeCreate(BaseModel):
    reason: str = Field(..., description="Motivo por el cual se abre la disputa")