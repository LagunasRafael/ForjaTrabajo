from sqlalchemy.orm import Session
from app.services import models
from fastapi import HTTPException
from datetime import datetime, timedelta
from sqlalchemy import or_
from app.core.roles import Role
from app.auth import models as auth_models
from app.services.notifications import service as notif_service
from app.services.chats.service import close_chat, close_service_chats, get_or_create_conversation
from app.payments.services import capture_payment
import logging
from app.core.config import PAYMENT_DUE_MINUTES, AUTO_RELEASE_MINUTES

logger = logging.getLogger(__name__)


def accept_postulation(db: Session, request_id: str, current_user_id: str):
    postulation = db.query(models.ServiceRequest).filter(models.ServiceRequest.id == request_id).first()
    if not postulation:
        raise HTTPException(status_code=404, detail="La postulación no existe")

    service_entry = postulation.service

    if str(service_entry.client_id) != str(current_user_id):
        raise HTTPException(status_code=403, detail="No tienes permiso")

    if service_entry.status != models.JobStatus.OPEN:
        existing_job = db.query(models.Job).filter(models.Job.request_id == request_id).first()
        if existing_job:
            return {
                "status": "success",
                "message": "Ya aceptado previamente",
                "job_id": str(existing_job.id)
            }
        raise HTTPException(status_code=400, detail="Este servicio ya ha sido asignado a otro trabajador.")

    try:
        final_price = postulation.proposed_price if postulation.proposed_price else service_entry.base_price
        service_entry.status = models.JobStatus.MATCHED
        service_entry.base_price = final_price
        postulation.status = "accepted"

        new_job = models.Job(
            request_id=postulation.id,
            provider_id=postulation.worker_id,
            client_id=service_entry.client_id,
            status=models.JobStatus.MATCHED,
            final_price=final_price,
            started_at=datetime.utcnow(),
            payment_due_at=datetime.utcnow() + timedelta(minutes=PAYMENT_DUE_MINUTES)
        )

        db.add(new_job)
        db.commit()

        notif_service.notify_job_accepted(db, new_job, service_entry.title)
        notif_service.notify_client_payment_deadline(db, new_job, PAYMENT_DUE_MINUTES)

        close_service_chats(db, str(service_entry.id), models.ClosedReason.WORKER_NOT_SELECTED.value, exclude_request_id=str(postulation.id))

        try:
            convo = get_or_create_conversation(db, str(postulation.id), str(current_user_id))
            if convo and convo.status == models.ConversationStatus.CLOSED.value:
                from app.services.chats.service import reactivate_chat
                reactivate_chat(db, str(convo.id))
        except Exception:
            pass

        return {
            "status": "success",
            "message": "Aceptado correctamente",
            "job_id": str(new_job.id)
        }

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


def complete_job(db: Session, job_id: str, user_id: str):
    job = db.query(models.Job).join(models.ServiceRequest).filter(
        or_(
            models.Job.id == job_id,
            models.ServiceRequest.id == job_id,
            models.ServiceRequest.service_id == job_id
        ),
        models.Job.status.in_([models.JobStatus.MATCHED, models.JobStatus.WAITING_CONFIRMATION])
    ).first()

    if not job:
        raise HTTPException(status_code=404, detail="Trabajo no encontrado o ya finalizado")

    is_client = str(job.client_id) == str(user_id)
    is_worker = str(job.provider_id) == str(user_id)

    if not (is_client or is_worker):
        raise HTTPException(status_code=403, detail="No tienes permiso para modificar este trabajo")

    if is_worker:
        if job.status == models.JobStatus.WAITING_CONFIRMATION:
            return job

        has_dispute = False
        if job.request and job.request.conversation:
            has_dispute = job.request.conversation.status == models.ConversationStatus.DISPUTE.value

        job.status = models.JobStatus.WAITING_CONFIRMATION
        if not has_dispute:
            job.auto_release_at = datetime.utcnow() + timedelta(minutes=AUTO_RELEASE_MINUTES)
        else:
            job.auto_release_at = None
        if job.request and job.request.service:
            job.request.service.status = models.JobStatus.WAITING_CONFIRMATION

        db.commit()
        db.refresh(job)

        if not has_dispute:
            notif_service.notify_worker_confirmation_deadline(db, job, AUTO_RELEASE_MINUTES)

        return job

    elif is_client:
        job.status = models.JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        job.auto_release_at = None

        if job.request and job.request.service:
            job.request.service.status = models.JobStatus.COMPLETED
            job.request.service.is_active = False

        db.commit()
        db.refresh(job)

        try:
            capture_payment(db, str(job.id))
        except Exception as e:
            logger.warning(f"No se pudo liberar el pago automaticamente: {e}")

        notif_service.notify_job_completed(db, job)

        if job.request:
            try:
                convo = db.query(models.Conversation).filter(
                    models.Conversation.request_id == job.request.id
                ).first()
                if convo and convo.status != models.ConversationStatus.CLOSED.value:
                    close_chat(db, str(convo.id), models.ClosedReason.SERVICE_COMPLETED.value)
            except Exception:
                pass

        return job


def cancel_job(db: Session, job_id: str, user_id: str, user_role: str):
    job = db.query(models.Job).join(models.ServiceRequest).filter(
        or_(
            models.Job.id == job_id,
            models.ServiceRequest.service_id == job_id
        )
    ).first()

    if not job:
        raise HTTPException(status_code=404, detail="Trabajo no encontrado")

    is_worker = str(job.provider_id) == str(user_id)
    is_client = str(job.client_id) == str(user_id)
    is_admin = user_role == Role.ADMIN

    if not (is_worker or is_client or is_admin):
        raise HTTPException(status_code=403, detail="No tienes permiso para cancelar")

    job.status = models.JobStatus.CANCELLED

    if job.request:
        job.request.status = "expired"
        if job.request.service:
            if is_worker:
                job.request.service.status = models.JobStatus.OPEN
            else:
                job.request.service.status = models.JobStatus.CANCELLED

    db.commit()
    db.refresh(job)

    notif_service.notify_job_cancelled(db, job, user_id)

    if job.request and job.request.service:
        try:
            close_service_chats(db, str(job.request.service.id), models.ClosedReason.SERVICE_CANCELLED.value)
        except Exception:
            pass

    return job
