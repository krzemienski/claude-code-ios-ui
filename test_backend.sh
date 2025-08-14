#!/bin/bash

echo "=== Testing Backend Server Connection ==="
echo ""

# Test basic connectivity
echo "1. Testing server connectivity..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3004/api/auth/status | grep -q "200"; then
    echo "   ✅ Server is running on port 3004"
else
    echo "   ❌ Server is NOT reachable on port 3004"
    exit 1
fi

# Test with JWT token
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjIsInVzZXJuYW1lIjoiZGVtbyIsImlhdCI6MTc1NTEzMjI3Mn0.D2ca9DyDwRR8rcJ3Latt86KyfsfuN4_8poJCQCjQ8TI"

echo ""
echo "2. Testing authentication..."
RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3004/api/auth/user)
if echo "$RESPONSE" | grep -q "demo"; then
    echo "   ✅ Authentication works with JWT token"
    echo "   User: $(echo "$RESPONSE" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)"
else
    echo "   ❌ Authentication failed"
fi

echo ""
echo "3. Testing projects endpoint..."
PROJECTS=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3004/api/projects)
if echo "$PROJECTS" | grep -q "name"; then
    PROJECT_COUNT=$(echo "$PROJECTS" | grep -o '"name"' | wc -l)
    echo "   ✅ Projects endpoint works - Found $PROJECT_COUNT projects"
else
    echo "   ❌ Projects endpoint failed"
fi

echo ""
echo "4. Testing WebSocket endpoint..."
WSTEST=$(curl -s -o /dev/null -w "%{http_code}" -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: test" "http://localhost:3004/ws?token=$TOKEN")
if [ "$WSTEST" = "101" ]; then
    echo "   ✅ WebSocket endpoint accepts connections with token"
else
    echo "   ⚠️  WebSocket returned status: $WSTEST (expected 101)"
fi

echo ""
echo "=== Backend Test Complete ==="
echo ""
echo "Backend URL: http://localhost:3004"
echo "WebSocket URL: ws://localhost:3004/ws"
echo "Auth Token: Valid for demo user"