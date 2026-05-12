from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import router

from app.db.database import Base, engine
from app.auth.models import User
from app.services.models import Service
from app.payments.models import Payment


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


# Routers
app.include_router(router)


@app.get("/")
def root():
    return {"message": "Forja Trabajo API funcionando"}