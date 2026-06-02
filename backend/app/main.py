import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import SQLAlchemyError
from slowapi import _rate_limit_exceeded_handler
from slowapi.middleware import SlowAPIMiddleware
from slowapi.errors import RateLimitExceeded
from dotenv import load_dotenv

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
Base.metadata.create_all(bind=engine)
print("Tablas creadas/verificadas con create_all.", flush=True)

app = FastAPI(
    title="Forja Trabajo API",
    version="1.0.0"
)


from app.core.config import CORS_ORIGINS

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.core.rate_limit import limiter

# Rate Limiting (Proteccion contra fuerza bruta y SPAM)
app.state.limiter = limiter # type: ignore
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)  # type: ignore[arg-type]
app.add_middleware(SlowAPIMiddleware)

# --- MANEJADORES GLOBALES DE ERRORES ---

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error("Error inesperado no manejado: %s", exc, exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Ocurrio un error interno en el servidor. Intenta mas tarde."},
    )

@app.exception_handler(SQLAlchemyError)
async def sqlalchemy_exception_handler(request: Request, exc: SQLAlchemyError):
    error_msg = str(exc)
    logger.error("Error de Base de Datos: %s", error_msg, exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": f"Error en la operacion de base de datos: {error_msg}"},
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = [{"campo": err["loc"][-1], "mensaje": err["msg"]} for err in exc.errors()]
    logger.error("Error de Validacion (422): %s", errors)
    return JSONResponse(
        status_code=422,
        content={"detail": "Datos de entrada invalidos", "errores": errors},
    )

# Scheduler automático (APScheduler)
from app.services.scheduler import start_scheduler, stop_scheduler

@app.on_event("startup")
def on_startup():
    # Crear tablas (solo corre en el worker, no en el reloader padre)
    logger.info("Tablas listas para crear: %s", Base.metadata.tables.keys())
    Base.metadata.create_all(bind=engine)
    logger.info("Tablas creadas/verificadas con create_all.")

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