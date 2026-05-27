import uuid
import datetime as dt
import logging
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.auth.security import get_current_user, check_role
from app.core.roles import Role
from app.auth import models as auth_models
from app.services import models as service_models
from app.payments import models as payment_models
from app.payments.services import refund_payment, capture_payment
from app.services.disputes import schemas
from app.services.disputes import service as dispute_service
from app.services.chats.ws_manager import manager
from app.utils.email import send_dispute_opened_email, send_dispute_resolved_email
from app.services.notifications import service as notif_service

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/chat/{conversation_id}/dispute")
async def open_dispute_endpoint(
    conversation_id: str,
    dispute_data: schemas.DisputeCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    """Permite al cliente o al trabajador escalar el chat a DISPUTA."""
    response = dispute_service.open_dispute(
        db=db,
        conversation_id=conversation_id,
        user_id=str(current_user.id),
        reason=dispute_data.reason
    )

    from app.admin.ws_manager import recalculate_and_broadcast
    recalculate_and_broadcast(db)

    convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
    if convo:
        other_user_id = convo.worker_id if str(convo.client_id) == str(current_user.id) else convo.client_id
        other_user = db.query(auth_models.User).filter(auth_models.User.id == other_user_id).first()
        is_other_client = (str(convo.client_id) == str(other_user_id))

        if other_user and other_user.email:
            background_tasks.add_task(send_dispute_opened_email, other_user.email, is_other_client)

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

    try:
        if convo:
            client = db.query(auth_models.User).filter(auth_models.User.id == convo.client_id).first()
            worker = db.query(auth_models.User).filter(auth_models.User.id == convo.worker_id).first()
            notif_service.notify_dispute_opened(db, conversation_id, client, worker)
    except Exception as e:
        logger.error("Error en notificacion de disputa: %s", e)

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
    """Devuelve los mensajes de un chat especifico para el visor de disputas del admin."""
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


@router.post("/admin/chat/{conversation_id}/message")
async def send_admin_message(
    conversation_id: str,
    message_data: schemas.AdminMessageCreate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """El administrador inyecta un mensaje en un chat para mediar la disputa."""
    convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversacion no encontrada")

    new_msg = service_models.Message(
        id=str(uuid.uuid4()),
        conversation_id=conversation_id,
        sender_id=str(current_user.id),
        content=f"ADMINISTRADOR: {message_data.content}",
        message_type=service_models.MessageType.SYSTEM.value,
        status="pending",
        created_at=dt.datetime.utcnow()
    )
    convo.updated_at = dt.datetime.utcnow()

    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)

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

    try:
        convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
        if convo:
            client = db.query(auth_models.User).filter(auth_models.User.id == convo.client_id).first()
            worker = db.query(auth_models.User).filter(auth_models.User.id == convo.worker_id).first()
            notif_service.notify_admin_dispute_message(db, conversation_id, client, worker, message_data.content)
    except Exception as e:
        logger.error("Error en notificacion de admin: %s", e)

    return {"status": "success", "message": "Mensaje de administrador enviado"}


@router.post("/admin/chat/{conversation_id}/resolve")
async def resolve_dispute(
    conversation_id: str,
    resolve_data: schemas.DisputeResolveRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    """El administrador dicta la resolucion de la disputa."""
    convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversacion no encontrada")

    if convo.status != service_models.ConversationStatus.DISPUTE.value:
        raise HTTPException(status_code=400, detail="Esta conversacion no esta en estado de disputa")

    request_entry = convo.request
    if not request_entry:
        raise HTTPException(status_code=404, detail="Postulacion asociada no encontrada")

    job = request_entry.job
    if not job:
        raise HTTPException(status_code=404, detail="Trabajo no encontrado (No se completo la oferta)")

    client = db.query(auth_models.User).filter(auth_models.User.id == convo.client_id).first()
    worker = db.query(auth_models.User).filter(auth_models.User.id == convo.worker_id).first()

    contract = db.query(payment_models.Contract).filter(
        payment_models.Contract.job_id == job.id
    ).first()
    payment = None
    if contract:
        payment = db.query(payment_models.Payment).filter(
            payment_models.Payment.contract_id == contract.id
        ).first()

    if resolve_data.winner_role == "client":
        job.status = service_models.JobStatus.CANCELLED
        resolution_msg = "RESOLUCION FINAL: La disputa se ha resuelto a favor del CLIENTE. Se procedera al reembolso del dinero congelado."

        if client and client.email:
            background_tasks.add_task(send_dispute_resolved_email, client.email, True, "client")
        if worker and worker.email:
            background_tasks.add_task(send_dispute_resolved_email, worker.email, False, "worker")

    elif resolve_data.winner_role == "worker":
        job.status = service_models.JobStatus.COMPLETED
        job.completed_at = dt.datetime.utcnow()
        resolution_msg = "RESOLUCION FINAL: La disputa se ha resuelto a favor del TRABAJADOR. El pago ha sido autorizado y liberado."

        if client and client.email:
            background_tasks.add_task(send_dispute_resolved_email, client.email, False, "client")
        if worker and worker.email:
            background_tasks.add_task(send_dispute_resolved_email, worker.email, True, "worker")

    elif resolve_data.winner_role == "continue":
        resolution_msg = "La disputa ha sido cerrada por un administrador. Ambas partes pueden continuar con el trabajo. El pago permanece en escrow hasta su finalizacion."

        if client and client.email:
            background_tasks.add_task(send_dispute_resolved_email, client.email, False, "client")
        if worker and worker.email:
            background_tasks.add_task(send_dispute_resolved_email, worker.email, False, "worker")

        convo.status = service_models.ConversationStatus.ACTIVE.value
        convo.updated_at = dt.datetime.utcnow()

        new_msg = service_models.Message(
            id=str(uuid.uuid4()),
            conversation_id=conversation_id,
            sender_id=str(current_user.id),
            content=resolution_msg,
            message_type=service_models.MessageType.SYSTEM.value,
            status="pending",
            created_at=dt.datetime.utcnow()
        )
        db.add(new_msg)
        db.commit()

        from app.admin.ws_manager import recalculate_and_broadcast
        recalculate_and_broadcast(db)

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

        try:
            notif_service.notify_dispute_resolved(db, conversation_id, "continue", client, worker, resolution_msg)
        except Exception as e:
            logger.error("Error en notificacion de continuacion: %s", e)

        return {"status": "success", "message": "Disputa cerrada, trabajo continua"}
    else:
        raise HTTPException(status_code=400, detail="El ganador debe ser 'client', 'worker' o 'continue'")

    if request_entry and request_entry.service:
        request_entry.service.status = job.status
        if job.status == service_models.JobStatus.COMPLETED or job.status == service_models.JobStatus.CANCELLED:
            request_entry.service.is_active = False

    convo.status = service_models.ConversationStatus.CLOSED.value
    convo.closed_reason = service_models.ClosedReason.DISPUTE_RESOLVED.value
    convo.updated_at = dt.datetime.utcnow()

    new_msg = service_models.Message(
        id=str(uuid.uuid4()),
        conversation_id=conversation_id,
        sender_id=str(current_user.id),
        content=resolution_msg,
        message_type=service_models.MessageType.SYSTEM.value,
        status="pending",
        created_at=dt.datetime.utcnow()
    )
    db.add(new_msg)

    if resolve_data.winner_role == "client":
        if payment:
            refund_payment(db, payment.id)
        else:
            db.commit()
    elif resolve_data.winner_role == "worker":
        if payment:
            capture_payment(db, job.id)
        else:
            db.commit()

    from app.admin.ws_manager import recalculate_and_broadcast
    recalculate_and_broadcast(db)

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

    try:
        convo = db.query(service_models.Conversation).filter(service_models.Conversation.id == conversation_id).first()
        if convo:
            client = db.query(auth_models.User).filter(auth_models.User.id == convo.client_id).first()
            worker = db.query(auth_models.User).filter(auth_models.User.id == convo.worker_id).first()
            notif_service.notify_dispute_resolved(db, conversation_id, resolve_data.winner_role, client, worker, resolution_msg)
    except Exception as e:
        logger.error("Error en notificacion de resolucion: %s", e)

    return {"status": "success", "message": "Disputa resuelta y dinero manejado"}
