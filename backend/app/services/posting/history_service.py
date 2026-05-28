from sqlalchemy.orm import Session, joinedload
from app.services import models


def get_my_services(db: Session, user_id: str):
    from app.services.models import ServiceRequest, Job, Review
    from app.payments.models import Contract, Payment
    from app.payments.models import PaymentStatus as PaymentStatusEnum

    services = (
        db.query(models.Service)
        .options(
            joinedload(models.Service.owner),
            joinedload(models.Service.requests)
                .joinedload(ServiceRequest.job),
            joinedload(models.Service.requests)
                .joinedload(ServiceRequest.worker)
        )
        .filter(
            models.Service.client_id == user_id,
        )
        .all()
    )

    result = []
    for service_obj in services:
        already_reviewed = False
        has_paid = False
        relevant_date = service_obj.created_at

        for request in service_obj.requests:
            if request.job and request.job.status != models.JobStatus.CANCELLED:
                contract = db.query(Contract).filter(Contract.job_id == request.job.id).first()
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
            if request.job and request.job.status != models.JobStatus.CANCELLED:
                existing_review = db.query(Review).filter(
                    Review.job_id == request.job.id,
                    Review.reviewer_id == user_id
                ).first()
                if existing_review:
                    already_reviewed = True

            if request.job and service_obj.status != models.JobStatus.OPEN:
                if request.job.status in [models.JobStatus.COMPLETED, models.JobStatus.CANCELLED] and request.job.completed_at:
                    relevant_date = request.job.completed_at
                elif request.job.started_at:
                    relevant_date = request.job.started_at

        setattr(service_obj, 'already_reviewed', already_reviewed)
        setattr(service_obj, 'has_paid', has_paid)

        payment_due_at = None
        auto_release_at = None
        for request in service_obj.requests:
            if request.job and request.job.status != models.JobStatus.CANCELLED:
                payment_due_at = request.job.payment_due_at
                auto_release_at = request.job.auto_release_at
                break
        setattr(service_obj, 'payment_due_at', payment_due_at)
        setattr(service_obj, 'auto_release_at', auto_release_at)

        setattr(service_obj, 'relevant_date', relevant_date)
        result.append(service_obj)

    result.sort(key=lambda x: getattr(x, 'relevant_date', x.created_at) or x.created_at, reverse=True)
    return result


def build_my_services_response(db: Session, services: list) -> list:
    result = []
    for svc in services:
        final_price = None
        for request in svc.requests:
            if request.job and request.job.final_price:
                final_price = float(request.job.final_price)
                break

        pay_due = getattr(svc, 'payment_due_at', None)
        auto_rel = getattr(svc, 'auto_release_at', None)
        svc_dict = {
            "id": svc.id,
            "title": svc.title,
            "summary": svc.summary,
            "description": svc.description,
            "base_price": float(svc.base_price) if svc.base_price else 0.0,
            "final_price": final_price,
            "category_id": svc.category_id,
            "client_id": svc.client_id,
            "latitude": svc.latitude,
            "longitude": svc.longitude,
            "exact_address": svc.exact_address,
            "image_urls": svc.image_urls or [],
            "status": svc.status.value if hasattr(svc.status, 'value') else str(svc.status),
            "is_active": svc.is_active,
            "created_at": svc.created_at,
            "author_name": svc.author_name,
            "author_image_url": svc.author_image_url,
            "request_id": svc.request_id,
            "worker_name": svc.worker_name,
            "worker_image_url": svc.worker_image_url,
            "worker_id": getattr(svc, 'worker_id', None),
            "already_reviewed": getattr(svc, 'already_reviewed', False),
            "has_paid": getattr(svc, 'has_paid', False),
            "payment_due_at": pay_due.isoformat() + "Z" if pay_due else None,
            "auto_release_at": auto_rel.isoformat() + "Z" if auto_rel else None,
        }
        result.append(svc_dict)
    return result
