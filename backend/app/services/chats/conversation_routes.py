from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
import logging

from app.db.database import get_db
from app.auth.security import get_current_user
from app.auth import models as auth_models
from app.services.chats import schemas
from app.services.chats import service

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/chat/my-chats")
def get_my_chats(db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    return service.get_user_chats(db, str(current_user.id))


@router.post("/chat/start/{request_id}", response_model=schemas.ConversationResponse)
def start_or_get_chat(request_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    return service.get_or_create_conversation(db, request_id, str(current_user.id))


class ArchiveToggleRequest(BaseModel):
    is_archived: bool


@router.post("/chat/{conversation_id}/archive")
def toggle_archive_chat(
    conversation_id: str,
    payload: ArchiveToggleRequest,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    return service.toggle_chat_archive(
        db=db,
        conversation_id=conversation_id,
        is_archived=payload.is_archived,
        user_id=str(current_user.id)
    )


@router.post("/chat/{conversation_id}/read")
def mark_chat_as_read(
    conversation_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    service.mark_chat_as_read(db, conversation_id, str(current_user.id))
    return {"status": "success"}


@router.delete("/chat/{conversation_id}")
def delete_chat(
    conversation_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    return service.delete_conversation(
        db=db,
        conversation_id=conversation_id,
        user_id=str(current_user.id)
    )
