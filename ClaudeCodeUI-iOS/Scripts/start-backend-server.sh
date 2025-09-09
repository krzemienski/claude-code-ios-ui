#!/bin/bash

# Start Backend Server for ClaudeCodeUI
# This script starts the backend server required for the iOS app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Starting Backend Server${NC}"
echo -e "${GREEN}========================================${NC}"

# Find backend directory
BACKEND_DIR=""
if [ -d "/Users/nick/Documents/claude-code-ios-ui/backend" ]; then
    BACKEND_DIR="/Users/nick/Documents/claude-code-ios-ui/backend"
elif [ -d "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/backend" ]; then
    BACKEND_DIR="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/backend"
else
    echo -e "${RED}Error: Backend directory not found${NC}"
    echo "Expected locations:"
    echo "  - /Users/nick/Documents/claude-code-ios-ui/backend"
    echo "  - /Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/backend"
    exit 1
fi

echo -e "${GREEN}Found backend at: $BACKEND_DIR${NC}"
cd "$BACKEND_DIR"

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: package.json not found in backend directory${NC}"
    exit 1
fi

# Check if node_modules exists, install if not
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    npm install
fi

# Kill any existing backend process on port 3004
echo -e "${YELLOW}Checking for existing backend process...${NC}"
if lsof -i :3004 > /dev/null 2>&1; then
    echo -e "${YELLOW}Killing existing backend process on port 3004...${NC}"
    kill -9 $(lsof -t -i:3004) 2>/dev/null || true
    sleep 2
fi

# Start the backend server
echo -e "${GREEN}Starting backend server...${NC}"
echo -e "${BLUE}Server will run at: http://192.168.0.155:3004${NC}"

# Create a log file for backend output
LOG_FILE="/tmp/claudecode_backend_$(date +%Y%m%d_%H%M%S).log"

# Start backend in background and save output to log
nohup npm start > "$LOG_FILE" 2>&1 &
BACKEND_PID=$!

echo -e "${GREEN}Backend server started with PID: $BACKEND_PID${NC}"
echo -e "${GREEN}Log file: $LOG_FILE${NC}"

# Wait a moment for server to start
echo -e "${YELLOW}Waiting for server to initialize...${NC}"
sleep 5

# Verify server is running
if curl -s -o /dev/null -w "%{http_code}" "http://192.168.0.155:3004/api/health" | grep -q "200"; then
    echo -e "${GREEN}✓ Backend server is running successfully!${NC}"
    echo ""
    echo "Server Details:"
    echo "  URL: http://192.168.0.155:3004"
    echo "  PID: $BACKEND_PID"
    echo "  Log: $LOG_FILE"
    echo ""
    echo "To stop the server:"
    echo "  kill $BACKEND_PID"
    echo ""
    echo "To view logs:"
    echo "  tail -f $LOG_FILE"
else
    echo -e "${RED}✗ Backend server failed to start${NC}"
    echo "Check the log file for errors:"
    echo "  cat $LOG_FILE"
    exit 1
fi