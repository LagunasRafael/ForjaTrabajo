import asyncio
import logging
from typing import Dict, List
from fastapi import WebSocket

logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, conversation_id: str):
        await websocket.accept()
        if conversation_id not in self.active_connections:
            self.active_connections[conversation_id] = []
        self.active_connections[conversation_id].append(websocket)

    def disconnect(self, websocket: WebSocket, conversation_id: str):
        if conversation_id in self.active_connections:
            self.active_connections[conversation_id].remove(websocket)
            if not self.active_connections[conversation_id]:
                del self.active_connections[conversation_id]

    async def broadcast(self, conversation_id: str, message: dict):
        if conversation_id in self.active_connections:
            dead_connections = []
            for connection in self.active_connections[conversation_id]:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.warning(f"Error broadcasting to connection: {e}")
                    dead_connections.append(connection)
            for dead_conn in dead_connections:
                if dead_conn in self.active_connections[conversation_id]:
                    self.active_connections[conversation_id].remove(dead_conn)


manager = ConnectionManager()


def broadcast_event(conversation_id: str, event: dict):
    """Schedule a broadcast to run in the event loop (for sync callers)."""
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            asyncio.ensure_future(manager.broadcast(conversation_id, event))
        else:
            logger.warning(f"Cannot broadcast: no running event loop")
    except Exception as e:
        logger.warning(f"Could not broadcast event: {e}")
