from fastapi import APIRouter
from app.services.posting.creation_routes import router as creation_router
from app.services.posting.query_routes import router as query_router
from app.services.posting.history_routes import router as history_router
from app.services.posting.modification_routes import router as modification_router
from app.services.posting.admin_routes import router as admin_router

router = APIRouter()
router.include_router(creation_router)
router.include_router(history_router)
router.include_router(query_router)
router.include_router(modification_router)
router.include_router(admin_router)
