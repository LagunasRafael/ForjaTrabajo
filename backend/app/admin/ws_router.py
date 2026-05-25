from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.admin.ws_manager import admin_manager, recalculate_and_broadcast

router = APIRouter()

@router.websocket("/ws/counts/{admin_id}")
async def admin_counts_ws(websocket: WebSocket, admin_id: str, db: Session = Depends(get_db)):
    await admin_manager.connect(websocket)
    try:
        recalculate_and_broadcast(db)
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        admin_manager.disconnect(websocket)
    except Exception as e:
        admin_manager.disconnect(websocket)
