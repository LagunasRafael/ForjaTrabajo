import logging
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from . import models
from app.services.models import Job, JobStatus
from .refund_service import refund_payment
from .transfer_service import capture_payment

logger = logging.getLogger(__name__)


def resolve_dispute(db: Session, conversation_id: str, resolution: str):
    """
    Resuelve una disputa.
    resolution: 'refund' (devuelve al cliente) o 'release' (paga al trabajador).
    """
    from app.services.models import Conversation, ConversationStatus

    convo = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")

    if not convo.request or not convo.request.job:
        raise HTTPException(status_code=404, detail="No hay un trabajo asociado a este chat")

    job = convo.request.job

    contract = db.query(models.Contract).filter(
        models.Contract.job_id == job.id
    ).first()
    if not contract:
        raise HTTPException(status_code=404, detail="No se encontró un contrato para este trabajo")

    payment = db.query(models.Payment).filter(
        models.Payment.contract_id == contract.id,
        models.Payment.status.in_([
            models.PaymentStatus.HELD_IN_ESCROW,
            models.PaymentStatus.PENDING_TRANSFER,
        ])
    ).first()

    if resolution == "refund":
        if payment:
            refund_payment(db, payment.id)
        job.status = JobStatus.CANCELLED
    elif resolution == "release":
        if payment:
            capture_payment(db, job.id)
        job.status = JobStatus.COMPLETED
    else:
        raise HTTPException(status_code=400, detail="Resolución inválida. Use 'refund' o 'release'")

    convo.status = ConversationStatus.CLOSED.value
    db.commit()

    return {"status": "success", "message": f"Disputa resuelta como: {resolution}"}
