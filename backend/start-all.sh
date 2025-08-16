#!/bin/bash

# Complete Automated Setup Script for Claude Code iOS Backend + Cloudflare Tunnel
# This script starts everything with one command and ensures proper order

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOUDFLARE_DIR="$SCRIPT_DIR/cloudflare"
TUNNEL_LOG="$CLOUDFLARE_DIR/tunnel.log"
BACKEND_LOG="$CLOUDFLARE_DIR/backend.log"
TUNNEL_URL_FILE="$CLOUDFLARE_DIR/current-tunnel-url.txt"

# Create directories
mkdir -p "$CLOUDFLARE_DIR"

clear
echo -e "${CYAN}${BOLD}"
cat << "EOF"
   ____  _                    _         ____            _      
  / ___|| |  ___   _   _   __| |  ___  / ___|  ___   __| |  ___ 
 | |    | | / _ \ | | | | / _` | / _ \| |     / _ \ / _` | / _ \
 | |___ | || (_) || |_| || (_| ||  __/| |___ | (_) | (_| ||  __/
  \____||_| \___/  \__,_| \__,_| \___| \____| \___/ \__,_| \___|
                                                                 
            Complete Automated Setup - One Command Solution
EOF
echo -e "${NC}"

# Don't trap anything - let the script exit normally after starting services

# Step 1: Install dependencies if needed
echo -e "${CYAN}📦 Step 1: Checking dependencies...${NC}"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing npm packages...${NC}"
    npm install
else
    echo -e "${GREEN}✓ Dependencies already installed${NC}"
fi

# Install cloudflared if not present
if ! command -v cloudflared &> /dev/null; then
    echo -e "${YELLOW}Installing cloudflared...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install cloudflare/cloudflare/cloudflared || {
            echo -e "${RED}Failed to install cloudflared${NC}"
            exit 1
        }
    else
        echo -e "${RED}Please install cloudflared manually${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ cloudflared already installed${NC}"
fi

echo ""

# Step 2: Stop any existing backend/tunnel
echo -e "${CYAN}🛑 Step 2: Stopping any existing processes...${NC}"

# Kill existing backend on port 3004
if lsof -Pi :3004 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}Stopping existing backend on port 3004...${NC}"
    lsof -Pi :3004 -sTCP:LISTEN -t | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# Kill existing cloudflared processes
if pgrep cloudflared > /dev/null; then
    echo -e "${YELLOW}Stopping existing cloudflared processes...${NC}"
    pkill cloudflared 2>/dev/null || true
    sleep 2
fi

echo -e "${GREEN}✓ Clean slate ready${NC}"
echo ""

# Step 3: Start backend server
echo -e "${CYAN}🚀 Step 3: Starting backend server...${NC}"
cd "$SCRIPT_DIR"

# Start backend in background
nohup npm run server > "$BACKEND_LOG" 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > "$CLOUDFLARE_DIR/backend.pid"

# Wait for backend to be ready
echo -n "Waiting for backend to start"
for i in {1..30}; do
    if curl -s http://localhost:3004/api/auth/status > /dev/null 2>&1; then
        echo ""
        echo -e "${GREEN}✓ Backend running on http://localhost:3004${NC}"
        break
    fi
    echo -n "."
    sleep 1
    
    if [ $i -eq 30 ]; then
        echo ""
        echo -e "${RED}✗ Backend failed to start after 30 seconds${NC}"
        echo "Check logs: $BACKEND_LOG"
        exit 1
    fi
done

echo ""

# Step 4: Start Cloudflare tunnel
echo -e "${CYAN}☁️  Step 4: Starting Cloudflare tunnel...${NC}"

# Start tunnel and capture output
cloudflared tunnel --url http://localhost:3004 > "$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!
echo $TUNNEL_PID > "$CLOUDFLARE_DIR/tunnel.pid"

# Wait for tunnel URL
echo -n "Waiting for tunnel URL"
TUNNEL_URL=""
for i in {1..30}; do
    TUNNEL_URL=$(grep -o 'https://.*\.trycloudflare\.com' "$TUNNEL_LOG" 2>/dev/null | head -1)
    if [ -n "$TUNNEL_URL" ]; then
        echo ""
        echo -e "${GREEN}✓ Tunnel established${NC}"
        break
    fi
    echo -n "."
    sleep 1
    
    if [ $i -eq 30 ]; then
        echo ""
        echo -e "${RED}✗ Failed to get tunnel URL after 30 seconds${NC}"
        echo "Check logs: $TUNNEL_LOG"
        exit 1
    fi
done

# Save tunnel URL
echo "$TUNNEL_URL" > "$TUNNEL_URL_FILE"

echo ""

# Step 5: Verify everything is working
echo -e "${CYAN}🔍 Step 5: Verifying setup...${NC}"

