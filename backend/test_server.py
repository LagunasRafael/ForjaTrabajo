from fastapi import FastAPI
from app.db.database import engine
# IMPORTACIONES CORREGIDAS: Quitamos la palabra "backend" del inicio
from app.payments import models as payment_models, routes as payment_routes
from app.auth import routes as auth_routes
from app.services import routes as services_routes

# Crea las tablas de la base de datos
payment_models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# CONECTA TUS RUTAS (Corregido el error de duplicados de la imagen 99199f)
app.include_router(payment_routes.router, prefix="/payments", tags=["Payments"])
app.include_router(services_routes.router, prefix="/services", tags=["Services"])
app.include_router(auth_routes.router, prefix="/auth", tags=["Auth"]) # Antes decía /payments