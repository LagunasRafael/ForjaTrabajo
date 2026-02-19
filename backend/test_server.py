from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware # <--- 1. AGREGAR ESTO
from app.db.database import engine
from app.payments import models, routes
from app.services import routes as service_routes # Asegúrate de importar tus rutas de servicios

app = FastAPI()

# --- 2. AGREGA ESTO JUSTO DESPUÉS DE CREAR LA APP ---
origins = [
    "http://localhost",
    "http://localhost:8080", # Puerto por defecto de Dart
    "http://127.0.0.1:8080",
    "*" # ⚠️ TRUCO: El asterisco permite TODO (ideal para desarrollo)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=[], # Dejamos esto vacío intencionalmente
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    # ✅ ESTE ES EL SECRETO: Permite cualquier localhost (http o https)
    allow_origin_regex="https?://(localhost|127\.0\.0\.1)(:\d+)?",
)
# Conecta tus rutas
app.include_router(routes.router, prefix="/payments", tags=["Payments"])
# Asegúrate de que también esté conectada la de servicios
app.include_router(service_routes.router, prefix="/services", tags=["Services"])