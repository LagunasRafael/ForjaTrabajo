from fastapi import FastAPI
from app.routers import router
from app.db.database import Base, engine
from app.auth.models import User
from app.services.models import Service
from app.payments.models import Payment
from app.routers import router
from fastapi.middleware.cors import CORSMiddleware
from app.payments.routes import router as payments_router



print("📋 Tablas listas para crear:", Base.metadata.tables.keys())
Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="Forja Trabajo API",
    version="1.0.0"
)

origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
]


app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],  # Permite GET, POST, PUT, DELETE, etc.
    allow_headers=["*"],  # Permite todos los headers (Authorization, Content-Type, etc.)
)

app.include_router(router)


@app.get("/")
def root():
    return {"message": "Forja Trabajo API funcionando "}