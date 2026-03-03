from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.auth.security import check_role
from app.core.roles import Role
from app.settings import models, schemas

router = APIRouter()

def get_config(db: Session):
    config = db.query(models.SiteConfig).first()
    if not config:
        config = models.SiteConfig()
        db.add(config)
        db.commit()
        db.refresh(config)
    return config

@router.get("/", response_model=schemas.SiteConfigResponse)
def read_site_config(db: Session = Depends(get_db)):
    """Obtener la configuración global del sitio."""
    return get_config(db)

@router.put("/", response_model=schemas.SiteConfigResponse)
def update_site_config(
    config_update: schemas.SiteConfigUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(check_role([Role.ADMIN]))
):
    """Actualizar la configuración global del sitio (solo ADMIN)."""
    db_config = get_config(db)
    
    update_data = config_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_config, key, value)
        
    db.commit()
    db.refresh(db_config)
    return db_config
