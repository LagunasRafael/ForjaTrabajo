from app.utils.notifications import send_push_notification
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
import logging

from app.db.database import get_db
from app.auth.security import get_current_user
from app.auth import models as auth_models
from app.services.chats import schemas
from app.services.chats import service
from app.services.chats.ws_manager import manager
from app.services import models as service_models
from app.utils.s3 import upload_chat_media_to_s3
from typing import List
from fastapi import UploadFile, File

logger = logging.getLogger(__name__)

router = APIRouter()


class MessagePayload(BaseModel):
    content: str
    message_type: str = "text"


@router.post("/chat/{conversation_id}/message", response_model=schemas.MessageResponse)
async def send_message_rest(
    conversation_id: str,
    payload: MessagePayload,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    convo = db.query(service_models.Conversation).filter(
        service_models.Conversation.id == conversation_id
    ).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if str(convo.client_id) != str(current_user.id) and str(convo.worker_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="No perteneces a esta conversacion")
    if convo.status == service_models.ConversationStatus.CLOSED.value:
        raise HTTPException(status_code=400, detail="Esta conversacion ya esta cerrada")

    saved_msg = service.save_message(
        db, conversation_id, str(current_user.id),
        payload.content, payload.message_type
    )

    message_to_send = {
        "id": str(saved_msg.id),
        "conversation_id": str(saved_msg.conversation_id),
        "sender_id": str(saved_msg.sender_id),
        "content": saved_msg.content,
        "message_type": saved_msg.message_type,
        "created_at": saved_msg.created_at.isoformat(),
        "status": getattr(saved_msg, "status", "pending")
    }
    await manager.broadcast(conversation_id, message_to_send)

    try:
        receiver_id = str(convo.worker_id) if str(convo.client_id) == str(current_user.id) else str(convo.client_id)
        receiver = db.query(auth_models.User).filter(auth_models.User.id == receiver_id).first()
        sender = db.query(auth_models.User).filter(auth_models.User.id == str(current_user.id)).first()
        sender_name = sender.full_name if sender else "Nuevo mensaje"
        content = payload.content
        msg_type = payload.message_type
        preview = content[:60] + "..." if len(content) > 60 else content
        if msg_type == "image": preview = "Imagen"
        elif msg_type == "audio": preview = "Audio"
        elif msg_type == "video": preview = "Video"
        elif msg_type == "location": preview = "Ubicacion"

        active_ws_count = len(manager.active_connections.get(conversation_id, []))
        if receiver and receiver.fcm_token and active_ws_count < 2:
            logger.info("[REST] Enviando Push a %s", receiver.full_name)
            send_push_notification(
                fcm_token=str(receiver.fcm_token),
                title=str(sender_name),
                body=preview,
                data={
                    "type": "new_message",
                    "conversation_id": conversation_id,
                    "sender_name": sender_name
                }
            )
    except Exception as notify_err:
        logger.warning("[REST] Error notificando: %s", notify_err)

    return saved_msg


@router.get("/chat/{conversation_id}/history", response_model=List[schemas.MessageResponse])
def get_history(conversation_id: str, skip: int = 0, limit: int = 15, db: Session = Depends(get_db)):
    return service.get_chat_history(db, conversation_id, skip, limit)


@router.post("/chat/{conversation_id}/upload")
async def upload_chat_media(
    conversation_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if str(convo.client_id) != str(current_user.id) and str(convo.worker_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="No perteneces a esta conversacion")

    url = await upload_chat_media_to_s3(file, conversation_id)
    if not url:
        raise HTTPException(status_code=500, detail="Error al subir el archivo")
    return {"url": url}
