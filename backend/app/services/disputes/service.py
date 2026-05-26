import logging
from datetime import datetime
from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.services import models
from app.auth import models as auth_models
from app.payments import models as payment_models

logger = logging.getLogger(__name__)


def open_dispute(db: Session, conversation_id: str, user_id: str, reason: str):
    """Permite a un usuario escalar el chat a una disputa administrativa."""
    convo = db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversacion no encontrada")

    if str(convo.client_id) != str(user_id) and str(convo.worker_id) != str(user_id):
        raise HTTPException(status_code=403, detail="No tienes permiso para abrir una disputa en este chat")

    if str(convo.status) == models.ConversationStatus.DISPUTE.value:
        raise HTTPException(status_code=400, detail="Esta conversacion ya esta en disputa")

    is_paid = False
    service_request = convo.request
    if service_request and service_request.job:
        contract = db.query(payment_models.Contract).filter(
            payment_models.Contract.job_id == service_request.job.id
        ).first()
        if contract:
            payment = db.query(payment_models.Payment).filter(
                payment_models.Payment.contract_id == contract.id
            ).order_by(payment_models.Payment.created_at.desc()).first()
            if payment and payment.status in [
                payment_models.PaymentStatus.HELD_IN_ESCROW,
                payment_models.PaymentStatus.PENDING_TRANSFER,
                payment_models.PaymentStatus.RELEASED
            ]:
                is_paid = True

    if not is_paid:
        raise HTTPException(
            status_code=400,
            detail="No se puede abrir una disputa para un servicio que no ha sido pagado"
        )

    user = db.query(auth_models.User).filter(auth_models.User.id == user_id).first()
    user_name = user.full_name if user and user.full_name else "Un usuario"

    convo.status = models.ConversationStatus.DISPUTE.value
    convo.updated_at = datetime.utcnow()

    if service_request and service_request.job:
        job = service_request.job
        job.status = models.JobStatus.DISPUTED
        if job.auto_release_at is not None:
            job.auto_release_at = None
            logger.info("Disputa: auto_release_at cancelado para job %s", job.id)
        if service_request.service:
            service_request.service.status = models.JobStatus.DISPUTED

    system_msg_content = f"{user_name} ha abierto una DISPUTA.\nMotivo: {reason}\nUn administrador revisara este caso pronto."
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
