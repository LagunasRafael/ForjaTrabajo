from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.services import models
from datetime import datetime
from sqlalchemy import or_, and_
from sqlalchemy.orm import joinedload
from app.auth import models as auth_models 
from app.services.notifications import service as notif_service
import logging

def get_or_create_conversation(db: Session, request_id: str, user_id: str):
    """Busca si ya existe un chat para esta postulación, o crea uno nuevo."""
    request_entry = db.query(models.ServiceRequest).filter(models.ServiceRequest.id == request_id).first()
    if not request_entry:
        raise HTTPException(status_code=404, detail="La postulación no existe")

    service_entry = request_entry.service
    
    # Validar que solo el cliente dueño o el trabajador postulado puedan abrir el chat
    if str(user_id) not in [str(service_entry.client_id), str(request_entry.worker_id)]:
        raise HTTPException(status_code=403, detail="No perteneces a esta negociación")

    convo = db.query(models.Conversation).filter(models.Conversation.request_id == request_id).first()
    
    if not convo:
        convo = models.Conversation(
            request_id=str(request_id),
            client_id=str(service_entry.client_id), # type: ignore
            worker_id=str(request_entry.worker_id), # type: ignore
            status=models.ConversationStatus.OPEN.value
        )
        db.add(convo)
        db.commit()
        db.refresh(convo)

    return convo

def save_message(db: Session, conversation_id: str, sender_id: str, content: str, msg_type: str = "text"):
    """Guarda un mensaje en la BD y actualiza la fecha del chat."""
    convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
    if not convo:
        raise ValueError("Chat inexistente")

    new_msg = models.Message(
        conversation_id=str(conversation_id),
        sender_id=str(sender_id),
        content=str(content),
        message_type=str(msg_type)
    )
    convo.updated_at = datetime.utcnow() # type: ignore
    
    # 🌟 REVIVIR EL CHAT PARA AMBOS USUARIOS SI HAY NUEVO MENSAJE
    convo.is_deleted_by_client = False # type: ignore
    convo.is_deleted_by_worker = False # type: ignore
    
    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)
    return new_msg

def get_chat_history(db: Session, conversation_id: str, skip: int = 0, limit: int = 15):
    """Devuelve el historial para cuando Flutter abre la pantalla (más recientes primero)."""
    return db.query(models.Message)\
        .filter(models.Message.conversation_id == conversation_id)\
        .order_by(models.Message.created_at.desc())\
        .offset(skip).limit(limit).all()


