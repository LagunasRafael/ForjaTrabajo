from fastapi import FastAPI
from app.db.database import engine
from app.payments import models, routes

# Crea las tablas
models.Base.metadata.create_all(bind=engine)

# Inicia la app
app = FastAPI() 

# Conecta tus rutas
app.include_router(routes.router, prefix="/payments", tags=["Payments"])