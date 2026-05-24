from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import SQLAlchemyError
from slowapi import _rate_limit_exceeded_handler
from slowapi.middleware import SlowAPIMiddleware
from slowapi.errors import RateLimitExceeded
import logging
import os
from dotenv import load_dotenv
from pathlib import Path

# Cargar variables de entorno desde .env (ruta absoluta)
load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env")

from app.routers import router

from app.db.database import Base, engine
from app.auth.models import User
from app.services.models import Service
from app.payments.models import Payment
from app.settings.models import SiteConfig


# Crear tablas
print("📋 Tablas listas para crear:", Base.metadata.tables.keys(), flush=True)

from sqlalchemy import text
try:
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS reports CASCADE"))
        conn.commit()
        print("Tabla reports eliminada para recrear desde modelo.", flush=True)
except Exception as e:
    print(f"Aviso (no critico): {e}", flush=True)

Base.metadata.create_all(bind=engine)
print("Tablas creadas/verificadas con create_all.", flush=True)

def _migrate():
    migs = [
        ("is_banned en users", "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE"),
        ("work_started_at en jobs", "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS work_started_at DATETIME"),
        ("is_deleted_by_client en services", "ALTER TABLE services ADD COLUMN is_deleted_by_client BOOLEAN DEFAULT FALSE"),
        ("is_deleted_by_worker en services", "ALTER TABLE services ADD COLUMN is_deleted_by_worker BOOLEAN DEFAULT FALSE"),
        ("closed_reason en conversations", "ALTER TABLE conversations ADD COLUMN closed_reason VARCHAR(50)"),
        ("reopened_at en conversations", "ALTER TABLE conversations ADD COLUMN reopened_at DATETIME"),
        ("bio en users", "ALTER TABLE users ADD COLUMN IF NOT EXISTS bio VARCHAR(400) DEFAULT NULL"),
    ]
    try:
        with engine.connect() as conn:
            for name, sql in migs:
                try:
                    conn.execute(text(sql))
                    conn.commit()
                    print(f"Migracion ok: {name}", flush=True)
                except Exception as e:
                    conn.rollback()
                    print(f"Migracion fallo ({name}): {e}", flush=True)
    except Exception as e:
        print(f"Error conectando para migracion: {e}", flush=True)
_migrate()

app = FastAPI(
    title="Forja Trabajo API",
    version="1.0.0"
)


from app.core.config import CORS_ORIGINS

# 🔥 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.core.rate_limit import limiter

# 🚦 Rate Limiting (Protección contra fuerza bruta y SPAM)
app.state.limiter = limiter # type: ignore
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)  # type: ignore[arg-type]
app.add_middleware(SlowAPIMiddleware)

# Configuración del Logger
logging.basicConfig(level=logging.ERROR)
logger = logging.getLogger(__name__)

# --- MANEJADORES GLOBALES DE ERRORES ---

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"❌ Error inesperado no manejado: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Ocurrió un error interno en el servidor. Intenta más tarde."},
    )

@app.exception_handler(SQLAlchemyError)
async def sqlalchemy_exception_handler(request: Request, exc: SQLAlchemyError):
    error_msg = str(exc)
    logger.error(f"🛢️ Error de Base de Datos: {error_msg}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": f"Error en la operación de base de datos: {error_msg}"},
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    # Simplificamos los errores para el cliente
    errors = [{"campo": err["loc"][-1], "mensaje": err["msg"]} for err in exc.errors()]
    logger.error(f"⚠️ Error de Validación (422): {errors}")
    return JSONResponse(
        status_code=422,
        content={"detail": "Datos de entrada inválidos", "errores": errors},
    )

# Scheduler automático (APScheduler)
from app.services.scheduler import start_scheduler, stop_scheduler

@app.on_event("startup")
def on_startup():
    start_scheduler()

@app.on_event("shutdown")
def on_shutdown():
    stop_scheduler()

# Routers
app.include_router(router)


@app.get("/")
def root():
    return {"message": "Forja Trabajo API funcionando"}


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "version": "1.0.0",
    }