def get_user_chats(db: Session, user_id: str):
    """Obtiene la lista de todas las conversaciones de un usuario con su último mensaje."""
    
    # 1. Buscar chats donde el usuario sea el cliente o el trabajador
    conversations = db.query(models.Conversation).options(
        joinedload(models.Conversation.request).joinedload(models.ServiceRequest.service)
    ).filter(
        or_(
            and_(models.Conversation.client_id == user_id, models.Conversation.is_deleted_by_client == False),
            and_(models.Conversation.worker_id == user_id, models.Conversation.is_deleted_by_worker == False)
        )
    ).order_by(models.Conversation.updated_at.desc()).all()

    chat_list = []
    
    for convo in conversations:
        # 2. Descubrir quién es la "otra persona" en el chat
        other_user_id = convo.worker_id if str(convo.client_id) == str(user_id) else convo.client_id
        
        # Optimizamos: Si ya cargamos el request y el service vía joinedload, no necesitamos queries extra
        request = convo.request
        service_name = request.service.title if request and request.service else "Servicio"

        # Para el otro usuario, aún necesitamos el nombre/foto. Podríamos hacer joinedload pero sqlalchemy 
        # no sabe dinámicamente si cargar client_id o worker_id fácilmente sin duplicar joins.
        # Por ahora, mantendremos este query pero con el user_id ya conocido es rápido (especialmente con el índice nuevo).
        other_user = db.query(auth_models.User).filter(auth_models.User.id == str(other_user_id)).first()
        
        # 3. Obtener el último mensaje
        last_msg = db.query(models.Message).filter(
            models.Message.conversation_id == convo.id
        ).order_by(models.Message.created_at.desc()).first()

        # ⚠️ FILTRADO DE POSTULACIONES PENDIENTES SIN MENSAJES:
        # No inundar la bandeja del chat si solo son postulados y nadie ha hablado.
        # Solo mostrar el chat si ya comenzó/se aceptó (status != pending) O si el cliente ya inició conversación (hay al menos 1 mensaje).
        request_status = str(request.status).lower().strip() if (request and request.status) else "pending"
        if request_status == "pending" and not last_msg:
            continue
        
        # ✅ AQUÍ ESTÁ LA MAGIA CORREGIDA: Usamos full_name
        other_name = other_user.full_name if other_user and other_user.full_name else "Usuario"
        
        # ✅ Aseguramos que el avatar sea una URL absoluta
        avatar = getattr(other_user, 'profile_picture_url', None)
        
        # Fallback si no hay avatar (null o vacío)
        if not avatar:
            inicial = other_name[0] if other_name else "U"
            avatar = f"https://ui-avatars.com/api/?name={inicial}&background=random"
        # Si es S3 o URL absoluta, lo dejamos. Si fuera relativa, en el futuro habría que prefijarla.
        # Por ahora, confiamos en lo que hay en DB si no es nulo.

        # 5. Generar preview inteligente del último mensaje
        if last_msg:
            if last_msg.message_type == "offer":
                offer_status = getattr(last_msg, 'status', 'pending')
                is_mine = str(last_msg.sender_id) == str(user_id)
                if offer_status == "accepted":
                    last_message_text = "Contraoferta aceptada"
                elif offer_status == "rejected":
                    last_message_text = "Contraoferta rechazada"
                elif offer_status == "withdrawn":
                    last_message_text = "Contraoferta retirada"
                else:
                    last_message_text = "Contraoferta enviada" if is_mine else "Contraoferta recibida"
            elif last_msg.message_type == "image":
                last_message_text = "ha enviado 1 imagen"
            elif last_msg.message_type == "video":
                last_message_text = "ha enviado 1 video"
            elif last_msg.message_type == "audio":
                last_message_text = "Audio"
            elif last_msg.message_type == "location":
                last_message_text = "Ubicación compartida"
            elif last_msg.message_type == "gallery":
                urls = [u.strip() for u in last_msg.content.split(",") if u.strip()]
                n = len(urls)
                last_message_text = f"ha enviado {n} imagen" if n == 1 else f"ha enviado {n} imágenes"
            elif last_msg.message_type == "system":
                last_message_text = "🛡️ " + (last_msg.content[:40] + "..." if len(last_msg.content) > 40 else last_msg.content)
            else:
                last_message_text = last_msg.content
            
            # ✍️ Indicar si el mensaje es nuestro
            if str(last_msg.sender_id) == str(user_id) and last_msg.message_type != "offer":
                last_message_text = f"Tú: {last_message_text}"
        else:
            last_message_text = "¡Comienza la conversación!"

        # 6. Calcular si hay mensajes no leídos usando el nuevo sistema de timestamps
        last_read = convo.last_read_at_client if str(convo.client_id) == str(user_id) else convo.last_read_at_worker
        has_unread = False
        if last_msg and last_msg.created_at > last_read:
            has_unread = True

        # 7. Traducir status para la UI
        status_db = str(convo.status).lower()
        if status_db in ["open", "negociating", "matched", "waiting_confirmation"]:
            status_ui = "ACTIVO"
        elif status_db == "dispute":
            status_ui = "EN DISPUTA"
        else:
            status_ui = "CERRADO"

        # 8. Obtener el estado de archivado por usuario
        is_archived = convo.is_archived_by_client if str(convo.client_id) == str(user_id) else convo.is_archived_by_worker

        # 9. Armar el JSON exacto que espera Flutter
        chat_list.append({
            "id": str(convo.id),
            "name": other_name,
            "serviceName": str(service_name),
            "status": status_ui,
            "lastMessage": last_message_text,
            "time": last_msg.created_at.strftime("%I:%M %p") if last_msg and hasattr(last_msg.created_at, "strftime") else "", # type: ignore
            "avatarUrl": avatar,
            "myRole": "client" if str(convo.client_id) == str(user_id) else "worker",
            "otherUserId": str(other_user_id),
            "isOnline": False,
            "hasUnread": has_unread,
            "isArchived": is_archived or False,
            "serviceStatus": str(request.service.status) if request and request.service else "OPEN",
            "serviceId": str(request.service.id) if request and request.service else ""
        })

    return chat_list

