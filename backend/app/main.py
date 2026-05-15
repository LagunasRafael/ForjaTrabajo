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

# Cargar variables de entorno desde .env
load_dotenv()

from app.routers import router

from app.db.database import Base, engine
from app.auth.models import User
from app.services.models import Service
from app.payments.models import Payment
from app.settings.models import SiteConfig


# Crear tablas
print("📋 Tablas listas para crear:", Base.metadata.tables.keys())
Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="Forja Trabajo API",
    version="1.0.0"
)


# 🔥 CORS - Desarrollo (Flutter Web cambia puerto dinámicamente)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción cambia "*" por tu URL de Flutter
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.core.rate_limit import limiter

# 🚦 Rate Limiting (Protección contra fuerza bruta y SPAM)
app.state.limiter = limiter # type: ignore
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
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
    logger.error(f"🛢️ Error de Base de Datos: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Error en la operación de base de datos."},
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

# Routers
app.include_router(router)


@app.get("/")
def root():
    return {"message": "Forja Trabajo API funcionando"}