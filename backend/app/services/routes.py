from fastapi import APIRouter

router = APIRouter()

@router.get("/ping")
def services_ping():
    return {"module": "services", "status": "ok"}
