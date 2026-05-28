from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, extract
from datetime import datetime, timedelta
from app.db.database import get_db
from app.auth.security import get_current_user
from app.auth import models as auth_models
from app.payments import models as payment_models
from app.services.models import Job, ServiceRequest
from pydantic import BaseModel

router = APIRouter()


def _get_user_name(db: Session, user_id: str) -> str:
    user = db.query(auth_models.User).filter(auth_models.User.id == user_id).first()
    return user.full_name if user else "N/A"


def _get_user_stripe_account_id(db: Session, user_id: str) -> str:
    user = db.query(auth_models.User).filter(auth_models.User.id == user_id).first()
    return user.stripe_account_id if user else ""


class FinanceOverview(BaseModel):
    gmv_total: float
    platform_revenue: float
    escrow_held: float
    pending_transfers: float
    refunded_total: float
    total_transactions: int
    average_ticket: float
    commission_rate: float
    payments_by_status: dict


class PaymentListItem(BaseModel):
    id: str
    service_title: str
    client_name: str
    worker_name: str
    amount: float
    platform_fee: float
    status: str
    created_at: datetime


class AnalyticsPoint(BaseModel):
    date: str
    gmv: float
    platform_fee: float


class EscrowItem(BaseModel):
    payment_id: str
    service_title: str
    amount: float
    status: str
    created_at: datetime
    worker_name: str
    worker_has_stripe: bool
    job_status: Optional[str] = None


@router.get("/overview", response_model=FinanceOverview)
def get_finance_overview(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="No tienes permiso")

    payments = db.query(payment_models.Payment).all()
    
    gmv_total = sum(p.amount for p in payments if p.status not in [payment_models.PaymentStatus.FAILED])
    platform_revenue = sum(p.platform_fee or 0 for p in payments if p.status in [
        payment_models.PaymentStatus.RELEASED, 
        payment_models.PaymentStatus.COMPLETED
    ])
    escrow_held = sum(p.amount for p in payments if p.status == payment_models.PaymentStatus.HELD_IN_ESCROW)
    pending_transfers = sum(p.amount for p in payments if p.status == payment_models.PaymentStatus.PENDING_TRANSFER)
    refunded_total = sum(p.amount for p in payments if p.status == payment_models.PaymentStatus.REFUNDED)
    
    completed_payments = [p for p in payments if p.status in [
        payment_models.PaymentStatus.RELEASED, 
        payment_models.PaymentStatus.COMPLETED
    ]]
    average_ticket = sum(p.amount for p in completed_payments) / len(completed_payments) if completed_payments else 0
    
    try:
        from app.settings.models import SiteConfig
        config = db.query(SiteConfig).first()
        commission_rate = config.commission_rate if config and config.commission_rate is not None else 10.0
    except Exception:
        commission_rate = 10.0

    payments_by_status = {}
    for p in payments:
        status_val = p.status.value if hasattr(p.status, 'value') else p.status
        payments_by_status[status_val] = payments_by_status.get(status_val, 0) + 1

    return FinanceOverview(
        gmv_total=gmv_total,
        platform_revenue=platform_revenue,
        escrow_held=escrow_held,
        pending_transfers=pending_transfers,
        refunded_total=refunded_total,
        total_transactions=len(payments),
        average_ticket=average_ticket,
        commission_rate=commission_rate,
        payments_by_status=payments_by_status
    )


@router.get("/payments", response_model=List[PaymentListItem])
def get_admin_payments(
    status: Optional[str] = Query(None),
    date_from: Optional[str] = Query(None),
    date_to: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="No tienes permiso")

    query = db.query(payment_models.Payment).options(
        joinedload(payment_models.Payment.contract)
        .joinedload(payment_models.Contract.job)
    )

    if status:
        query = query.filter(payment_models.Payment.status == status)
    
    if date_from:
        query = query.filter(payment_models.Payment.created_at >= datetime.fromisoformat(date_from))
    
    if date_to:
        query = query.filter(payment_models.Payment.created_at <= datetime.fromisoformat(date_to))

    payments = query.all()
    
    if search:
        search_lower = search.lower()
        filtered = []
        for p in payments:
            contract = p.contract
            job = contract.job if contract else None
            service_title = ""
            if job and job.request and job.request.service:
                service_title = job.request.service.title or ""
            
            client_name = _get_user_name(db, contract.client_id) if contract else ""
            worker_name = _get_user_name(db, job.provider_id) if job else ""
            
            if (search_lower in p.id.lower() or 
                search_lower in service_title.lower() or
                search_lower in client_name.lower() or
                search_lower in worker_name.lower()):
                filtered.append(p)
        payments = filtered

    payments = payments[skip:skip + limit]

    result = []
    for p in payments:
        contract = p.contract
        job = contract.job if contract else None
        
        service_title = ""
        if job and job.request and job.request.service:
            service_title = job.request.service.title or ""
        
        client_name = _get_user_name(db, contract.client_id) if contract else "N/A"
        worker_name = _get_user_name(db, job.provider_id) if job else "N/A"
        
        status_val = p.status.value if hasattr(p.status, 'value') else p.status
        
        result.append(PaymentListItem(
            id=p.id,
            service_title=service_title or "Servicio",
            client_name=client_name,
            worker_name=worker_name,
            amount=p.amount,
            platform_fee=p.platform_fee or 0,
            status=status_val,
            created_at=p.created_at
        ))

    return result


