#!/usr/bin/env python3
"""
Complete WebSocket Connection Test for Claude Code iOS
Tests WebSocket connectivity between iOS app and backend
"""

import asyncio
import websockets
import json
import sys
import subprocess
import time
from datetime import datetime

def check_backend_health():
    """Check if backend is healthy"""
    import requests
    try:
        response = requests.get("http://192.168.0.155:3004/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Backend is healthy: {data}")
            return True
        else:
            print(f"❌ Backend health check failed: Status {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Backend health check error: {e}")
        return False

async def test_websocket_as_client():
    """Test WebSocket connection as iOS client would"""
    uri = "ws://192.168.0.155:3004/ws"
    print(f"\n🔄 Testing WebSocket as iOS client at {uri}...")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ WebSocket connected!")
            
            # Send a message like the iOS app would
            ios_message = {
                "type": "claude-command",
                "content": "Test message from iOS simulator",
                "projectPath": "/test/project",
                "sessionId": "test-session-" + str(int(time.time())),
                "timestamp": datetime.now().isoformat()
            }
            
            print(f"📤 Sending iOS-style message: {json.dumps(ios_message, indent=2)}")
            await websocket.send(json.dumps(ios_message))
            
            # Wait for any response with timeout
            print("⏳ Waiting for response...")
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=3.0)
                print(f"📥 Received response: {response}")
                
                # Parse response
                try:
                    response_data = json.loads(response)
                    print(f"✅ Parsed response: {json.dumps(response_data, indent=2)}")
                except json.JSONDecodeError:
                    print(f"⚠️  Response is not JSON: {response}")
                    
            except asyncio.TimeoutError:
                print("⏰ No response within 3 seconds (normal for this backend)")
            
            # Test streaming multiple messages
            print("\n🔄 Testing message stream...")
            for i in range(3):
                msg = {
                    "type": "claude-command",
                    "content": f"Message {i+1}: Hello from iOS test",
                    "projectPath": "/test/project",
                    "timestamp": datetime.now().isoformat()
                }
                print(f"📤 Sending message {i+1}")
                await websocket.send(json.dumps(msg))
                await asyncio.sleep(0.5)
            
            print("\n✅ Client test completed!")
            return True
            
    except Exception as e:
        print(f"❌ WebSocket error: {e}")
        return False

def get_simulator_logs():
    """Get logs from iOS simulator"""
    print("\n📱 Checking iOS Simulator logs...")
    
    # Get recent console logs from simulator
    try:
        # Check for WebSocket-related logs in the last 30 seconds
        result = subprocess.run([
            'log', 'show',
            '--predicate', 'subsystem == "com.claudecode.ui" OR process == "ClaudeCodeUI"',
            '--last', '30s',
            '--style', 'compact'
        ], capture_output=True, text=True, timeout=5)
        
        if result.stdout:
            logs = result.stdout.split('\n')
            websocket_logs = [log for log in logs if 'WebSocket' in log or 'ws://' in log]
            
            if websocket_logs:
                print("📋 WebSocket-related logs found:")
                for log in websocket_logs[-10:]:  # Show last 10 relevant logs
                    if 'CONNECTED' in log:
                        print(f"  ✅ {log}")
                    elif 'ERROR' in log or 'FAILED' in log:
                        print(f"  ❌ {log}")
                    else:
                        print(f"  ℹ️  {log}")
            else:
                print("  ⚠️  No WebSocket logs found in last 30 seconds")
        else:
            print("  ⚠️  No logs available")
            
    except subprocess.TimeoutExpired:
        print("  ⚠️  Log retrieval timed out")
    except Exception as e:
        print(f"  ❌ Error getting logs: {e}")

