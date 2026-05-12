from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.services import models
from datetime import datetime
from sqlalchemy import or_, and_
from sqlalchemy.orm import joinedload
from app.auth import models as auth_models 

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
            request_id=request_id,
            client_id=service_entry.client_id,
            worker_id=request_entry.worker_id,
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
        conversation_id=conversation_id,
        sender_id=sender_id,
        content=content,
        message_type=msg_type
    )
    convo.updated_at = datetime.utcnow()
    
    # 🌟 REVIVIR EL CHAT PARA AMBOS USUARIOS SI HAY NUEVO MENSAJE
    convo.is_deleted_by_client = False
    convo.is_deleted_by_worker = False
    
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
        other_user = db.query(auth_models.User).filter(auth_models.User.id == other_user_id).first()
        
        # 3. Obtener el último mensaje (Sigue siendo un query extra por chat, pero mejoramos el resto)
        last_msg = db.query(models.Message).filter(
            models.Message.conversation_id == convo.id
        ).order_by(models.Message.created_at.desc()).first()
        
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
                    last_message_text = "✅ Contraoferta aceptada"
                elif offer_status == "rejected":
                    last_message_text = "❌ Contraoferta rechazada"
                elif offer_status == "withdrawn":
                    last_message_text = "↩️ Contraoferta retirada"
                else:
                    last_message_text = "📋 Contraoferta enviada" if is_mine else "📋 Contraoferta recibida"
            elif last_msg.message_type == "image":
                last_message_text = "📷 Foto"
            elif last_msg.message_type == "video":
                last_message_text = "🎬 Video"
            elif last_msg.message_type == "audio":
                last_message_text = "🎵 Audio"
            elif last_msg.message_type == "location":
                last_message_text = "📍 Ubicación compartida"
            elif last_msg.message_type == "gallery":
                last_message_text = "🖼️ Galería multimedia"
            else:
                last_message_text = last_msg.content
        else:
            last_message_text = "No hay mensajes aún"

        # 6. Calcular si hay mensajes no leídos (si el último mensaje es del otro usuario)
        has_unread = False
        if last_msg and str(last_msg.sender_id) != str(user_id):
            has_unread = True

        # 7. Armar el JSON exacto que espera Flutter
        chat_list.append({
            "id": str(convo.id),
            "name": other_name,
            "serviceName": service_name,
            "status": "ACTIVO" if convo.status == "OPEN" else "CERRADO",
            "lastMessage": last_message_text,
            "time": last_msg.created_at.strftime("%I:%M %p") if last_msg else "",
            "avatarUrl": avatar,
            "myRole": "client" if str(convo.client_id) == str(user_id) else "worker",
            "isOnline": False,
            "hasUnread": has_unread,
            "isArchived": convo.is_archived or False
        })

    return chat_list

def send_offer(db: Session, conversation_id: str, sender_id: str, amount: float):
    convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Chat no encontrado")

    if convo.status == models.ConversationStatus.CLOSED.value:
        raise HTTPException(status_code=400, detail="Esta conversación ya está cerrada.")

    # 1. 🧹 LIMPIEZA AUTOMÁTICA: Buscamos ofertas viejas pendientes y las "retiramos"
    db.query(models.Message).filter(
        models.Message.conversation_id == conversation_id,
        models.Message.message_type == models.MessageType.OFFER.value,
        models.Message.status == "pending"
    ).update({"status": "withdrawn"}, synchronize_session=False)

    # 2. ✨ CREAMOS LA NUEVA OFERTA (La única que nace 'pending')
    new_offer = models.Message(
        conversation_id=conversation_id,
        sender_id=sender_id,
        content=str(amount), 
        message_type=models.MessageType.OFFER.value,
        status="pending" 
    )
    
    convo.updated_at = datetime.utcnow()
    convo.status = "NEGOCIATING" 
    
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
        offer_msg.status = "accepted"

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
        service_entry.status = models.JobStatus.MATCHED
        request.status = "accepted"
        request.proposed_price = float(offer_msg.content)  # Precio negociado en el chat

        # 4. Crear el Job (mismo flujo que accept_postulation en contracts)
        new_job = models.Job(
            request_id=request.id,
            provider_id=convo.worker_id,
            client_id=convo.client_id,
            status=models.JobStatus.MATCHED,
            final_price=float(offer_msg.content),
            started_at=datetime.utcnow()
        )
        db.add(new_job)

        # 5. Cerrar la conversación (el trato se cerró)
        convo.status = models.ConversationStatus.CLOSED.value

    elif action == "reject":
        offer_msg.status = "rejected"

    db.commit()
    db.refresh(offer_msg)
    return offer_msg

def toggle_chat_archive(db: Session, conversation_id: str, is_archived: bool, user_id: str):
    """Archiva o desarchiva un chat verificando que el usuario pertenezca a la conversación."""
    convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
    
    if not convo:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")
        
    # Verificar que el usuario tenga permisos
    if str(convo.client_id) != str(user_id) and str(convo.worker_id) != str(user_id):
        raise HTTPException(status_code=403, detail="No tienes permiso para modificar este chat")

    # Guardamos el estado de archivo
    convo.is_archived = is_archived
    db.commit()
    return {"message": "Estado del chat actualizado correctamente"}

def delete_conversation(db: Session, conversation_id: str, user_id: str):
    """Aplica soft-delete a la conversación. Si ambos la eliminan, se borra permanentemente."""
    convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
    
    if not convo:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")
    
    if str(convo.client_id) == str(user_id):
        convo.is_deleted_by_client = True
    elif str(convo.worker_id) == str(user_id):
        convo.is_deleted_by_worker = True
    else:
        raise HTTPException(status_code=403, detail="No tienes permiso para eliminar este chat")

    # Si ambos eliminaron la conversación, borrarla definitivamente
    if convo.is_deleted_by_client and convo.is_deleted_by_worker:
        db.delete(convo)
        
    db.commit()
    return {"message": "Conversación eliminada correctamente"}