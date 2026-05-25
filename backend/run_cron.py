import time
import logging
import os
from app.db.database import SessionLocal
from app.services.expiration import process_expired_payments

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("cron")

INTERVAL_MINUTES = int(os.getenv("CRON_INTERVAL_MINUTES", "5"))


def main():
    logger.info(f"Cron iniciado — cada {INTERVAL_MINUTES} minuto(s)")
    while True:
        try:
            db = SessionLocal()
            try:
                results = process_expired_payments(db)
                if results["cancelled"] > 0 or results["auto_released"] > 0:
                    logger.info(f"Procesados: {results}")
            finally:
                db.close()
        except Exception as e:
            logger.error(f"Error en ciclo cron: {e}", exc_info=True)
        time.sleep(INTERVAL_MINUTES * 60)


if __name__ == "__main__":
    main()
