from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.db.database import get_db
from app.services import schemas
from app.services.expiration import process_expired_payments
from app.services.posting.query_service import get_services, get_service_by_id, get_services_by_category, search_services

router = APIRouter()


@router.get("/", response_model=List[schemas.Service])
def list_services(
    skip: int = 0,
    limit: int = 100,
    include_inactive: bool = False,
    category_id: Optional[str] = Query(None, description="Filtrar por categoria"),
    query: Optional[str] = Query(None, description="Buscar por texto en titulo o descripcion"),
    latitude: Optional[float] = Query(None, description="Latitud del usuario para filtro por distancia"),
    longitude: Optional[float] = Query(None, description="Longitud del usuario para filtro por distancia"),
    radius_km: Optional[float] = Query(None, description="Radio de busqueda en km"),
    db: Session = Depends(get_db),
):
    return get_services(
        db, skip=skip, limit=limit, include_inactive=include_inactive,
        category_id=category_id, query=query,
        latitude=latitude, longitude=longitude, radius_km=radius_km,
    )


@router.get("/search", response_model=List[schemas.Service])
def search_services_route(query: str, db: Session = Depends(get_db)):
    return search_services(db, query)


@router.get("/category/{category_id}", response_model=List[schemas.Service])
def services_by_category(category_id: str, db: Session = Depends(get_db)):
    return get_services_by_category(db, category_id)


@router.get("/{service_id}", response_model=schemas.Service)
def read_service(service_id: str, db: Session = Depends(get_db)):
    process_expired_payments(db)
    db_service = get_service_by_id(db, service_id=service_id)
    if db_service is None:
        raise HTTPException(status_code=404, detail="El servicio no existe")
    return db_service
