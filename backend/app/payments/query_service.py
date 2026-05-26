import logging
from sqlalchemy.orm import Session, joinedload
from . import models
from app.services.models import Job

logger = logging.getLogger(__name__)


def get_payment(db: Session, payment_id: str):
    return db.query(models.Payment).filter(models.Payment.id == payment_id).first()


def get_payments_by_role(db: Session, current_user):
    """Filtra el historial de pagos según el rol del usuario logueado."""
    base_query = db.query(models.Payment).options(
        joinedload(models.Payment.contract).joinedload(models.Contract.job)
    )

    if current_user.role == "admin":
        payments = base_query.all()
    elif current_user.role == "client":
        payments = base_query\
            .join(models.Contract)\
            .filter(models.Contract.client_id == current_user.id)\
            .all()
    elif current_user.role == "worker":
        payments = base_query\
            .join(models.Contract)\
            .filter(models.Contract.job.has(Job.provider_id == current_user.id))\
            .all()
    else:
        return []

    result = []
    for payment in payments:
        status_val = payment.status.value if hasattr(payment.status, 'value') else payment.status
        payment_dict = {
            "id": payment.id,
            "contract_id": payment.contract_id,
            "amount": payment.amount,
            "amount_cents": payment.amount_cents,
            "platform_fee": payment.platform_fee or 0.0,
            "status": status_val,
            "payment_method": payment.payment_method,
            "stripe_payment_intent_id": payment.stripe_payment_intent_id,
            "created_at": payment.created_at,
            "service_title": None,
            "service_description": None,
            "service_category": None,
        }
        contract = payment.contract
        if contract and contract.job:
            job = contract.job
            if job.request and job.request.service:
                svc = job.request.service
                payment_dict["service_title"] = svc.title
                payment_dict["service_description"] = svc.description
                payment_dict["service_category"] = svc.category.name if svc.category else None
        result.append(payment_dict)

    return result


def get_contracts_by_role(db: Session, current_user):
    """Obtiene contratos con la información del Job cargada."""
    query = db.query(models.Contract).options(joinedload(models.Contract.job))

    if current_user.role == "admin":
        return query.all()

    return query.filter(models.Contract.client_id == current_user.id).all()
