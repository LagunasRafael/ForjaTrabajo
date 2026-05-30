import asyncio
import json
from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
import logging

from app.db.database import SessionLocal
from app.services.chats import service
from app.services.chats.ws_manager import manager
from app.services import models as service_models
from app.auth import models as auth_models
from app.utils.notifications import send_push_notification

logger = logging.getLogger(__name__)

router = APIRouter()


@router.websocket("/chat/ws/{conversation_id}/{user_id}")
async def websocket_endpoint(websocket: WebSocket, conversation_id: str, user_id: str):
    await manager.connect(websocket, conversation_id)
    
    # 1. Marcar como leído usando una sesión corta
    db = SessionLocal()
    try:
        service.mark_chat_as_read(db, conversation_id, user_id)
    finally:
        db.close()
        
    logger.debug("WS connected: convo=%s, user=%s", conversation_id, user_id)

    try:
        while True:
            try:
                data = await asyncio.wait_for(websocket.receive_text(), timeout=120)
            except asyncio.TimeoutError:
                logger.debug("WS timeout: convo=%s", conversation_id)
                break
            logger.debug("WS received: convo=%s", conversation_id)

            # 2. Procesar el mensaje con una nueva sesión corta
            db = SessionLocal()
            try:
                convo = db.query(service_models.Conversation).filter(
                    service_models.Conversation.id == conversation_id
                ).first()
                if convo and convo.status == service_models.ConversationStatus.CLOSED.value:
                    await websocket.send_json({"error": "Esta conversacion ya esta cerrada y no admite mas mensajes."})
                    continue

                payload = json.loads(data)
                msg_type = payload.get("type", "text")

                if msg_type == "ping":
                    await websocket.send_json({"type": "pong"})
                    continue

                if msg_type == "typing":
                    typing_event = {
                        "type": "typing",
                        "sender_id": user_id,
                        "is_typing": payload.get("is_typing", False),
                        "conversation_id": conversation_id
                    }
                    if conversation_id in manager.active_connections:
                        dead_connections = []
                        for connection in manager.active_connections[conversation_id]:
                            if connection != websocket:
                                try:
                                    await connection.send_json(typing_event)
                                except Exception:
                                    dead_connections.append(connection)
                        for dead_conn in dead_connections:
                            manager.disconnect(dead_conn, conversation_id)
                    continue

                content = payload.get("content", "")

                if msg_type == "offer":
                    if convo and str(convo.client_id) != str(user_id):
                        await websocket.send_json({"error": "Solo el cliente puede enviar propuestas."})
                        continue

                try:
                    saved_msg = service.save_message(db, conversation_id, user_id, content, msg_type)
                    logger.debug("WS saved msg: %s", saved_msg.id)
                except (ValueError, Exception) as save_err:
                    logger.warning("WS save error: %s", save_err)
                    await websocket.send_json({"error": str(save_err)})
                    continue

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
                logger.debug("WS broadcasted: convo=%s", conversation_id)

                try:
                    convo = db.query(service_models.Conversation).filter(
                        service_models.Conversation.id == conversation_id
                    ).first()
                    if convo:
                        sender = db.query(auth_models.User).filter(auth_models.User.id == user_id).first()
                        sender_name = sender.full_name if sender else "Nuevo mensaje"
                        preview = content[:60] + "..." if len(content) > 60 else content
                        if msg_type == "image": preview = "Imagen"
                        elif msg_type == "audio": preview = "Audio"
                        elif msg_type == "video": preview = "Video"
                        elif msg_type == "location": preview = "Ubicacion"

                        receiver_id = str(convo.worker_id) if str(convo.client_id) == str(user_id) else str(convo.client_id)
                        receiver = db.query(auth_models.User).filter(auth_models.User.id == receiver_id).first()

                        if receiver and receiver.fcm_token:
                            active_ws_count = len(manager.active_connections.get(conversation_id, []))
                            if active_ws_count < 2:
                                logger.info("[WS] Enviando Push a %s", receiver.full_name)
                                response = send_push_notification(
                                    fcm_token=str(receiver.fcm_token),
                                    title=str(sender_name),
                                    body=preview,
                                    data={
                                        "type": "new_message",
                                        "conversation_id": conversation_id,
                                        "sender_name": sender_name
                                    }
                                )
                                logger.info("[WS] Resultado Push: %s", response)
                            else:
                                logger.info("[WS] Receptor en sala %s, no hace falta push.", conversation_id)
                        else:
                            logger.warning("[WS] No se envio push: Receptor %s no tiene token.", receiver_id)
                except Exception as notify_err:
                    logger.error("[WS] Error notificando: %s", notify_err, exc_info=True)
            finally:
                db.close() # Siempre cerrar después de procesar el mensaje

    except WebSocketDisconnect:
        logger.debug("WS disconnected: convo=%s", conversation_id)
    except Exception as e:
        logger.warning("WS error: %s", e)
    finally:
        manager.disconnect(websocket, conversation_id)