# Test local backend
if curl -s http://localhost:3004/api/auth/status | grep -q "needsSetup"; then
    echo -e "${GREEN}✓ Local backend responding${NC}"
else
    echo -e "${RED}✗ Local backend not responding properly${NC}"
fi

# Test tunnel
if curl -s "$TUNNEL_URL/api/auth/status" | grep -q "needsSetup"; then
    echo -e "${GREEN}✓ Tunnel connection working${NC}"
else
    echo -e "${YELLOW}⚠ Tunnel may need a moment to stabilize${NC}"
fi

echo ""

# Step 6: Display configuration
echo -e "${GREEN}${BOLD}================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 SUCCESS! Everything is running!${NC}"
echo -e "${GREEN}${BOLD}================================================${NC}"
echo ""
echo -e "${CYAN}📱 iOS App Configuration:${NC}"
echo -e "${YELLOW}${BOLD}$TUNNEL_URL${NC}"
echo ""
echo "Update your iOS app's ${BOLD}AppConfig.swift${NC}:"
echo ""
echo "    static let apiBaseURL = \"$TUNNEL_URL\""
echo "    static let wsBaseURL = \"${TUNNEL_URL/https/wss}\""
echo ""
echo -e "${CYAN}📊 Service Status:${NC}"
echo "  Backend: ${GREEN}Running${NC} on http://localhost:3004 (PID: $BACKEND_PID)"
echo "  Tunnel:  ${GREEN}Active${NC} at $TUNNEL_URL (PID: $TUNNEL_PID)"
echo ""
echo -e "${CYAN}📋 Quick Test Commands:${NC}"
echo "  Test Auth:     curl $TUNNEL_URL/api/auth/status"
echo "  Test Projects: curl $TUNNEL_URL/api/projects"
echo "  Test Health:   curl $TUNNEL_URL/api/health"
echo ""
echo -e "${CYAN}📝 Log Files:${NC}"
echo "  Backend: $BACKEND_LOG"
echo "  Tunnel:  $TUNNEL_LOG"
echo ""
echo -e "${CYAN}🛑 To Stop Everything:${NC}"
echo "  Press ${BOLD}Ctrl+C${NC} or run: kill $BACKEND_PID $TUNNEL_PID"
echo ""
echo -e "${GREEN}Everything is ready! The services will keep running.${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop all services and exit.${NC}"
echo ""

# Create a quick test script
cat > "$CLOUDFLARE_DIR/quick-test.sh" << EOF
#!/bin/bash
# Quick test script for the tunnel
URL="$TUNNEL_URL"

echo "Testing \$URL..."
echo ""
echo "Auth Status:"
curl -s "\$URL/api/auth/status" | jq . 2>/dev/null || curl -s "\$URL/api/auth/status"
echo ""
echo "Projects:"
curl -s "\$URL/api/projects" | jq . 2>/dev/null || curl -s "\$URL/api/projects"
EOF
chmod +x "$CLOUDFLARE_DIR/quick-test.sh"

# Save stop script
cat > "$SCRIPT_DIR/stop-all.sh" << EOF
#!/bin/bash
# Stop all services

echo "Stopping services..."

# Kill backend
if [ -f "$CLOUDFLARE_DIR/backend.pid" ]; then
    kill \$(cat "$CLOUDFLARE_DIR/backend.pid") 2>/dev/null
    rm -f "$CLOUDFLARE_DIR/backend.pid"
    echo "✓ Backend stopped"
fi

# Kill tunnel
if [ -f "$CLOUDFLARE_DIR/tunnel.pid" ]; then
    kill \$(cat "$CLOUDFLARE_DIR/tunnel.pid") 2>/dev/null
    rm -f "$CLOUDFLARE_DIR/tunnel.pid"
    echo "✓ Tunnel stopped"
fi

# Kill any remaining processes
pkill -f "npm run server" 2>/dev/null
pkill cloudflared 2>/dev/null

echo "All services stopped"
EOF
chmod +x "$SCRIPT_DIR/stop-all.sh"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Services are running in the background!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${CYAN}🛑 To stop all services:${NC}"
echo "  Run: ${BOLD}./stop-all.sh${NC}"
echo "  Or: kill $BACKEND_PID $TUNNEL_PID"
echo ""
echo -e "${CYAN}📊 To check status:${NC}"
echo "  Run: ${BOLD}./cloudflare/quick-test.sh${NC}"
echo ""
echo -e "${CYAN}📝 To view logs:${NC}"
echo "  Backend: tail -f $BACKEND_LOG"
echo "  Tunnel:  tail -f $TUNNEL_LOG"
echo ""
echo -e "${GREEN}The terminal is now free for other tasks!${NC}"