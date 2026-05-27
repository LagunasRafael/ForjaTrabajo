from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.db.database import SessionLocal
from app.admin.ws_manager import admin_manager, recalculate_and_broadcast

router = APIRouter()

@router.websocket("/ws/counts/{admin_id}")
async def admin_counts_ws(websocket: WebSocket, admin_id: str):
    await admin_manager.connect(websocket)
    db = SessionLocal()
    try:
        recalculate_and_broadcast(db)
    finally:
        db.close()

    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        admin_manager.disconnect(websocket)
    except Exception as e:
        admin_manager.disconnect(websocket)
