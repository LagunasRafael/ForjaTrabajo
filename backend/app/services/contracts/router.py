from fastapi import APIRouter
from app.services.contracts.job_routes import router as job_router
from app.services.contracts.evidence_routes import router as evidence_router
from app.services.contracts.review_routes import router as review_router
from app.services.contracts.admin_routes import router as admin_router
from app.services.contracts.cron_routes import router as cron_router

router = APIRouter()
router.include_router(job_router)
router.include_router(evidence_router)
router.include_router(review_router)
router.include_router(admin_router)
router.include_router(cron_router)
