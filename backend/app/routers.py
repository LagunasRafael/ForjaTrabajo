from fastapi import APIRouter
from app.auth.routes import router as auth_router

from app.services.categories.router import router as categories_router
from app.services.posting.router import router as posting_router
from app.services.applications.router import router as applications_router
from app.services.contracts.router import router as contracts_router
from app.services.chats.router import router as chats_router
from app.services.notifications.router import router as notifications_router
from app.payments.routes import router as payments_router, workers_router
from app.settings.routes import router as settings_router

router = APIRouter()

router.include_router(auth_router, prefix="/auth", tags=["Auth"])

router.include_router(categories_router, prefix="/services", tags=["Services - Categorías"])
router.include_router(posting_router, prefix="/services", tags=["Services - Publicaciones"])
router.include_router(applications_router, prefix="/services", tags=["Services - Postulaciones"])
router.include_router(contracts_router, prefix="/services", tags=["Services - Contratos y Jobs"])
router.include_router(chats_router, prefix="/services", tags=["Services - chats"])
router.include_router(notifications_router, prefix="/services", tags=["Services - Notificaciones"])

router.include_router(payments_router, prefix="/payments", tags=["Payments"])
router.include_router(workers_router, prefix="/workers", tags=["Workers - Stripe"])
router.include_router(settings_router, prefix="/settings", tags=["Settings"])


