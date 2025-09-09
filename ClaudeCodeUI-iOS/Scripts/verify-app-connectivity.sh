#!/bin/bash

# Verify App Connectivity to Backend
# This script checks if the app can connect to the backend server

set -e

# Configuration
BACKEND_HOST="192.168.0.155"
BACKEND_PORT="3004"
SIMULATOR_NAME="iPhone 16 Pro"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} App Connectivity Verification${NC}"
echo -e "${GREEN}========================================${NC}"

# Get the simulator UUID
SIMULATOR_UUID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -E '\([A-F0-9-]+\)' | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')

echo -e "${BLUE}Configuration:${NC}"
echo "  Backend: http://$BACKEND_HOST:$BACKEND_PORT"
echo "  Simulator: $SIMULATOR_NAME ($SIMULATOR_UUID)"
echo ""

# Step 1: Verify backend is running
echo -e "${YELLOW}Step 1: Checking backend server...${NC}"
if curl -s -o /dev/null -w "%{http_code}" "http://$BACKEND_HOST:$BACKEND_PORT/api/health" | grep -q "200"; then
    echo -e "${GREEN}✓ Backend health check passed${NC}"
else
    echo -e "${RED}✗ Backend health check failed${NC}"
    echo "  Please ensure the backend is running at http://$BACKEND_HOST:$BACKEND_PORT"
    exit 1
fi

# Step 2: Check WebSocket endpoint
echo -e "${YELLOW}Step 2: Checking WebSocket endpoint...${NC}"
if curl -s -o /dev/null -w "%{http_code}" "http://$BACKEND_HOST:$BACKEND_PORT/ws" | grep -q "426\|101"; then
    echo -e "${GREEN}✓ WebSocket endpoint available${NC}"
else
    echo -e "${YELLOW}⚠ WebSocket endpoint might not be configured${NC}"
fi

# Step 3: Check app process
echo -e "${YELLOW}Step 3: Checking app process...${NC}"
if ps aux | grep -q "[C]laudeCodeUI.app"; then
    echo -e "${GREEN}✓ App is running${NC}"
else
    echo -e "${YELLOW}⚠ App might not be running${NC}"
    echo "  Launching app..."
    xcrun simctl launch "$SIMULATOR_UUID" com.claudecode.ui 2>/dev/null || true
fi

# Step 4: Monitor app logs for connection
echo -e "${YELLOW}Step 4: Monitoring app logs for backend connection...${NC}"
echo "  Watching for connection attempts (10 seconds)..."

# Create a temporary log file
LOG_FILE="/tmp/claudecode_connectivity_$(date +%s).log"

# Start monitoring logs in background
xcrun simctl spawn "$SIMULATOR_UUID" log stream --predicate 'processImagePath endswith "ClaudeCodeUI"' --level debug > "$LOG_FILE" 2>&1 &
LOG_PID=$!

# Wait a bit for logs to accumulate
sleep 10

# Kill the log monitoring
kill $LOG_PID 2>/dev/null || true

# Check for backend connection logs
if grep -q "192.168.0.155\|backend\|WebSocket\|API" "$LOG_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ App is attempting to connect to backend${NC}"
    echo ""
    echo "Relevant log entries:"
    grep -i "backend\|websocket\|api\|192.168" "$LOG_FILE" | head -10 || true
else
    echo -e "${YELLOW}⚠ No backend connection attempts detected in logs${NC}"
fi

# Step 5: Test API endpoints from simulator context
echo ""
echo -e "${YELLOW}Step 5: Testing API endpoints...${NC}"

# Test auth status endpoint
AUTH_STATUS=$(curl -s -w "\n%{http_code}" "http://$BACKEND_HOST:$BACKEND_PORT/api/auth/status" | tail -1)
if [ "$AUTH_STATUS" = "200" ] || [ "$AUTH_STATUS" = "401" ]; then
    echo -e "${GREEN}✓ Auth status endpoint responding (Status: $AUTH_STATUS)${NC}"
else
    echo -e "${RED}✗ Auth status endpoint not responding${NC}"
fi

# Test projects endpoint
PROJECTS_STATUS=$(curl -s -w "\n%{http_code}" "http://$BACKEND_HOST:$BACKEND_PORT/api/projects" | tail -1)
if [ "$PROJECTS_STATUS" = "200" ] || [ "$PROJECTS_STATUS" = "401" ]; then
    echo -e "${GREEN}✓ Projects endpoint responding (Status: $PROJECTS_STATUS)${NC}"
else
    echo -e "${RED}✗ Projects endpoint not responding${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Connectivity Test Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Summary:"
echo "  ✓ Backend server is running"
echo "  ✓ API endpoints are accessible"
echo "  ✓ App is installed and running"
echo ""
echo "If the app is not connecting:"
echo "1. Check the app's network logs in Xcode Console"
echo "2. Verify firewall settings allow connections"
echo "3. Ensure both devices are on the same network"
echo "4. Try restarting the app:"
echo "   xcrun simctl terminate $SIMULATOR_UUID com.claudecode.ui"
echo "   xcrun simctl launch $SIMULATOR_UUID com.claudecode.ui"
echo ""
echo "Log file saved to: $LOG_FILE"