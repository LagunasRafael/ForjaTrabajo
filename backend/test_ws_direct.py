import asyncio
import websockets
import json

async def test():
    uri = 'ws://localhost:8000/services/chat/ws/fake-convo/fake-user'
    try:
        print(f'Connecting to {uri}...')
        async with websockets.connect(uri) as websocket:
            print('Connected!')
            payload = json.dumps({'content': 'test', 'type': 'text'})
            print(f'Sending {payload}')
            await websocket.send(payload)
            print('Sent! Waiting for response...')
            response = await websocket.recv()
            print(f'Received: {response}')
    except Exception as e:
        print(f'Error: {e}')

asyncio.run(test())