@router.get("/analytics", response_model=List[AnalyticsPoint])
def get_finance_analytics(
    days: int = Query(30, ge=1, le=90),
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="No tienes permiso")

    cutoff_date = datetime.utcnow() - timedelta(days=days)
    
    payments = db.query(payment_models.Payment).filter(
        payment_models.Payment.created_at >= cutoff_date
    ).all()

    daily_data = {}
    for p in payments:
        date_key = p.created_at.strftime("%Y-%m-%d")
        if date_key not in daily_data:
            daily_data[date_key] = {"gmv": 0.0, "platform_fee": 0.0}
        
        if p.status != payment_models.PaymentStatus.FAILED:
            daily_data[date_key]["gmv"] += p.amount
            if p.status in [payment_models.PaymentStatus.RELEASED, payment_models.PaymentStatus.COMPLETED]:
                daily_data[date_key]["platform_fee"] += p.platform_fee or 0

    result = []
    for d in range(days):
        date = (datetime.utcnow() - timedelta(days=days - 1 - d)).strftime("%Y-%m-%d")
        result.append(AnalyticsPoint(
            date=date,
            gmv=round(daily_data.get(date, {}).get("gmv", 0.0), 2),
            platform_fee=round(daily_data.get(date, {}).get("platform_fee", 0.0), 2)
        ))

    return result


@router.get("/escrow", response_model=List[EscrowItem])
def get_escrow_monitor(
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="No tienes permiso")

    payments = db.query(payment_models.Payment).options(
        joinedload(payment_models.Payment.contract)
        .joinedload(payment_models.Contract.job)
    ).filter(
        payment_models.Payment.status.in_([
            payment_models.PaymentStatus.HELD_IN_ESCROW,
            payment_models.PaymentStatus.PENDING_TRANSFER
        ])
    ).all()

    result = []
    for p in payments:
        contract = p.contract
        job = contract.job if contract else None
        
        service_title = ""
        if job and job.request and job.request.service:
            service_title = job.request.service.title or ""
        
        worker_name = _get_user_name(db, job.provider_id) if job else "N/A"
        worker_has_stripe = bool(_get_user_stripe_account_id(db, job.provider_id)) if job else False
        
        status_val = p.status.value if hasattr(p.status, 'value') else p.status
        job_status_val = job.status.value if (job and hasattr(job.status, 'value')) else (job.status if job else None)
        
        result.append(EscrowItem(
            payment_id=p.id,
            service_title=service_title or "Servicio",
            amount=p.amount,
            status=status_val,
            created_at=p.created_at,
            worker_name=worker_name,
            worker_has_stripe=worker_has_stripe,
            job_status=job_status_val
        ))

    return result


@router.post("/process-pending-transfer/{payment_id}")
def process_pending_transfer(
    payment_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="No tienes permiso")

    payment = db.query(payment_models.Payment).filter(
        payment_models.Payment.id == payment_id
    ).first()
    
    if not payment:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    
    if payment.status != payment_models.PaymentStatus.PENDING_TRANSFER:
        raise HTTPException(status_code=400, detail="El pago no está pendiente de transferencia")

    import app.payments.services as payment_service
    contract = payment.contract
    if not contract or not contract.job:
        raise HTTPException(status_code=400, detail="Contrato o job no encontrado")
    
    job = contract.job
    payment_service._transfer_to_worker(db, job, payment)
    db.commit()

    return {"status": "success", "message": "Transferencia procesada"}


@router.post("/refund/{payment_id}")
def admin_refund_payment(
    payment_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="No tienes permiso")

    import app.payments.services as payment_service
    return payment_service.refund_payment(db, payment_id)


@router.post("/release/{payment_id}")
def admin_release_payment(
    payment_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="No tienes permiso")

    import app.payments.services as payment_service
    payment = db.query(payment_models.Payment).filter(
        payment_models.Payment.id == payment_id
    ).first()
    
    if not payment:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    
    contract = payment.contract
    if not contract or not contract.job:
        raise HTTPException(status_code=400, detail="Contrato o job no encontrado")
    
    job = contract.job
    return payment_service.capture_payment(db, job.id)


class CommissionUpdateRequest(BaseModel):
    commission_rate: float


@router.put("/config")
def update_commission_rate(
    request: CommissionUpdateRequest,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="No tienes permiso")

    if request.commission_rate < 0 or request.commission_rate > 100:
        raise HTTPException(status_code=400, detail="La comisión debe estar entre 0 y 100")

    from app.settings.models import SiteConfig

    config = db.query(SiteConfig).first()
    if not config:
        config = SiteConfig(commission_rate=request.commission_rate)
        db.add(config)
    else:
        config.commission_rate = request.commission_rate

    db.commit()
    return {"status": "success", "commission_rate": config.commission_rate}
