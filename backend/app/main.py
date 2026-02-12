from fastapi import FastAPI
from app.routers import router
from app.db.database import Base, engine
from app.auth.models import User
from app.services.models import Service
from app.payments.models import Payment
from app.routers import router


print("📋 Tablas listas para crear:", Base.metadata.tables.keys())
Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="Forja Trabajo API",
    version="1.0.0"
)

app.include_router(router)

@app.get("/")
def root():
    return {"message": "Forja Trabajo API funcionando "}
