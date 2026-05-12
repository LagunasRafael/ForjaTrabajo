from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from typing import Dict, List
import json
from pydantic import BaseModel

from app.db.database import get_db
from app.auth.security import get_current_user, check_role
from app.core.roles import Role
from app.auth import models as auth_models
from app.services.chats import schemas
from app.services.chats import service 
from app.services import models as service_models
from app.utils.s3 import upload_chat_media_to_s3
from fastapi import UploadFile, File, BackgroundTasks
from app.utils.email import send_dispute_opened_email, send_dispute_resolved_email

router = APIRouter()

# ---------------------------------------------------------
# MANAGER DE WEBSOCKETS (El "Operador del Conmutador")
# ---------------------------------------------------------
class ConnectionManager:
    def __init__(self):
        # Guarda quién está conectado a qué sala: { "conversation_id": [websocket1, websocket2] }
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, conversation_id: str):
        await websocket.accept()
        if conversation_id not in self.active_connections:
            self.active_connections[conversation_id] = []
        self.active_connections[conversation_id].append(websocket)

    def disconnect(self, websocket: WebSocket, conversation_id: str):
        if conversation_id in self.active_connections:
            self.active_connections[conversation_id].remove(websocket)
            if not self.active_connections[conversation_id]:
                del self.active_connections[conversation_id]

    async def broadcast(self, conversation_id: str, message: dict):
        if conversation_id in self.active_connections:
            dead_connections = []
            for connection in self.active_connections[conversation_id]:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    print(f"Error broadcasting to connection: {e}")
                    dead_connections.append(connection)
            for dead_conn in dead_connections:
                if dead_conn in self.active_connections[conversation_id]:
                    self.active_connections[conversation_id].remove(dead_conn)

manager = ConnectionManager()

# ---------------------------------------------------------
# RUTAS REST (Peticiones normales de Flutter)
# ---------------------------------------------------------

# ✅ 1. PON ESTA RUTA HASTA ARRIBA (Para que nada la bloquee)
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
    print(f"WS CONNECTED: convo={conversation_id}, user={user_id}")
    try:
        while True:
            # Espera a que Flutter mande un mensaje
            data = await websocket.receive_text()
            print(f"WS RECEIVED DATA: {data}")
            payload = json.loads(data)
            
            msg_type = payload.get("type", "text")

            # 🟢 TYPING EVENT: No guardar en DB, solo reenviar a los demás
            if msg_type == "typing":
                typing_event = {
                    "type": "typing",
                    "sender_id": user_id,
                    "is_typing": payload.get("is_typing", False)
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
                convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
                if convo and str(convo.client_id) != str(user_id):
                    await websocket.send_json({"error": "Solo el cliente puede enviar propuestas."})
                    continue
                if convo and convo.status == service_models.ConversationStatus.CLOSED.value:
                    await websocket.send_json({"error": "Esta conversación ya está cerrada."})
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
        "sender_id": new_offer.sender_id,
        "content": new_offer.content,
        "message_type": new_offer.message_type,
        "created_at": new_offer.created_at.isoformat(),
        "status": "pending"
    }
    await manager.broadcast(offer_data.conversation_id, message_to_send)

    return new_offer

@router.post("/chat/offer/{message_id}/action")
def respond_to_offer(
    message_id: str,
    action_data: schemas.OfferAction,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """El trabajador acepta o rechaza la oferta."""
    if action_data.action not in ["accept", "reject"]:
        raise HTTPException(status_code=400, detail="Acción no válida")
        
    return service.handle_offer_action(
        db, 
        message_id=message_id, 
        action=action_data.action,
        user_id=str(current_user.id)
    )


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
def open_dispute_endpoint(
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
        "sender_id": response["system_message"].sender_id,
        "content": response["system_message"].content,
        "message_type": response["system_message"].message_type,
        "created_at": response["system_message"].created_at.isoformat(),
        "status": "pending"
    }
    
    # Hacemos el broadcast de manera asíncrona usando async loop (si manager está importado/disponible)
    import asyncio
    try:
        loop = asyncio.get_running_loop()
        loop.create_task(manager.broadcast(conversation_id, message_to_send))
    except RuntimeError:
        pass # Ignoramos si no hay loop corriendo en el test
        
    return {"status": "success", "message": "Disputa iniciada correctamente"}

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
def send_admin_message(
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
        content=f"👨‍⚖️ ADMIN: {message_data.content}",
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
        "sender_id": new_msg.sender_id,
        "content": new_msg.content,
        "message_type": new_msg.message_type,
        "created_at": new_msg.created_at.isoformat(),
        "status": "pending"
    }
    
    import asyncio
    try:
        loop = asyncio.get_running_loop()
        loop.create_task(manager.broadcast(conversation_id, message_to_send))
    except RuntimeError:
        pass
        
    return {"status": "success", "message": "Mensaje de administrador enviado"}

class DisputeResolveRequest(BaseModel):
    winner_role: str # "client" o "worker"

@router.post("/admin/chat/{conversation_id}/resolve")
def resolve_dispute(
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
    if resolve_data.winner_role == "client":
        job.status = service_models.JobStatus.CANCELLED # type: ignore
        resolution_msg = "⚖️ RESOLUCIÓN FINAL: La disputa se ha resuelto a favor del CLIENTE. Se procederá al reembolso del dinero congelado."
        
        # Enviar emails
        if client and client.email: # type: ignore
            background_tasks.add_task(send_dispute_resolved_email, client.email, True, "client") # type: ignore
        if worker and worker.email: # type: ignore
            background_tasks.add_task(send_dispute_resolved_email, worker.email, False, "worker") # type: ignore
            
    elif resolve_data.winner_role == "worker":
        job.status = service_models.JobStatus.COMPLETED # type: ignore
        job.completed_at = datetime.datetime.utcnow() # type: ignore
        resolution_msg = "⚖️ RESOLUCIÓN FINAL: La disputa se ha resuelto a favor del TRABAJADOR. El pago ha sido autorizado y liberado."
        
        # Enviar emails
        if client and client.email: # type: ignore
            background_tasks.add_task(send_dispute_resolved_email, client.email, False, "client") # type: ignore
        if worker and worker.email: # type: ignore
            background_tasks.add_task(send_dispute_resolved_email, worker.email, True, "worker") # type: ignore
    else:
        raise HTTPException(status_code=400, detail="El ganador debe ser 'client' o 'worker'")
        
    # Cerrar la conversación
    convo.status = service_models.ConversationStatus.CLOSED.value # type: ignore
    convo.updated_at = datetime.datetime.utcnow() # type: ignore
    
    # Inyectar el mensaje final
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
    db.commit()
    
    # Broadcast websocket
    message_to_send = {
        "id": new_msg.id,
        "sender_id": new_msg.sender_id,
        "content": new_msg.content,
        "message_type": new_msg.message_type,
        "created_at": new_msg.created_at.isoformat(),
        "status": "pending"
    }
    
    import asyncio
    try:
        loop = asyncio.get_running_loop()
        loop.create_task(manager.broadcast(conversation_id, message_to_send))
    except RuntimeError:
        pass
        
    return {"status": "success", "message": "Disputa resuelta y dinero manejado"}