import asyncio
import logging
from typing import List
from fastapi import WebSocket
from sqlalchemy.orm import Session
from sqlalchemy import func

logger = logging.getLogger(__name__)

class AdminWSManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, payload: dict):
        dead = []
        for conn in self.active_connections:
            try:
                await conn.send_json(payload)
            except Exception:
                dead.append(conn)
        for d in dead:
            if d in self.active_connections:
                self.active_connections.remove(d)

admin_manager = AdminWSManager()

def recalculate_and_broadcast(db: Session):
    from app.services.models import Conversation, Report, Service, ReportStatus
    from app.auth.models import IdentityVerification, VerificationStatus, User

    disputes = db.query(Conversation).filter(Conversation.status == 'dispute').count()
    verifications = db.query(IdentityVerification).filter(
        IdentityVerification.status == VerificationStatus.PENDING
    ).count()
    reports = db.query(Report).filter(Report.status == ReportStatus.PENDING).count()
    reported_services = db.query(Service).filter(
        Service.is_reported == True,
        Service.is_active == True
    ).count()
    total_users = db.query(User).count()

    payload = {
        "type": "counts_update",
        "data": {
            "disputes": disputes,
            "verifications": verifications,
            "reports": reports,
            "reported_services": reported_services,
            "total_users": total_users,
        }
    }

    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            asyncio.ensure_future(admin_manager.broadcast(payload))
    except Exception as e:
        logger.warning("No se pudo hacer broadcast a administradores: %s", e)
