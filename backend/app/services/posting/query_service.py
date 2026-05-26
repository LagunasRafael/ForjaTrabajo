import math
from typing import Optional
from sqlalchemy.orm import Session, joinedload
from app.services import models


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * \
        math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def get_services(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    include_inactive: bool = False,
    category_id: Optional[str] = None,
    query: Optional[str] = None,
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    radius_km: Optional[float] = None,
):
    q = db.query(models.Service).options(joinedload(models.Service.owner))

    if not include_inactive:
        q = q.filter(
            models.Service.is_active == True,
            models.Service.status == models.JobStatus.OPEN
        )

    if category_id is not None:
        q = q.filter(models.Service.category_id == category_id)

    if query is not None and query.strip():
        search_term = f"%{query.strip().lower()}%"
        q = q.filter(
            (models.Service.title.ilike(search_term)) |
            (models.Service.description.ilike(search_term))
        )

    results = (
        q
        .order_by(models.Service.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    if latitude is not None and longitude is not None and radius_km is not None:
        results = [
            s for s in results
            if s.latitude is not None and s.longitude is not None
            and _haversine_km(latitude, longitude, float(s.latitude), float(s.longitude)) <= radius_km
        ]

    return results


def get_service_by_id(db: Session, service_id: str):
    srv = (
        db.query(models.Service)
        .options(joinedload(models.Service.owner))
        .filter(models.Service.id == service_id)
        .first()
    )
    if srv:
        return srv

    from app.services.models import Job
    job = db.query(Job).filter(Job.id == service_id).first()
    if job and job.request and job.request.service:
        return job.request.service

    return None


def get_services_by_category(db: Session, category_id: str):
    return (
        db.query(models.Service)
        .filter(
            models.Service.category_id == category_id,
            models.Service.is_active == True,
            models.Service.status == models.JobStatus.OPEN
        )
        .all()
    )


def search_services(db: Session, search_query: str):
    query_clean = search_query.strip().lower()
    search_term = f"%{query_clean}%"
    return (
        db.query(models.Service)
        .filter(
            (models.Service.title.ilike(search_term)) |
            (models.Service.description.ilike(search_term))
        )
        .filter(models.Service.status == models.JobStatus.OPEN)
        .all()
    )
