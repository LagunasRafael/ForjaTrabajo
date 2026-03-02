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