from fastapi import APIRouter

from app.auth.routes import router as auth_router
from app.services.routes import router as services_router
from app.payments.routes import router as payments_router

router = APIRouter()

router.include_router(auth_router, prefix="/auth", tags=["Auth"])
router.include_router(services_router, prefix="/services", tags=["Services"])
router.include_router(payments_router, prefix="/payments", tags=["Payments"])
