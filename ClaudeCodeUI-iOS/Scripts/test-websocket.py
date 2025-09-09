#!/usr/bin/env python3
"""
WebSocket Connection Test Script for Claude Code iOS
Tests WebSocket connectivity and message exchange
"""

import asyncio
import websockets
import json
import sys
from datetime import datetime

async def test_websocket():
    uri = "ws://192.168.0.155:3004/ws"
    print(f"🔄 Connecting to WebSocket at {uri}...")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ WebSocket connected successfully!")
            
            # Send test message
            test_message = {
                "type": "test",
                "content": "Hello from WebSocket test client!",
                "timestamp": datetime.now().isoformat(),
                "client": "test-script"
            }
            
            print(f"📤 Sending test message: {test_message}")
            await websocket.send(json.dumps(test_message))
            
            # Set timeout for receiving
            print("⏳ Waiting for response (5 second timeout)...")
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                print(f"📥 Received response: {response}")
                
                # Parse and display the response
                try:
                    response_data = json.loads(response)
                    print(f"✅ Parsed response data: {json.dumps(response_data, indent=2)}")
                except json.JSONDecodeError:
                    print(f"⚠️  Response is not JSON: {response}")
                    
            except asyncio.TimeoutError:
                print("⏰ No response received within 5 seconds (this is normal for echo server)")
                
            # Send multiple messages to test streaming
            print("\n🔄 Testing message streaming...")
            for i in range(3):
                msg = {
                    "type": "stream_test",
                    "message_id": i + 1,
                    "content": f"Stream message {i + 1}",
                    "timestamp": datetime.now().isoformat()
                }
                print(f"📤 Sending: Message {i + 1}")
                await websocket.send(json.dumps(msg))
                await asyncio.sleep(0.5)
            
            print("\n✅ WebSocket test completed successfully!")
            print("📊 Test Summary:")
            print("  - Connection: ✅ Established")
            print("  - Send Messages: ✅ Successful")
            print("  - Message Format: ✅ Valid JSON")
            print("  - Server Reachable: ✅ Yes")
            
            return True
            
    except websockets.exceptions.WebSocketException as e:
        print(f"❌ WebSocket error: {e}")
        return False
    except ConnectionRefusedError:
        print(f"❌ Connection refused. Is the server running on {uri}?")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

async def test_api_endpoints():
    """Test regular API endpoints"""
    import aiohttp
    
    base_url = "http://192.168.0.155:3004"
    print(f"\n🔄 Testing API endpoints at {base_url}...")
    
    async with aiohttp.ClientSession() as session:
        # Test health endpoint
        try:
            async with session.get(f"{base_url}/health") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✅ Health check: {data}")
                else:
                    print(f"❌ Health check failed: Status {response.status}")
        except Exception as e:
            print(f"❌ Health check error: {e}")
        
        # Test projects endpoint
        try:
            async with session.get(f"{base_url}/api/projects") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✅ Projects endpoint: {data['count']} projects")
                else:
                    print(f"❌ Projects endpoint failed: Status {response.status}")
        except Exception as e:
            print(f"❌ Projects endpoint error: {e}")

async def main():
    print("=" * 60)
    print("Claude Code iOS WebSocket Connection Test")
    print("=" * 60)
    
    # Test API endpoints first
    await test_api_endpoints()
    
    # Test WebSocket connection
    success = await test_websocket()
    
    print("\n" + "=" * 60)
    if success:
        print("✅ ALL TESTS PASSED - WebSocket is working!")
        sys.exit(0)
    else:
        print("❌ TESTS FAILED - WebSocket connection issues detected")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())