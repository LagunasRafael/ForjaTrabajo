import logging
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

COMMISSION_RATE = 0.05


def get_commission_rate(db: Session) -> float:
    try:
        from app.settings.models import SiteConfig
        config = db.query(SiteConfig).first()
        if config and config.commission_rate is not None:
            return config.commission_rate / 100.0
    except Exception as e:
        logger.warning("No se pudo obtener commission_rate desde DB, usando default: %s", e)
    return COMMISSION_RATE
