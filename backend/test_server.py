from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.db.database import engine
# Tus modelos
from app.payments import models as payment_models

from app.auth import routes as auth_routes        
from app.services import routes as service_routes

from app.payments import routes as payment_routes
# Crea las tablas
payment_models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# --- 2. AGREGA ESTO JUSTO DESPUÉS DE CREAR LA APP ---
origins = [
    "http://localhost",
    "http://localhost:8080", # Puerto por defecto de Dart
    "http://127.0.0.1:8080",
    "http://10.0.2.2:8080",
    "*" # ⚠️ TRUCO: El asterisco permite TODO (ideal para desarrollo)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Simplificado para desarrollo: permite TODO
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Rutas de Autenticación
app.include_router(auth_routes.router, prefix="/auth", tags=["Auth"])

# Rutas de Servicios (Solo Services)
app.include_router(service_routes.router, prefix="/services", tags=["Services"])

# Rutas de Pagos (Solo Payments)
# 👇 AQUÍ ESTA LA CORRECCIÓN: Usamos payment_routes, NO service_routes
app.include_router(payment_routes.router, prefix="/payments", tags=["Payments"])