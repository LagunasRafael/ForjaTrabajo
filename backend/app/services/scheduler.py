import logging
import os
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger
from app.db.database import SessionLocal
from app.core.config import ENABLE_SCHEDULER, SCHEDULER_INTERVAL_MINUTES

logger = logging.getLogger(__name__)

scheduler = BackgroundScheduler()


def check_expirations_job():
    db = SessionLocal()
    try:
        from app.services.expiration import process_expired_payments
        results = process_expired_payments(db)
        if results["cancelled"] > 0 or results["auto_released"] > 0:
            logger.info(f"Scheduler: {results}")
    except Exception as e:
        logger.error(f"Error en scheduler check_expirations: {e}", exc_info=True)
    finally:
        db.close()


def start_scheduler():
    if not ENABLE_SCHEDULER:
        logger.info("APScheduler desactivado por config (ENABLE_SCHEDULER=false)")
        return

    if scheduler.get_job("check_expirations"):
        return

    # En multi-worker (gunicorn -w N), solo el primer worker ejecuta el scheduler
    # para evitar duplicados. Usa ENABLE_SCHEDULER=false con cron externo en ese caso.
    scheduler.add_job(
        check_expirations_job,
        IntervalTrigger(minutes=SCHEDULER_INTERVAL_MINUTES),
        id="check_expirations",
        name="Verificar pagos expirados y auto-liberar",
        replace_existing=True,
    )
    scheduler.start()
    logger.info(
        f"APScheduler iniciado — check_expirations cada {SCHEDULER_INTERVAL_MINUTES} minuto(s)"
    )


def stop_scheduler():
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("APScheduler detenido")
