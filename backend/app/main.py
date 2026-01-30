from fastapi import FastAPI
from app.routers import router

app = FastAPI(
    title="Forja Trabajo API",
    version="1.0.0"
)

app.include_router(router)

@app.get("/")
def root():
    return {"message": "Forja Trabajo API funcionando 🚀"}
