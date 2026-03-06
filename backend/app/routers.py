from fastapi import APIRouter
from app.auth.routes import router as auth_router

from app.services.categories.router import router as categories_router
from app.services.postings.router import router as postings_router
from app.services.applications.router import router as applications_router
from app.services.contracts.router import router as contracts_router
from app.payments.routes import router as payments_router
from app.settings.routes import router as settings_router


router = APIRouter()

router.include_router(auth_router, prefix="/auth", tags=["Auth"])

router.include_router(categories_router, prefix="/services", tags=["Services - Categorías"])
router.include_router(postings_router, prefix="/services", tags=["Services - Publicaciones"])
router.include_router(applications_router, prefix="/services", tags=["Services - Postulaciones"])
router.include_router(contracts_router, prefix="/services", tags=["Services - Contratos y Jobs"])

router.include_router(payments_router, prefix="/payments", tags=["Payments"])

router.include_router(settings_router, prefix="/config", tags=["Config"])
