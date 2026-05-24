from app.utils.notifications import send_push_notification
from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from typing import List, Dict
import json
from pydantic import BaseModel
import logging

from app.db.database import get_db
from app.auth.security import get_current_user, check_role
from app.core.roles import Role
from app.auth import models as auth_models
from app.services.chats import schemas
from app.services.chats import service 
from app.services.chats.ws_manager import manager
from app.services import models as service_models
from app.payments import models as payment_models
from app.payments.services import refund_payment, capture_payment
from app.utils.s3 import upload_chat_media_to_s3
from app.services.notifications import service as notif_service
from fastapi import UploadFile, File, BackgroundTasks
from app.utils.email import send_dispute_opened_email, send_dispute_resolved_email

logger = logging.getLogger(__name__)

router = APIRouter()


class MessagePayload(BaseModel):
    content: str
    message_type: str = "text"

# ---------------------------------------------------------
# RUTAS REST (Peticiones normales de Flutter)
# ---------------------------------------------------------

# ✅ 1. PON ESTA RUTA HASTA ARRIBA (Para que nada la bloquee)
@router.post("/chat/{conversation_id}/message", response_model=schemas.MessageResponse)
async def send_message_rest(
    conversation_id: str,
    payload: MessagePayload,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """REST fallback para enviar mensajes cuando WebSocket no esta disponible."""
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
            logger.info(f"📣 [REST] Enviando Push a {receiver.full_name}")
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
        logger.warning(f"⚠️ [REST] Error notificando: {notify_err}")

    return saved_msg


@router.get("/chat/my-chats")
def get_my_chats(db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    """Flutter llama esto para pintar la bandeja de entrada completa."""
    return service.get_user_chats(db, str(current_user.id))

# ✅ 2. Luego ya dejas las que tenías que tienen {variables}
@router.post("/chat/start/{request_id}", response_model=schemas.ConversationResponse)
def start_or_get_chat(request_id: str, db: Session = Depends(get_db), current_user: auth_models.User = Depends(get_current_user)):
    return service.get_or_create_conversation(db, request_id, str(current_user.id))

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
    """Sube un archivo multimedia al bucket S3 y devuelve su URL para usarla en un mensaje."""
    # Verificar que el usuario pertenece al chat
    convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if str(convo.client_id) != str(current_user.id) and str(convo.worker_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="No perteneces a esta conversación")

    url = await upload_chat_media_to_s3(file, conversation_id)
    if not url:
        raise HTTPException(status_code=500, detail="Error al subir el archivo")
    return {"url": url}

# ---------------------------------------------------------
# RUTA WEBSOCKET (La Línea Directa en Tiempo Real)
# ---------------------------------------------------------
@router.websocket("/chat/ws/{conversation_id}/{user_id}")
async def websocket_endpoint(websocket: WebSocket, conversation_id: str, user_id: str, db: Session = Depends(get_db)):
    """
    AQUÍ SE CONECTA FLUTTER PARA CHATEAR.
    URL ejemplo: ws://localhost:8000/chat/ws/1234-abcd/mi-user-id
    """
    await manager.connect(websocket, conversation_id)
    # Marcar como leído al entrar
    service.mark_chat_as_read(db, conversation_id, user_id)
    print(f"WS CONNECTED & READ: convo={conversation_id}, user={user_id}")
    
    try:
        while True:
            # Espera a que Flutter mande un mensaje
            data = await websocket.receive_text()
            print(f"WS RECEIVED DATA: {data}")
            
            # Verificar si la conversación está cerrada ANTES de procesar nada
            convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
            if convo and convo.status == service_models.ConversationStatus.CLOSED.value:
                await websocket.send_json({"error": "Esta conversación ya está cerrada y no admite más mensajes."})
                continue

            payload = json.loads(data)
            
            msg_type = payload.get("type", "text")

            # 🟢 TYPING EVENT: No guardar en DB, solo reenviar a los demás
            if msg_type == "typing":
                typing_event = {
                    "type": "typing",
                    "sender_id": user_id,
                    "is_typing": payload.get("is_typing", False),
                    "conversation_id": conversation_id # 👈 Importante para el filtrado frontend
                }
                # Broadcast a todos EXCEPTO al que envió
                if conversation_id in manager.active_connections:
                    for connection in manager.active_connections[conversation_id]:
                        if connection != websocket:
                            try:
                                await connection.send_json(typing_event)
                            except Exception:
                                pass
                continue

            # 🟢 MENSAJE NORMAL: Guardar en DB y broadcast
            content = payload.get("content", "")
            
            # --- SEGURIDAD: Solo el cliente puede despachar type "offer" directamente por WS o endpoints
            if msg_type == "offer":
                if convo and str(convo.client_id) != str(user_id):
                    await websocket.send_json({"error": "Solo el cliente puede enviar propuestas."})
                    continue
                
            
            try:
                saved_msg = service.save_message(db, conversation_id, user_id, content, msg_type)
                print(f"WS SAVED MSG: {saved_msg.id}")
            except (ValueError, Exception) as save_err:
                print(f"WS SAVE ERROR: {save_err}")
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
            print(f"WS BROADCASTED MSG to convo={conversation_id}")

            # 🔔 Push notification si el receptor NO está conectado al WS
            try:
                convo = db.query(service_models.Conversation).filter(
                    service_models.Conversation.id == conversation_id
                ).first()
                if convo:
                    # Determinar receptor
                    receiver_id = str(convo.worker_id) if str(convo.client_id) == user_id else str(convo.client_id)
                    active_ws_count = len(manager.active_connections.get(conversation_id, []))
                    # Solo enviar push si el receptor no está en el chat (1 conexión = solo el emisor)
                    if active_ws_count < 2:
                        receiver = db.query(auth_models.User).filter(
                            auth_models.User.id == receiver_id
                        ).first()
                        sender = db.query(auth_models.User).filter(
                            auth_models.User.id == user_id
                        ).first()
                    sender = db.query(auth_models.User).filter(auth_models.User.id == user_id).first()
                    sender_name = sender.full_name if sender else "Nuevo mensaje"
                    preview = content[:60] + "..." if len(content) > 60 else content
                    if msg_type == "image": preview = "📷 Imagen"
                    elif msg_type == "audio": preview = "🎤 Audio"
                    elif msg_type == "video": preview = "🎥 Video"
                    elif msg_type == "location": preview = "📍 Ubicación"
                    
                    # 📱 Enviar Notificación Push para Tiempo Real
                    receiver_id = str(convo.worker_id) if str(convo.client_id) == str(user_id) else str(convo.client_id)
                    receiver = db.query(auth_models.User).filter(auth_models.User.id == receiver_id).first()
                    
                    if receiver and receiver.fcm_token:
                        # Si solo hay una persona en el WS (el emisor), el receptor necesita push
                        active_ws_count = len(manager.active_connections.get(conversation_id, []))
                        
                        # Siempre enviamos la push si el receptor no está en el chat activo
                        if active_ws_count < 2:
                            logger.info(f"📣 [WS] Enviando Push a {receiver.full_name} (Token: {str(receiver.fcm_token)[:10]}...)")
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
                            logger.info(f"📡 [WS] Resultado Push: {response}")
                        else:
                            logger.info(f"✅ [WS] Receptor está en la sala {conversation_id}, no hace falta push.")
                    else:
                        logger.warning(f"⚠️ [WS] No se envió push: Receptor {receiver_id} no tiene token.")
            except Exception as notify_err:
                logger.error(f"❌ [WS] Error notificando: {notify_err}", exc_info=True)

    except WebSocketDisconnect:
        print(f"WS DISCONNECTED: convo={conversation_id}")
        manager.disconnect(websocket, conversation_id)
    except Exception as e:
        print(f"WS ERROR: {e}")
        manager.disconnect(websocket, conversation_id)

# ---------------------------------------------------------
# RUTAS DE NEGOCIACIÓN (Ofertas y Contratos)
# ---------------------------------------------------------

@router.post("/chat/offer", response_model=schemas.MessageResponse)
async def create_counter_offer(
    offer_data: schemas.OfferCreate, 
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """El cliente envía una nueva oferta formal y se avisa por WebSocket."""
    
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

    # 🔔 Notificar al otro usuario sobre la nueva contraoferta (Migrado)
    try:
        convo = db.query(service_models.Conversation).filter(
            service_models.Conversation.id == offer_data.conversation_id
        ).first()
        if convo:
            # El receptor es el que NO mandó la oferta
            receiver_id = str(convo.worker_id) if str(convo.client_id) == str(current_user.id) else str(convo.client_id)
            notif_service.notify_new_offer(
                db=db,
                conversation_id=offer_data.conversation_id,
                receiver_id=receiver_id,
                sender_id=str(current_user.id),
                amount=new_offer.content # type: ignore
            )
    except Exception as notify_err:
        logger.warning(f"Error notificando contraoferta: {notify_err}")

    return new_offer

@router.post("/chat/offer/{message_id}/action", response_model=schemas.MessageResponse)
async def respond_to_offer(
    message_id: str,
    action_data: schemas.OfferAction,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """El trabajador acepta o rechaza la oferta."""
    if action_data.action not in ["accept", "reject", "withdraw"]:
        raise HTTPException(status_code=400, detail="Acción no válida")
        
    updated_offer = service.handle_offer_action(
        db, 
        message_id=message_id, 
        action=action_data.action,
        user_id=str(current_user.id)
    )

    # Broadcast updated offer state to WS
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


class ArchiveToggleRequest(BaseModel):
    is_archived: bool

@router.post("/chat/{conversation_id}/archive")
def toggle_archive_chat(
    conversation_id: str,
    payload: ArchiveToggleRequest,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Permite al usuario archivar o desarchivar un chat."""
    
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
    """Permite marcar un chat como leído explícitamente."""
    service.mark_chat_as_read(db, conversation_id, str(current_user.id))
    return {"status": "success"}

@router.delete("/chat/{conversation_id}")
def delete_chat(
    conversation_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Elimina una conversación y todos sus mensajes."""
    return service.delete_conversation(
        db=db,
        conversation_id=conversation_id,
        user_id=str(current_user.id)
    )

@router.post("/chat/{conversation_id}/dispute")
async def open_dispute_endpoint(
    conversation_id: str,
    dispute_data: schemas.DisputeCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Permite al cliente o al trabajador escalar el chat a DISPUTA."""
    response = service.open_dispute(
        db=db,
        conversation_id=conversation_id,
        user_id=str(current_user.id),
        reason=dispute_data.reason
    )
    
    # Send email notification
    convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
    if convo:
        other_user_id = convo.worker_id if str(convo.client_id) == str(current_user.id) else convo.client_id # type: ignore
        other_user = db.query(auth_models.User).filter(auth_models.User.id == other_user_id).first()
        is_other_client = (str(convo.client_id) == str(other_user_id)) # type: ignore
        
        if other_user and other_user.email: # type: ignore
            background_tasks.add_task(send_dispute_opened_email, other_user.email, is_other_client) # type: ignore
    
    # Notificamos por WebSocket a la otra parte para que aparezca el mensaje de inmediato
    message_to_send = {
        "id": response["system_message"].id,
        "conversation_id": conversation_id,
        "sender_id": response["system_message"].sender_id,
        "content": response["system_message"].content,
        "message_type": response["system_message"].message_type,
        "created_at": response["system_message"].created_at.isoformat(),
        "status": "pending"
    }
    
    await manager.broadcast(conversation_id, message_to_send)
    print(f"🚩 DISPUTE broadcasted to {conversation_id}")

    # 🔔 Notificar por Push que se inició una disputa
    try:
        if convo:
            client = db.query(auth_models.User).filter(auth_models.User.id == convo.client_id).first()
            worker = db.query(auth_models.User).filter(auth_models.User.id == convo.worker_id).first()
            
            dispute_msg = "Este chat ha entrado en disputa y un administrador intervendrá pronto."
            
            for user in [client, worker]:
                if user and user.fcm_token:
                    send_push_notification(
                        fcm_token=str(user.fcm_token),
                        title="Disputa Iniciada",
                        body=dispute_msg,
                        data={
                            "type": "dispute_opened", 
                            "conversation_id": conversation_id,
                            "sender_name": "Sistema"
                        }
                    )
    except Exception as e:
        print(f"Error enviando Push de Inicio de Disputa: {e}")
        
    return {
        "status": "success",
        "message": "Disputa iniciada correctamente",
        "system_message": {
            "id": str(response["system_message"].id),
            "conversation_id": conversation_id,
            "sender_id": str(response["system_message"].sender_id),
            "content": response["system_message"].content,
            "message_type": response["system_message"].message_type,
            "created_at": response["system_message"].created_at.isoformat(),
            "status": "sent"
        }
    }

# =================================================================
# ADMIN DISPUTES
# =================================================================

@router.get("/admin/conversations/all")
def get_all_conversations_admin(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """Devuelve todas las conversaciones para el visor de disputas del admin."""
    conversations = db.query(service_models.Conversation).order_by(service_models.Conversation.updated_at.desc()).all()
    
    result = []
    for conv in conversations:
        client = db.query(auth_models.User).filter(auth_models.User.id == conv.client_id).first()
        worker = db.query(auth_models.User).filter(auth_models.User.id == conv.worker_id).first()
        
        result.append({
            "id": conv.id,
            "request_id": conv.request_id,
            "status": conv.status,
            "created_at": conv.created_at,
            "updated_at": conv.updated_at,
            "client_name": client.full_name if client else "Cliente",
            "worker_name": worker.full_name if worker else "Trabajador",
        })
    return result

@router.get("/admin/conversations/{conversation_id}/messages")
def get_conversation_messages_admin(
    conversation_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """Devuelve los mensajes de un chat específico para el visor de disputas del admin."""
    messages = db.query(service_models.Message).filter(
        service_models.Message.conversation_id == conversation_id
    ).order_by(service_models.Message.created_at.asc()).all()
    
    result = []
    for msg in messages:
        sender = db.query(auth_models.User).filter(auth_models.User.id == msg.sender_id).first()
        result.append({
            "id": msg.id,
            "sender_id": msg.sender_id,
            "sender_name": sender.full_name if sender else "Usuario",
            "content": msg.content,
            "message_type": msg.message_type,
            "created_at": msg.created_at
        })
    return result

class AdminMessageCreate(BaseModel):
    content: str

@router.post("/admin/chat/{conversation_id}/message")
async def send_admin_message(
    conversation_id: str,
    message_data: AdminMessageCreate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """El administrador inyecta un mensaje en un chat para mediar la disputa."""
    convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")
        
    # Crear mensaje SYSTEM del Admin
    import uuid
    from datetime import datetime
    new_msg = service_models.Message(
        id=str(uuid.uuid4()),
        conversation_id=conversation_id,
        sender_id=str(current_user.id),
        content=f"ADMINISTRADOR: {message_data.content}",
        message_type=service_models.MessageType.SYSTEM.value,
        status="pending",
        created_at=datetime.utcnow()
    )
    convo.updated_at = datetime.utcnow() # type: ignore
    
    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)
    
    # Broadcast websocket
    message_to_send = {
        "id": new_msg.id,
        "conversation_id": conversation_id,
        "sender_id": new_msg.sender_id,
        "content": new_msg.content,
        "message_type": new_msg.message_type,
        "created_at": new_msg.created_at.isoformat(),
        "status": "pending"
    }
    
    await manager.broadcast(conversation_id, message_to_send)
    print(f"ADMIN MSG broadcasted to {conversation_id}")

    # 🔔 Notificar por Push al Cliente y al Trabajador
    try:
        convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
        if convo:
            client = db.query(auth_models.User).filter(auth_models.User.id == convo.client_id).first()
            worker = db.query(auth_models.User).filter(auth_models.User.id == convo.worker_id).first()
            
            preview = message_data.content[:60] + "..." if len(message_data.content) > 60 else message_data.content
            
            for user in [client, worker]:
                if user and user.fcm_token:
                    logger.info(f"📣 [ADMIN] Enviando Push a {user.full_name}...")
                    response = send_push_notification(
                        fcm_token=str(user.fcm_token),
                        title="Soporte Forja",
                        body=preview,
                        data={
                            "type": "new_message", 
                            "conversation_id": conversation_id,
                            "sender_name": "Soporte Forja"
                        }
                    )
                    logger.info(f"📡 [ADMIN] Resultado Push: {response}")
                else:
                    logger.warning(f"⚠️ [ADMIN] Un usuario no tiene token FCM.")
    except Exception as e:
        print(f"Error enviando Push de Admin: {e}")

        
    return {"status": "success", "message": "Mensaje de administrador enviado"}

class DisputeResolveRequest(BaseModel):
    winner_role: str # "client" o "worker"

@router.post("/admin/chat/{conversation_id}/resolve")
async def resolve_dispute(
    conversation_id: str,
    resolve_data: DisputeResolveRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """El administrador dicta la resolución de la disputa."""
    convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")
        
    if convo.status != service_models.ConversationStatus.DISPUTE.value: # type: ignore
        raise HTTPException(status_code=400, detail="Esta conversación no está en estado de disputa")
        
    request_entry = convo.request # type: ignore
    if not request_entry:
        raise HTTPException(status_code=404, detail="Postulación asociada no encontrada")
        
    job = request_entry.job # type: ignore
    if not job:
        raise HTTPException(status_code=404, detail="Trabajo no encontrado (No se completó la oferta)")
        
    # Obtener usuarios para correos
    client = db.query(auth_models.User).filter(auth_models.User.id == convo.client_id).first() # type: ignore
    worker = db.query(auth_models.User).filter(auth_models.User.id == convo.worker_id).first() # type: ignore
    
    import datetime

    # Buscar contrato y pago asociados (para ambos paths)
    contract = db.query(payment_models.Contract).filter(
        payment_models.Contract.job_id == job.id
    ).first()
    payment = None
    if contract:
        payment = db.query(payment_models.Payment).filter(
            payment_models.Payment.contract_id == contract.id
        ).first()

    # 1. Determinar resultado segun ganador
    if resolve_data.winner_role == "client":
        job.status = service_models.JobStatus.CANCELLED # type: ignore
        resolution_msg = "RESOLUCION FINAL: La disputa se ha resuelto a favor del CLIENTE. Se procedera al reembolso del dinero congelado."
        
        if client and client.email: # type: ignore
            background_tasks.add_task(send_dispute_resolved_email, client.email, True, "client") # type: ignore
        if worker and worker.email: # type: ignore
            background_tasks.add_task(send_dispute_resolved_email, worker.email, False, "worker") # type: ignore
            
    elif resolve_data.winner_role == "worker":
        job.status = service_models.JobStatus.COMPLETED # type: ignore
        job.completed_at = datetime.datetime.utcnow() # type: ignore
        resolution_msg = "RESOLUCION FINAL: La disputa se ha resuelto a favor del TRABAJADOR. El pago ha sido autorizado y liberado."
        
        if client and client.email: # type: ignore
            background_tasks.add_task(send_dispute_resolved_email, client.email, False, "client") # type: ignore
        if worker and worker.email: # type: ignore
            background_tasks.add_task(send_dispute_resolved_email, worker.email, True, "worker") # type: ignore
    else:
        raise HTTPException(status_code=400, detail="El ganador debe ser 'client' o 'worker'")
        
    # 2. Reflejar el fin de la labor en el servicio principal
    if request_entry and request_entry.service:
        request_entry.service.status = job.status # type: ignore
        if job.status == service_models.JobStatus.COMPLETED or job.status == service_models.JobStatus.CANCELLED:
            request_entry.service.is_active = False # type: ignore
        
    # 3. Cerrar la conversación
    convo.status = service_models.ConversationStatus.CLOSED.value # type: ignore
    convo.closed_reason = service_models.ClosedReason.DISPUTE_RESOLVED.value # type: ignore
    convo.updated_at = datetime.datetime.utcnow() # type: ignore
    
    # 4. Inyectar el mensaje final
    import uuid
    new_msg = service_models.Message(
        id=str(uuid.uuid4()),
        conversation_id=conversation_id,
        sender_id=str(current_user.id),
        content=resolution_msg,
        message_type=service_models.MessageType.SYSTEM.value,
        status="pending",
        created_at=datetime.datetime.utcnow()
    )
    db.add(new_msg)

    # 5. Procesar pago (commit unico: persiste todos los cambios anteriores atómicamente)
    print(f"[RESOLVE] winner={resolve_data.winner_role}, payment={'EXISTS' if payment else 'NONE'}, stripe_id={payment.stripe_payment_intent_id if payment else 'N/A'}", flush=True)
    if resolve_data.winner_role == "client":
        if payment:
            print(f"[RESOLVE] Llamando refund_payment({payment.id})...", flush=True)
            refund_payment(db, payment.id)
            print(f"[RESOLVE] refund_payment OK", flush=True)
        else:
            db.commit()
    elif resolve_data.winner_role == "worker":
        if payment:
            print(f"[RESOLVE] Llamando capture_payment(job.id={job.id})...", flush=True)
            capture_payment(db, job.id)
            print(f"[RESOLVE] capture_payment OK", flush=True)
        else:
            db.commit()
    
    # Broadcast websocket
    message_to_send = {
        "id": new_msg.id,
        "conversation_id": conversation_id, # 👈 ¡ESTO FALTABA!
        "sender_id": new_msg.sender_id,
        "content": new_msg.content,
        "message_type": new_msg.message_type,
        "created_at": new_msg.created_at.isoformat(),
        "status": "pending"
    }
    
    await manager.broadcast(conversation_id, message_to_send)
    print(f"RESOLUTION broadcasted to {conversation_id}")

    # 🔔 Notificar por Push la resolución final
    try:
        convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
        if convo:
            client = db.query(auth_models.User).filter(auth_models.User.id == convo.client_id).first()
            worker = db.query(auth_models.User).filter(auth_models.User.id == convo.worker_id).first()
            
            for user in [client, worker]:
                if user and user.fcm_token:
                    send_push_notification(
                        fcm_token=str(user.fcm_token),
                        title="Resolución de Trabajo",
                        body=resolution_msg,
                        data={
                            "type": "job_completed" if resolve_data.winner_role == "worker" else "job_cancelled",
                            "conversation_id": conversation_id,
                            "sender_name": "Soporte Forja"
                        }
                    )
    except Exception as e:
        print(f"Error enviando Push de Resolucion: {e}")

        
    return {"status": "success", "message": "Disputa resuelta y dinero manejado"}