def send_offer(db: Session, conversation_id: str, sender_id: str, amount: float):
    convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Chat no encontrado")

    if str(convo.status) == models.ConversationStatus.CLOSED.value:
        raise HTTPException(status_code=400, detail="Esta conversación ya está cerrada.")

    # 1. 🧹 LIMPIEZA AUTOMÁTICA: Buscamos ofertas viejas pendientes y las "retiramos"
    db.query(models.Message).filter(
        models.Message.conversation_id == conversation_id,
        models.Message.message_type == models.MessageType.OFFER.value,
        models.Message.status == "pending"
    ).update({"status": "withdrawn"}, synchronize_session=False)

    # 2. ✨ CREAMOS LA NUEVA OFERTA (La única que nace 'pending')
    new_offer = models.Message(
        conversation_id=str(conversation_id),
        sender_id=str(sender_id),
        content=str(amount), 
        message_type=models.MessageType.OFFER.value,
        status="pending" 
    )
    
    convo.updated_at = datetime.utcnow() # type: ignore
    convo.status = "NEGOCIATING" # type: ignore
    
    db.add(new_offer)
    db.commit()
    db.refresh(new_offer)
    return new_offer

def handle_offer_action(db: Session, message_id: str, action: str, user_id: str):
    """Acepta o rechaza una oferta. Si se acepta, crea el Job y actualiza el flujo completo."""
    offer_msg = db.query(models.Message).filter(models.Message.id == message_id).first()
    if not offer_msg:
        raise HTTPException(status_code=404, detail="Oferta no encontrada")

    convo = db.query(models.Conversation).filter(
        models.Conversation.id == offer_msg.conversation_id
    ).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")

    if action == "accept":
        offer_msg.status = "accepted" # type: ignore

        # 1. Obtener la postulación y el servicio asociados
        request = convo.request
        if not request:
            raise HTTPException(status_code=404, detail="Postulación asociada no encontrada")

        service_entry = request.service
        if not service_entry:
            raise HTTPException(status_code=404, detail="Servicio asociado no encontrado")

        # 2. Verificar que no exista ya un Job para esta postulación
        existing_job = db.query(models.Job).filter(models.Job.request_id == request.id).first()
        if existing_job:
            raise HTTPException(status_code=400, detail="Ya existe un trabajo para esta postulación")

        # 3. Actualizar status del servicio y la postulación
        service_entry.status = models.JobStatus.MATCHED # type: ignore
        service_entry.base_price = float(str(offer_msg.content))  # 👈 Sincronizar precio pactado en el Servicio original
        request.status = "accepted" # type: ignore
        request.proposed_price = float(str(offer_msg.content))  # type: ignore

        # 4. Crear el Job (mismo flujo que accept_postulation en contracts)
        new_job = models.Job(
            request_id=str(request.id),
            provider_id=str(convo.worker_id),
            client_id=str(convo.client_id),
            status=models.JobStatus.MATCHED,
            final_price=float(str(offer_msg.content)),
            started_at=datetime.utcnow()
        )
        db.add(new_job)

        # 5. El chat permanece ABIERTO para coordinar el trabajo
        convo.status = models.ConversationStatus.OPEN.value # type: ignore

    elif action == "reject":
        offer_msg.status = "rejected" # type: ignore
    elif action == "withdraw":
        offer_msg.status = "withdrawn" # type: ignore

    # 🧹 LIMPIEZA DE NEGOCIACIÓN: Si no queda ninguna oferta 'pending', restaurar status de conversación a 'open'
    pending_offers_count = db.query(models.Message).filter(
        models.Message.conversation_id == convo.id,
        models.Message.message_type == models.MessageType.OFFER.value,
        models.Message.status == "pending"
    ).count()

    if pending_offers_count == 0:
        convo.status = models.ConversationStatus.OPEN.value # type: ignore

    db.commit()

    # 🔔 Notificar al otro usuario sobre la respuesta a la oferta (Migrado)
    receiver_id = offer_msg.sender_id if action != "withdraw" else (str(convo.worker_id) if str(convo.client_id) == str(user_id) else str(convo.client_id))
    notif_service.notify_offer_responded(
        db=db,
        conversation_id=str(convo.id),
        receiver_id=receiver_id,
        sender_id=str(user_id),
        amount=offer_msg.content, # type: ignore
        action=action
    )

    db.refresh(offer_msg)
    return offer_msg

