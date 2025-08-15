#!/bin/bash

# CloudFlare Tunnel Start Script
# Starts the CloudFlare tunnel service for Claude Code UI

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================"
echo "Starting CloudFlare Tunnel for Claude Code UI"
echo "================================================"

# Configuration
TUNNEL_NAME="claude-code-ui"
CONFIG_DIR="$HOME/.cloudflared"
CONFIG_FILE="$CONFIG_DIR/config.yml"
PROJECT_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
LOG_FILE="$PROJECT_DIR/cloudflare/tunnel.log"

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo -e "${RED}cloudflared is not installed. Please run ./install-cloudflared.sh first${NC}"
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Configuration file not found at $CONFIG_FILE${NC}"
    echo "Please run ./create-tunnel.sh first"
    exit 1
fi

# Check if tunnel exists
if ! cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo -e "${RED}Tunnel '$TUNNEL_NAME' not found${NC}"
    echo "Please run ./create-tunnel.sh first"
    exit 1
fi

# Check if backend is running
echo -e "${YELLOW}Checking if backend is running...${NC}"
if ! curl -s http://localhost:3004/api/health > /dev/null 2>&1; then
    echo -e "${YELLOW}Backend server is not running${NC}"
    echo "Starting backend server..."
    cd "$PROJECT_DIR"
    npm run server &
    BACKEND_PID=$!
    sleep 5
    echo -e "${GREEN}✓ Backend server started (PID: $BACKEND_PID)${NC}"
else
    echo -e "${GREEN}✓ Backend server is already running${NC}"
fi

# Stop any existing tunnel process
echo -e "${YELLOW}Checking for existing tunnel process...${NC}"
if pgrep -f "cloudflared tunnel run" > /dev/null; then
    echo -e "${YELLOW}Stopping existing tunnel...${NC}"
    pkill -f "cloudflared tunnel run"
    sleep 2
fi

# Start the tunnel
echo -e "${GREEN}Starting CloudFlare tunnel...${NC}"
echo ""

# Run tunnel in foreground for debugging (use nohup for background)
echo -e "${BLUE}Tunnel output:${NC}"
echo "----------------------------------------"

# For production/background use:
# nohup cloudflared tunnel --config "$CONFIG_FILE" run "$TUNNEL_NAME" > "$LOG_FILE" 2>&1 &
# echo $! > "$PROJECT_DIR/cloudflare/tunnel.pid"
# echo -e "${GREEN}✓ Tunnel started in background (PID: $(cat $PROJECT_DIR/cloudflare/tunnel.pid))${NC}"
# echo "Log file: $LOG_FILE"

# For debugging/foreground use:
cloudflared tunnel --config "$CONFIG_FILE" run "$TUNNEL_NAME"