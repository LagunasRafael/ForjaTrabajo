from sqlalchemy.orm import Session
from app.services import models
import logging

logger = logging.getLogger(__name__)


def get_worker_applications(db: Session, worker_id: str):
    try:
        from app.services.models import Review
        from app.auth.models import User

        unique_results = {}

        jobs = db.query(models.Job).filter(models.Job.provider_id == worker_id).all()

        for job in jobs:
            req = job.request
            srv = req.service if req else None
            if not srv:
                continue
            if srv.is_deleted_by_worker:
                continue

            existing_review = db.query(Review).filter(
                Review.job_id == job.id,
                Review.reviewer_id == worker_id
            ).first()
            already_reviewed = existing_review is not None

            from app.payments.models import Contract, Payment
            from app.payments.models import PaymentStatus as PaymentStatusEnum
            from app.payments.transfer_service import _get_stripe_fee_cents
            has_paid = False
            platform_fee = 0.0
            stripe_fee = 0.0
            net_payout = 0.0
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
                    platform_fee = float(payment.platform_fee) if payment.platform_fee else 0.0
                    stripe_fee_cents = _get_stripe_fee_cents(payment)
                    stripe_fee = float(stripe_fee_cents / 100)
                    transfer_cents = payment.amount_cents - (payment.platform_fee_cents or 0) - stripe_fee_cents
                    if transfer_cents < 0:
                        transfer_cents = 0
                    net_payout = float(transfer_cents / 100)

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
                "platform_fee": platform_fee,
                "stripe_fee": stripe_fee,
                "net_payout": net_payout,
                "payment_due_at": (job.payment_due_at.isoformat() + "Z") if job.payment_due_at else None,
                "auto_release_at": (job.auto_release_at.isoformat() + "Z") if job.auto_release_at else None,
            }

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

        final_list = list(unique_results.values())
        final_list.sort(key=lambda x: x.get("created_at") or "", reverse=True)
        return final_list

    except Exception as e:
        logger.error(f"Error en get_worker_applications: {e}")
        raise e
