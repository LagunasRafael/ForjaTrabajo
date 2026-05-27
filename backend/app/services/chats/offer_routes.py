from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import logging

from app.db.database import get_db
from app.auth.security import get_current_user
from app.auth import models as auth_models
from app.services.chats import schemas
from app.services.chats import service
from app.services.chats.ws_manager import manager
from app.services import models as service_models
from app.services.notifications import service as notif_service

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/chat/offer", response_model=schemas.MessageResponse)
async def create_counter_offer(
    offer_data: schemas.OfferCreate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    new_offer = service.send_offer(
        db,
        conversation_id=offer_data.conversation_id,
        sender_id=str(current_user.id),
        amount=offer_data.amount
    )

    message_to_send = {
        "id": new_offer.id,
        "conversation_id": new_offer.conversation_id,
        "sender_id": new_offer.sender_id,
        "content": new_offer.content,
        "message_type": new_offer.message_type,
        "created_at": new_offer.created_at.isoformat(),
        "status": "pending"
    }
    await manager.broadcast(offer_data.conversation_id, message_to_send)

    try:
        convo = db.query(service_models.Conversation).filter(
            service_models.Conversation.id == offer_data.conversation_id
        ).first()
        if convo:
            receiver_id = str(convo.worker_id) if str(convo.client_id) == str(current_user.id) else str(convo.client_id)
            notif_service.notify_new_offer(
                db=db,
                conversation_id=offer_data.conversation_id,
                receiver_id=receiver_id,
                sender_id=str(current_user.id),
                amount=new_offer.content
            )
    except Exception as notify_err:
        logger.warning("Error notificando contraoferta: %s", notify_err)

    return new_offer


@router.post("/chat/offer/{message_id}/action", response_model=schemas.MessageResponse)
async def respond_to_offer(
    message_id: str,
    action_data: schemas.OfferAction,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    if action_data.action not in ["accept", "reject", "withdraw"]:
        raise HTTPException(status_code=400, detail="Accion no valida")

    updated_offer = service.handle_offer_action(
        db,
        message_id=message_id,
        action=action_data.action,
        user_id=str(current_user.id)
    )

    message_to_send = {
        "id": str(updated_offer.id),
        "conversation_id": str(updated_offer.conversation_id),
        "sender_id": str(updated_offer.sender_id),
        "content": str(updated_offer.content),
        "message_type": str(updated_offer.message_type),
        "created_at": updated_offer.created_at.isoformat(),
        "status": str(updated_offer.status)
    }
    await manager.broadcast(str(updated_offer.conversation_id), message_to_send)

    return updated_offer
