from sqlalchemy.orm import Session
from app.services import models
from fastapi import HTTPException
from app.core.roles import Role
from app.services.notifications import service as notif_service
from app.services.chats.service import close_service_chats
from app.payments.models import Payment, Contract, PaymentStatus
import stripe
from app.services import schemas
import logging

logger = logging.getLogger(__name__)


def update_service(db: Session, service_id: str, data: schemas.ServiceUpdate, user_id: str, user_role: str):
    service_entry = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service_entry:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    is_admin = user_role == Role.ADMIN
    is_owner = str(service_entry.client_id) == str(user_id)

    if not (is_admin or is_owner):
        raise HTTPException(status_code=403, detail="No tienes permiso")

    if service_entry.status != models.JobStatus.OPEN:
        raise HTTPException(status_code=400, detail="No puedes editar un servicio que ya fue tomado o finalizado")

    if data.category_id is not None:
        category = db.query(models.Category).filter(models.Category.id == str(data.category_id)).first()
        if not category:
            raise HTTPException(status_code=400, detail="La categoria no existe")
        service_entry.category_id = data.category_id

    fields = ["title", "summary", "description", "base_price", "latitude", "longitude", "exact_address", "image_urls"]
    for field in fields:
        value = getattr(data, field, None)
        if value is not None:
            setattr(service_entry, field, value)

    db.commit()
    db.refresh(service_entry)
    return service_entry


def cancel_service(db: Session, service_id: str, user_id: str, user_role: str):
    service_entry = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service_entry:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    is_admin = user_role == Role.ADMIN
    is_owner = service_entry.client_id == str(user_id)
    is_assigned_worker = False
    active_job = None

    if service_entry.status == models.JobStatus.MATCHED:
        active_job = db.query(models.Job).join(models.ServiceRequest).filter(
            models.ServiceRequest.service_id == service_entry.id,
            models.Job.status == models.JobStatus.MATCHED
        ).first()
        if active_job and str(active_job.provider_id) == str(user_id):
            is_assigned_worker = True

    if not (is_owner or is_admin or is_assigned_worker):
        raise HTTPException(status_code=403, detail="No tienes permiso para cancelar")

    if active_job:
        contract = db.query(Contract).filter(Contract.job_id == active_job.id).first()
        if contract:
            payments = db.query(Payment).filter(
                Payment.contract_id == contract.id,
                Payment.status.in_([PaymentStatus.PENDING, PaymentStatus.HELD_IN_ESCROW])
            ).all()
            for payment in payments:
                if payment.stripe_payment_intent_id:
                    try:
                        intent = stripe.PaymentIntent.retrieve(payment.stripe_payment_intent_id)
                        if intent.status in ("requires_payment_method", "requires_confirmation", "requires_capture"):
                            stripe.PaymentIntent.cancel(payment.stripe_payment_intent_id)
                    except Exception:
                        pass
                payment.status = PaymentStatus.FAILED

    active_requests = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.service_id == service_id,
        models.ServiceRequest.status.in_(["pending", "accepted"])
    ).all()
    for req in active_requests:
        req.status = "expired"

    try:
        close_service_chats(db, service_id, models.ClosedReason.SERVICE_CANCELLED.value)
    except Exception as e:
        logger.warning(f"No se pudieron cerrar los chats del servicio: {e}")

    service_entry.status = models.JobStatus.CANCELLED
    if active_job:
        active_job.status = models.JobStatus.CANCELLED

    db.commit()
    db.refresh(service_entry)

    if active_job:
        notif_service.notify_job_cancelled(db, active_job, user_id)

    return {"message": "Servicio cancelado correctamente", "status": "cancelled"}


def delete_service(db: Session, service_id: str):
    service_entry = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service_entry:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    # Soft-delete: marcar como inactivo y cancelado sin borrar datos
    service_entry.is_active = False
    service_entry.status = models.JobStatus.CANCELLED

    # Cerrar conversaciones activas
    try:
        close_service_chats(db, service_id, models.ClosedReason.SERVICE_CANCELLED.value)
    except Exception as e:
        logger.warning(f"No se pudieron cerrar los chats del servicio: {e}")

    # Marcar postulaciones activas como expiradas
    active_requests = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.service_id == service_id,
        models.ServiceRequest.status.in_(["pending", "accepted"])
    ).all()
    for req in active_requests:
        req.status = "expired"

    # Cancelar job activo si existe
    job = db.query(models.Job).join(models.ServiceRequest).filter(
        models.ServiceRequest.service_id == service_id,
        models.Job.status != models.JobStatus.CANCELLED
    ).first()
    if job:
        job.status = models.JobStatus.CANCELLED

    db.commit()
    db.refresh(service_entry)
    return {"message": "Servicio cancelado correctamente"}


def hide_from_history(db: Session, service_id: str, user_id: str):
    svc = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not svc:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    if str(svc.client_id) == user_id:
        svc.is_deleted_by_client = True
    else:
        svc.is_deleted_by_worker = True
    db.commit()
    return {"status": "success", "message": "Eliminado del historial"}


def toggle_service_active(db: Session, service_id: str, is_active: bool):
    db_service = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not db_service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")
    db_service.is_active = is_active
    db.commit()
    db.refresh(db_service)
    return db_service


def get_reported_services(db: Session):
    from sqlalchemy import func
    from app.services.models import Report, ReportStatus, Category

    services = db.query(models.Service).filter(
        models.Service.is_reported == True,
        models.Service.is_active == True
    ).all()

    result = []
    for svc in services:
        from app.auth import models as auth_models

        report_count = db.query(Report).filter(
            Report.reported_service_id == svc.id,
            Report.status == ReportStatus.PENDING
        ).count()

        owner = db.query(auth_models.User).filter(auth_models.User.id == svc.client_id).first()
        category = db.query(Category).filter(Category.id == svc.category_id).first()

        result.append({
            "id": svc.id,
            "title": svc.title,
            "description": svc.description[:100] if svc.description else "",
            "owner_name": owner.full_name if owner else "Usuario",
            "category_name": category.name if category else "Sin categoria",
            "is_active": svc.is_active,
            "created_at": svc.created_at.isoformat() if svc.created_at else None,
            "report_count": report_count,
        })

    return result
