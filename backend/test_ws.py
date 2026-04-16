import sys
import json
from fastapi.testclient import TestClient
try:
    from app.main import app
    print("Loaded app")
    client = TestClient(app)
    print("Created TestClient")
    with client.websocket_connect("/services/chat/ws/fake-convo/fake-user") as websocket:
        print("Connected to websocket")
        websocket.send_json({"content": "hello", "type": "text"})
        print("Sent JSON")
        data = websocket.receive_text()
        print("Received:", data)
except Exception as e:
    import traceback
    traceback.print_exc()
