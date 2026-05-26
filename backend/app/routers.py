from fastapi import APIRouter

from app.services.categories.router import router as categories_router
from app.services.posting.router import router as posting_router
from app.services.applications.router import router as applications_router
from app.services.contracts.router import router as contracts_router
from app.services.chats.router import router as chats_router
from app.services.notifications.router import router as notifications_router
from app.payments.routes import router as payments_router, workers_router
from app.settings.routes import router as settings_router
from app.moderation.router import router as moderation_router
from app.payments.webhooks import router as webhook_router
from app.admin.finance.routes import router as admin_finance_router
from app.admin.ws_router import router as admin_ws_router
from app.auth import routes as auth_routes
from app.auth import password_routes
from app.auth import profile_routes
from app.auth import fcm_routes
from app.auth import public_profile_routes
from app.auth import identity_routes
from app.auth import admin_user_routes
from app.services.disputes.router import router as disputes_router

router = APIRouter()

router.include_router(auth_routes.router, prefix="/auth", tags=["Auth"])
router.include_router(password_routes.router, prefix="/auth", tags=["Password Recovery"])
router.include_router(profile_routes.router, prefix="/auth", tags=["User Profile"])
router.include_router(fcm_routes.router, prefix="/auth", tags=["FCM"])
router.include_router(public_profile_routes.router, prefix="/auth", tags=["Public Profiles"])
router.include_router(identity_routes.router, prefix="/auth", tags=["Identity Verification"])
router.include_router(admin_user_routes.router, prefix="/auth", tags=["Admin Users"])


router.include_router(categories_router, prefix="/services", tags=["Services - Categorías"])
router.include_router(posting_router, prefix="/services", tags=["Services - Publicaciones"])
router.include_router(applications_router, prefix="/services", tags=["Services - Postulaciones"])
router.include_router(contracts_router, prefix="/services", tags=["Services - Contratos y Jobs"])
router.include_router(chats_router, prefix="/services", tags=["Services - chats"])
router.include_router(notifications_router, prefix="/services", tags=["Services - Notificaciones"])
router.include_router(disputes_router, prefix="/services", tags=["Services - Disputas"])

router.include_router(payments_router, prefix="/payments", tags=["Payments"])
router.include_router(workers_router, prefix="/workers", tags=["Workers - Stripe"])
router.include_router(settings_router, prefix="/settings", tags=["Settings"])

router.include_router(admin_finance_router, prefix="/admin/finance", tags=["Admin - Finance"])
router.include_router(admin_ws_router, prefix="/admin", tags=["Admin WebSocket"])

router.include_router(moderation_router, prefix="/services", tags=["Moderacion"])

router.include_router(webhook_router, tags=["Stripe Webhooks"])

