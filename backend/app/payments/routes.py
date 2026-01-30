from fastapi import APIRouter

router = APIRouter()

@router.get("/ping")
def payments_ping():
    return {"module": "payments", "status": "ok"}
