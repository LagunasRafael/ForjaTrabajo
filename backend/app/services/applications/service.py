from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.services import models, schemas
from uuid import UUID
from app.services.chats.service import close_chat
from app.auth import models as auth_models
from app.services.notifications import service as notif_service
from datetime import datetime
import logging

from app.services.applications.worker_service import get_worker_applications

logger = logging.getLogger(__name__)


def create_service_request(db: Session, request_data: schemas.ServiceRequestCreate, worker_id: UUID):
    existing_request = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.service_id == str(request_data.service_id),
        models.ServiceRequest.worker_id == str(worker_id),
        models.ServiceRequest.status.in_(["pending", "accepted"])
    ).first()

    if existing_request:
        if existing_request.status == "accepted":
            raise HTTPException(status_code=400, detail="Ya fuiste aceptado para este trabajo.")
        service = db.query(models.Service).filter(
            models.Service.id == str(request_data.service_id)
        ).first()
        if service and service.status == models.JobStatus.OPEN:
            existing_request.description = request_data.description
            existing_request.proposed_price = request_data.proposed_price
            db.commit()
            return existing_request
        raise HTTPException(status_code=400, detail="Ya enviaste una propuesta a este trabajo.")

    worker = db.query(auth_models.User).filter(auth_models.User.id == str(worker_id)).first()
    if not worker or not worker.stripe_account_id:
        raise HTTPException(
            status_code=400,
            detail="Debes configurar tu billetera (Stripe) antes de postularte. "
                   "Ve a \"Mi Billetera\" en tu perfil para configurarla."
        )

    db_request = models.ServiceRequest(
        service_id=str(request_data.service_id),
        description=request_data.description,
        proposed_price=request_data.proposed_price,
        worker_id=str(worker_id),
        status="pending"
    )
    db.add(db_request)
    db.commit()
    db.refresh(db_request)

    service_entry = db.query(models.Service).filter(models.Service.id == str(request_data.service_id)).first()
    worker = db.query(auth_models.User).filter(auth_models.User.id == str(worker_id)).first()
    if worker and service_entry:
        notif_service.notify_new_application(db, service_entry, worker)

    return db_request


def get_offers_by_service(db: Session, service_id: str, client_id: str, is_admin: bool = False):
    from sqlalchemy.orm import joinedload
    from datetime import datetime
    db_service = db.query(models.Service)\
        .options(joinedload(models.Service.requests).joinedload(models.ServiceRequest.worker))\
        .filter(models.Service.id == service_id).first()
    if not db_service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    if is_admin or str(db_service.client_id) == str(client_id):
        active_requests = [
            req for req in db_service.requests
            if req.status not in ["expired", "rejected"]
        ]
        return sorted(active_requests, key=lambda x: x.created_at or datetime.min, reverse=True)

    my_requests = [
        req for req in db_service.requests
        if str(req.worker_id) == str(client_id)
    ]
    return sorted(my_requests, key=lambda x: x.created_at or datetime.min, reverse=True)


def update_service_request(db: Session, request_id: str, description: str, proposed_price: float):
    postulation = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.id == request_id
    ).first()

    if not postulation:
        raise HTTPException(status_code=404, detail="Postulacion no encontrada")

    postulation.description = description
    postulation.proposed_price = proposed_price

    db.commit()
    db.refresh(postulation)
    return postulation


def withdraw_postulation(db: Session, request_id: str, user_id: str):
    postulation = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.id == request_id,
        models.ServiceRequest.worker_id == user_id
    ).first()

    if not postulation:
        raise HTTPException(status_code=404, detail="Postulacion no encontrada o no tienes permiso")

    try:
        convo = db.query(models.Conversation).filter(
            models.Conversation.request_id == request_id
        ).first()
        if convo and convo.status != models.ConversationStatus.CLOSED.value:
            close_chat(db, str(convo.id), models.ClosedReason.APPLICATION_WITHDRAWN.value)
    except Exception:
        pass

    db.delete(postulation)
    db.commit()
    return {"message": "Postulacion retirada con exito"}