def test_network_connectivity():
    """Test network connectivity between simulator and backend"""
    print("\n🌐 Testing network connectivity...")
    
    # Test ping to backend host
    try:
        result = subprocess.run(
            ['ping', '-c', '3', '192.168.0.155'],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0:
            print("✅ Network connectivity OK - host is reachable")
            # Parse ping output for stats
            lines = result.stdout.split('\n')
            for line in lines:
                if 'packet loss' in line:
                    print(f"  📊 {line.strip()}")
                elif 'min/avg/max' in line:
                    print(f"  ⏱️  {line.strip()}")
        else:
            print("❌ Network connectivity issue - host unreachable")
            
    except Exception as e:
        print(f"❌ Network test error: {e}")

async def monitor_websocket_for_ios():
    """Monitor WebSocket for messages from iOS app"""
    uri = "ws://192.168.0.155:3004/ws"
    print(f"\n👂 Monitoring WebSocket for iOS app messages at {uri}...")
    print("   (Send a message from the iOS app to see it here)")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ Monitor connected - waiting for iOS app messages...")
            
            # Listen for messages for 10 seconds
            end_time = time.time() + 10
            message_count = 0
            
            while time.time() < end_time:
                try:
                    message = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                    message_count += 1
                    print(f"\n📥 Message {message_count} from iOS app:")
                    
                    try:
                        data = json.loads(message)
                        print(f"   Type: {data.get('type', 'unknown')}")
                        print(f"   Content: {data.get('content', 'N/A')}")
                        print(f"   Timestamp: {data.get('timestamp', 'N/A')}")
                    except:
                        print(f"   Raw: {message[:200]}...")
                        
                except asyncio.TimeoutError:
                    remaining = int(end_time - time.time())
                    if remaining > 0:
                        print(f"   ⏳ Waiting... ({remaining}s remaining)", end='\r')
                    
            if message_count == 0:
                print("\n⚠️  No messages received from iOS app")
                print("   Please ensure the app is running and try sending a message")
            else:
                print(f"\n✅ Received {message_count} messages from iOS app")
                
    except Exception as e:
        print(f"❌ Monitor error: {e}")

async def main():
    print("=" * 70)
    print("Claude Code iOS WebSocket Connection Test Suite")
    print("=" * 70)
    
    # 1. Check backend health
    print("\n[1/5] Backend Health Check")
    print("-" * 40)
    backend_ok = check_backend_health()
    
    if not backend_ok:
        print("\n❌ Backend is not running! Starting it...")
        # Try to start backend
        subprocess.Popen([
            'python3', 
            '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/backend/server.py'
        ])
        await asyncio.sleep(2)
        backend_ok = check_backend_health()
    
    # 2. Test network connectivity
    print("\n[2/5] Network Connectivity Test")
    print("-" * 40)
    test_network_connectivity()
    
    # 3. Test WebSocket as client
    print("\n[3/5] WebSocket Client Test")
    print("-" * 40)
    ws_ok = await test_websocket_as_client()
    
    # 4. Check iOS simulator logs
    print("\n[4/5] iOS Simulator Log Check")
    print("-" * 40)
    get_simulator_logs()
    
    # 5. Monitor for iOS app messages
    print("\n[5/5] iOS App Message Monitor")
    print("-" * 40)
    await monitor_websocket_for_ios()
    
    # Summary
    print("\n" + "=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    
    if backend_ok and ws_ok:
        print("✅ WebSocket infrastructure is WORKING!")
        print("\nNext steps:")
        print("1. Launch the iOS app in simulator")
        print("2. Try sending a message in the chat")
        print("3. Check console logs for WebSocket activity")
        print("\nIf messages aren't working:")
        print("- Check app's WebSocket configuration")
        print("- Verify network settings in simulator")
        print("- Check for firewall blocking port 3004")
        sys.exit(0)
    else:
        print("❌ WebSocket connection issues detected")
        print("\nTroubleshooting:")
        print("1. Ensure backend is running on port 3004")
        print("2. Check network connectivity")
        print("3. Verify firewall settings")
        print("4. Check iOS app configuration")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())