def toggle_chat_archive(db: Session, conversation_id: str, is_archived: bool, user_id: str):
    """Archiva o desarchiva un chat verificando que el usuario pertenezca a la conversación."""
    convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
    
    if not convo:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")
        
    # Verificar que el usuario tenga permisos y aplicar el archivo solo a ese usuario
    if str(convo.client_id) == str(user_id):
        convo.is_archived_by_client = is_archived # type: ignore
    elif str(convo.worker_id) == str(user_id):
        convo.is_archived_by_worker = is_archived # type: ignore
    else:
        raise HTTPException(status_code=403, detail="No tienes permiso para modificar este chat")

    db.commit()
    return {"message": "Estado del chat actualizado correctamente"}

def mark_chat_as_read(db: Session, conversation_id: str, user_id: str):
    """Actualiza el timestamp de última lectura para un usuario en un chat."""
    convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
    if not convo:
        return
    
    now = datetime.utcnow()
    if str(convo.client_id) == str(user_id):
        convo.last_read_at_client = now # type: ignore
    elif str(convo.worker_id) == str(user_id):
        convo.last_read_at_worker = now # type: ignore
    
    db.commit()

def delete_conversation(db: Session, conversation_id: str, user_id: str):
    """Aplica soft-delete a la conversación. Si ambos la eliminan, se borra permanentemente."""
    convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
    
    if not convo:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")
    
    if str(convo.client_id) == str(user_id):
        convo.is_deleted_by_client = True # type: ignore
    elif str(convo.worker_id) == str(user_id):
        convo.is_deleted_by_worker = True # type: ignore
    else:
        raise HTTPException(status_code=403, detail="No tienes permiso para eliminar este chat")

    # Si ambos eliminaron la conversación, borrarla definitivamente
    if convo.is_deleted_by_client and convo.is_deleted_by_worker:
        db.delete(convo)
        
    db.commit()
    return {"message": "Conversación eliminada correctamente"}

def open_dispute(db: Session, conversation_id: str, user_id: str, reason: str):
    """Permite a un usuario escalar el chat a una disputa administrativa."""
    convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")

    if str(convo.client_id) != str(user_id) and str(convo.worker_id) != str(user_id):
        raise HTTPException(status_code=403, detail="No tienes permiso para abrir una disputa en este chat")

    if str(convo.status) == models.ConversationStatus.DISPUTE.value:
        raise HTTPException(status_code=400, detail="Esta conversación ya está en disputa")

    user = db.query(auth_models.User).filter(auth_models.User.id == user_id).first()
    user_name = user.full_name if user and user.full_name else "Un usuario"

    convo.status = models.ConversationStatus.DISPUTE.value # type: ignore
    convo.updated_at = datetime.utcnow() # type: ignore

    system_msg_content = f"{user_name} ha abierto una DISPUTA.\nMotivo: {reason}\nUn administrador revisará este caso pronto."
    new_msg = models.Message(
        conversation_id=str(conversation_id),
        sender_id=str(user_id),
        content=str(system_msg_content),
        message_type=models.MessageType.SYSTEM.value,
        status="pending"
    )
    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)
    
    return {"message": "Disputa abierta correctamente", "system_message": new_msg}