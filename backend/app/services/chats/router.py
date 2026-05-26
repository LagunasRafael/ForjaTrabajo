from fastapi import APIRouter
from app.services.chats.message_routes import router as message_router
from app.services.chats.conversation_routes import router as conversation_router
from app.services.chats.offer_routes import router as offer_router
from app.services.chats.websocket_routes import router as websocket_router

router = APIRouter()

router.include_router(message_router)
router.include_router(conversation_router)
router.include_router(offer_router)
router.include_router(websocket_router)
