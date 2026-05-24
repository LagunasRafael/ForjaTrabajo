from sqlalchemy.orm import Session
from app.services import models, schemas
from uuid import UUID
from fastapi import HTTPException
from app.auth import models as auth_models
from app.services.notifications import service as notif_service
import logging

logger = logging.getLogger(__name__)

def create_service_request(db: Session, request_data: schemas.ServiceRequestCreate, worker_id: UUID):
    existing_request = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.service_id == str(request_data.service_id),
        models.ServiceRequest.worker_id == str(worker_id)
    ).first()

    if existing_request:
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

    # 🔔 Notificar al cliente sobre la nueva postulación (Migrado)
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
        return sorted(db_service.requests, key=lambda x: x.created_at or datetime.min, reverse=True)

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
        raise HTTPException(status_code=404, detail="Postulación no encontrada")

    postulation.description = description

    postulation.proposed_price = proposed_price

    db.commit()
    db.refresh(postulation)
    return postulation

def get_worker_applications(db: Session, worker_id: str):
    try:
        from app.services.models import Review
        from app.auth.models import User

        unique_results = {}

        jobs = db.query(models.Job).filter(models.Job.provider_id == worker_id).all()

        for job in jobs:
            req = job.request
            srv = req.service if req else None
            if not srv: continue

            existing_review = db.query(Review).filter(
                Review.job_id == job.id,
                Review.reviewer_id == worker_id
            ).first()
            already_reviewed = existing_review is not None

            # Verificar si el pago fue realizado
            from app.payments.models import Contract, Payment
            from app.payments.models import PaymentStatus as PaymentStatusEnum
            has_paid = False
            contract = db.query(Contract).filter(Contract.job_id == job.id).first()
            if contract:
                payment = db.query(Payment).filter(
                    Payment.contract_id == contract.id,
                    Payment.status.in_([
                        PaymentStatusEnum.HELD_IN_ESCROW,
                        PaymentStatusEnum.PENDING_TRANSFER,
                        PaymentStatusEnum.RELEASED,
                        PaymentStatusEnum.COMPLETED,
                    ])
                ).first()
                if payment:
                    has_paid = True

            if job.status in [models.JobStatus.COMPLETED, models.JobStatus.CANCELLED] and job.completed_at:
                fecha_buscada = job.completed_at.isoformat()
            else:
                fecha_buscada = job.started_at.isoformat() if job.started_at else None
            precio_mosca = req.proposed_price if req else srv.base_price
            service_id_str = str(srv.id)

            author_name = "Usuario Cliente"
            author_image_url = None
            client = db.query(User).filter(User.id == job.client_id).first()
            if client:
                author_name = client.full_name or "Usuario Cliente"
                author_image_url = client.profile_picture_url

            unique_results[service_id_str] = {
                "id": service_id_str,
                "request_id": str(req.id) if req else None,
                "title": srv.title,
                "description": srv.description,
                "base_price": float(precio_mosca) if precio_mosca else 0.0,
                "final_price": float(job.final_price) if job.final_price else None,
                "category_id": str(srv.category_id),
                "client_id": str(job.client_id),
                "latitude": srv.latitude,
                "longitude": srv.longitude,
                "exact_address": srv.exact_address,
                "status": job.status.value if hasattr(job.status, 'value') else str(job.status),
                "is_active": srv.is_active,
                "created_at": fecha_buscada,
                "image_urls": srv.image_urls if srv.image_urls else [],
                "already_reviewed": already_reviewed,
                "author_name": author_name,
                "author_image_url": author_image_url,
                "has_paid": has_paid,
                "payment_due_at": job.payment_due_at.isoformat() if job.payment_due_at else None,
                "auto_release_at": job.auto_release_at.isoformat() if job.auto_release_at else None,
            }

        # 2. BUSCAMOS LAS POSTULACIONES PENDIENTES
        postulations = db.query(models.ServiceRequest, models.Service).join(
            models.Service, models.ServiceRequest.service_id == models.Service.id
        ).filter(
            models.ServiceRequest.worker_id == worker_id,
            models.ServiceRequest.status == "pending",
            models.Service.is_active == True
        ).all()

        for req, srv in postulations:
            service_id_str = str(srv.id)
            if service_id_str not in unique_results:
                author_name = "Usuario Cliente"
                author_image_url = None
                client = db.query(User).filter(User.id == srv.client_id).first()
                if client:
                    author_name = client.full_name or "Usuario Cliente"
                    author_image_url = client.profile_picture_url

                unique_results[service_id_str] = {
                    "id": service_id_str,
                    "request_id": str(req.id),
                    "title": srv.title,
                    "description": req.description,
                    "base_price": float(req.proposed_price) if req.proposed_price else 0.0,
                    "category_id": str(srv.category_id),
                    "client_id": str(srv.client_id),
                    "latitude": srv.latitude,
                    "longitude": srv.longitude,
                    "exact_address": srv.exact_address,
                    "status": "open",
                    "is_active": srv.is_active,
                    "created_at": req.created_at.isoformat() if req.created_at else None,
                    "image_urls": srv.image_urls if srv.image_urls else [],
                    "already_reviewed": False,
                    "author_name": author_name,
                    "author_image_url": author_image_url,
                }
                
        # 🏁 ORDENAR POR FECHA DE CREACIÓN DESCENDENTE (Del más reciente al más antiguo)
        final_list = list(unique_results.values())
        final_list.sort(key=lambda x: x.get("created_at") or "", reverse=True)
        return final_list
        
    except Exception as e:
        logger.error(f"🚨 Error en get_worker_applications: {e}")
        raise e

def withdraw_postulation(db: Session, request_id: str, user_id: str):
    postulation = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.id == request_id,
        models.ServiceRequest.worker_id == user_id 
    ).first()

    if not postulation:
        raise HTTPException(status_code=404, detail="Postulación no encontrada o no tienes permiso")

    db.delete(postulation)
    db.commit()
    return {"message": "Postulación retirada con éxito"}