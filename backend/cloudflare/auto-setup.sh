#!/bin/bash

# CloudFlare Tunnel Auto-Setup Script
# Automatically installs, configures, and starts CloudFlare tunnel with zero configuration
# Uses CloudFlare's free .trycloudflare.com domain if no custom domain is available

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================================"
echo "   CloudFlare Tunnel Auto-Setup for Claude Code"
echo "   Zero Configuration Required!"
echo "================================================${NC}"
echo ""

# Configuration
PROJECT_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
BACKEND_PORT="3004"
CONFIG_DIR="$HOME/.cloudflared"
TUNNEL_NAME="claude-code-ui-$(date +%s)"
USE_FREE_DOMAIN=false

# Function to display spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is designed for macOS only${NC}"
    exit 1
fi

echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}📦 Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo -e "${YELLOW}📦 Installing cloudflared...${NC}"
    brew install cloudflare/cloudflare/cloudflared &
    spinner $!
    echo -e "${GREEN}✓ cloudflared installed${NC}"
else
    echo -e "${GREEN}✓ cloudflared already installed${NC}"
fi

# Check if backend is running
echo -e "${YELLOW}🔍 Checking backend server...${NC}"
if ! curl -s http://localhost:${BACKEND_PORT}/api/health > /dev/null 2>&1; then
    echo -e "${YELLOW}🚀 Starting backend server...${NC}"
    cd "$PROJECT_DIR"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}📦 Installing backend dependencies...${NC}"
        npm install &
        spinner $!
    fi
    
    # Start backend in background
    nohup npm run server > "$PROJECT_DIR/cloudflare/backend.log" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$PROJECT_DIR/cloudflare/backend.pid"
    
    # Wait for backend to start
    sleep 5
    
    if curl -s http://localhost:${BACKEND_PORT}/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Backend server started (PID: $BACKEND_PID)${NC}"
    else
        echo -e "${RED}✗ Failed to start backend server${NC}"
        echo "Check logs at: $PROJECT_DIR/cloudflare/backend.log"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Backend server already running${NC}"
fi

echo ""
echo -e "${MAGENTA}🌐 Setting up CloudFlare Tunnel...${NC}"
echo ""

# Check if user wants to use custom domain or free domain
echo -e "${CYAN}Choose tunnel type:${NC}"
echo "1) Use free .trycloudflare.com domain (Quick setup, no account needed)"
echo "2) Use custom domain (Requires CloudFlare account)"
echo ""
read -p "Enter choice (1 or 2): " -n 1 -r
echo ""

if [[ $REPLY == "1" ]]; then
    USE_FREE_DOMAIN=true
    echo -e "${GREEN}Using free .trycloudflare.com domain${NC}"
elif [[ $REPLY == "2" ]]; then
    USE_FREE_DOMAIN=false
    echo -e "${BLUE}Using custom domain setup${NC}"
else
    echo -e "${YELLOW}Invalid choice. Using free domain by default.${NC}"
    USE_FREE_DOMAIN=true
fi

# Create directories
mkdir -p "$PROJECT_DIR/cloudflare"
mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$CONFIG_DIR"

if [ "$USE_FREE_DOMAIN" = true ]; then
    # ========================================
    # FREE DOMAIN SETUP (.trycloudflare.com)
    # ========================================
    
    echo ""
    echo -e "${CYAN}🚀 Starting free CloudFlare tunnel...${NC}"
    echo -e "${YELLOW}No login required! This will generate a random URL.${NC}"
    echo ""
    
    # Create a simple tunnel config for try mode
    TUNNEL_CONFIG="$PROJECT_DIR/cloudflare/tunnel-free.yml"
    cat > "$TUNNEL_CONFIG" << EOF
url: http://localhost:${BACKEND_PORT}
EOF
    
    # Start tunnel in try mode (no auth required)
    echo -e "${GREEN}Starting tunnel...${NC}"
    echo -e "${YELLOW}Look for the URL below (format: https://[random].trycloudflare.com)${NC}"
    echo ""
    
    # Run tunnel and capture output
    TUNNEL_LOG="$PROJECT_DIR/cloudflare/tunnel-free.log"
    
    # Start tunnel in background and capture output
    cloudflared tunnel --url http://localhost:${BACKEND_PORT} 2>&1 | tee "$TUNNEL_LOG" &
    TUNNEL_PID=$!
    echo $TUNNEL_PID > "$PROJECT_DIR/cloudflare/tunnel.pid"
    
    # Wait for tunnel URL to appear
    echo -e "${YELLOW}Waiting for tunnel URL...${NC}"
    TUNNEL_URL=""
    ATTEMPTS=0
    MAX_ATTEMPTS=30
    
    while [ -z "$TUNNEL_URL" ] && [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
        sleep 2
        TUNNEL_URL=$(grep -o 'https://.*\.trycloudflare\.com' "$TUNNEL_LOG" 2>/dev/null | head -1)
        ATTEMPTS=$((ATTEMPTS + 1))
        echo -n "."
    done
    echo ""
    
    if [ -n "$TUNNEL_URL" ]; then
        echo ""
        echo -e "${GREEN}================================================${NC}"
        echo -e "${GREEN}🎉 SUCCESS! Tunnel is running!${NC}"
        echo -e "${GREEN}================================================${NC}"
        echo ""
        echo -e "${CYAN}Your tunnel URL:${NC}"
        echo -e "${YELLOW}$TUNNEL_URL${NC}"
        echo ""
        
        # Save configuration for iOS app
        IOS_CONFIG="$PROJECT_DIR/cloudflare/ios-quick-config.json"
        cat > "$IOS_CONFIG" << EOF
{
  "tunnelURL": "$TUNNEL_URL",
  "apiBaseURL": "$TUNNEL_URL",
  "wsBaseURL": "${TUNNEL_URL/https/wss}",
  "endpoints": {
    "auth": "/api/auth",
    "projects": "/api/projects",
    "sessions": "/api/projects/:projectName/sessions",
    "messages": "/api/projects/:projectName/sessions/:sessionId/messages",
    "files": "/api/projects/:projectName/files",
    "git": "/api/git",
    "websocket": "/ws",
    "shell": "/shell"
  },
  "createdAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "type": "trycloudflare",
  "note": "This URL changes each time the tunnel restarts"
}
EOF
        
        echo -e "${GREEN}iOS configuration saved to:${NC}"
        echo "$IOS_CONFIG"
        echo ""
        
        # Create iOS AppConfig update snippet
        IOS_UPDATE="$PROJECT_DIR/cloudflare/ios-config-snippet.swift"
        cat > "$IOS_UPDATE" << EOF
// Update this in your iOS app's AppConfig.swift
// Location: ClaudeCodeUI-iOS/Core/Config/AppConfig.swift

struct AppConfig {
    // CloudFlare Tunnel Configuration
    static let apiBaseURL = "$TUNNEL_URL"
    static let wsBaseURL = "${TUNNEL_URL/https/wss}"
    
    // Endpoints
    static let websocketPath = "/ws"
    static let shellPath = "/shell"
    
    // Auto-generated on: $(date)
    // Note: This URL will change if tunnel restarts
}
EOF
        
        echo -e "${CYAN}📱 iOS App Configuration:${NC}"
        echo "Update your iOS app with the configuration above"
        echo "Configuration file: $IOS_UPDATE"
        echo ""
        
    else
        echo -e "${RED}✗ Failed to get tunnel URL${NC}"
        echo "Check logs at: $TUNNEL_LOG"
        exit 1
    fi
    
else
    # ========================================
    # CUSTOM DOMAIN SETUP
    # ========================================
    
    echo ""
    echo -e "${CYAN}Setting up custom domain tunnel...${NC}"
    
    # Check if authenticated
    if ! cloudflared tunnel list &> /dev/null; then
        echo -e "${YELLOW}📝 You need to authenticate with CloudFlare${NC}"
        echo "This will open a browser window for login"
        echo ""
        read -p "Press Enter to continue..." -n 1 -r
        echo ""
        
        cloudflared tunnel login
        
        if ! cloudflared tunnel list &> /dev/null; then
            echo -e "${RED}✗ Authentication failed${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✓ Authenticated with CloudFlare${NC}"
    
    # Create tunnel
    echo -e "${YELLOW}Creating tunnel...${NC}"
    
    # Check if tunnel exists
    if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
        cloudflared tunnel delete "$TUNNEL_NAME" -f 2>/dev/null || true
    fi
    
    cloudflared tunnel create "$TUNNEL_NAME"
    
    # Get tunnel UUID
    TUNNEL_UUID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    echo -e "${GREEN}✓ Tunnel created: $TUNNEL_UUID${NC}"
    
    # Get domain
    echo ""
    read -p "Enter your domain (e.g., example.com): " DOMAIN
    echo ""
    
    # Create config
    CONFIG_FILE="$CONFIG_DIR/config-auto.yml"
    cat > "$CONFIG_FILE" << EOF
tunnel: $TUNNEL_UUID
credentials-file: $CONFIG_DIR/${TUNNEL_UUID}.json

ingress:
  - hostname: claude-code-api.${DOMAIN}
    service: http://localhost:${BACKEND_PORT}
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
  
  - hostname: claude-code-api.${DOMAIN}
    path: /ws
    service: ws://localhost:${BACKEND_PORT}
    originRequest:
      noTLSVerify: true
      connectTimeout: 60s
  
  - hostname: claude-code-api.${DOMAIN}
    path: /shell
    service: ws://localhost:${BACKEND_PORT}
    originRequest:
      noTLSVerify: true
      connectTimeout: 60s
  
  - service: http_status:404
EOF
    
    echo -e "${GREEN}✓ Configuration created${NC}"
    
    # Add DNS record
    echo ""
    echo -e "${YELLOW}Add this DNS record in CloudFlare:${NC}"
    echo -e "${CYAN}Type:${NC} CNAME"
    echo -e "${CYAN}Name:${NC} claude-code-api"
    echo -e "${CYAN}Target:${NC} ${TUNNEL_UUID}.cfargotunnel.com"
    echo ""
    read -p "Press Enter after adding the DNS record..." -n 1 -r
    echo ""
    
    # Start tunnel
    echo -e "${YELLOW}Starting tunnel...${NC}"
    cloudflared tunnel --config "$CONFIG_FILE" run "$TUNNEL_NAME" &
    TUNNEL_PID=$!
    echo $TUNNEL_PID > "$PROJECT_DIR/cloudflare/tunnel.pid"
    
    TUNNEL_URL="https://claude-code-api.${DOMAIN}"
    
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}🎉 SUCCESS! Custom domain tunnel is running!${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo -e "${CYAN}Your tunnel URL:${NC}"
    echo -e "${YELLOW}$TUNNEL_URL${NC}"
    echo ""
fi

# Create convenience scripts
echo -e "${YELLOW}Creating convenience scripts...${NC}"

# Create start script
START_SCRIPT="$PROJECT_DIR/cloudflare/quick-start.sh"
cat > "$START_SCRIPT" << 'EOF'
#!/bin/bash

PROJECT_DIR="$(dirname "$(dirname "$(realpath "$0")")")"

# Start backend if not running
if ! curl -s http://localhost:3004/api/health > /dev/null 2>&1; then
    echo "Starting backend..."
    cd "$PROJECT_DIR"
    nohup npm run server > "$PROJECT_DIR/cloudflare/backend.log" 2>&1 &
    echo $! > "$PROJECT_DIR/cloudflare/backend.pid"
    sleep 5
fi

# Start tunnel
echo "Starting CloudFlare tunnel..."
EOF

if [ "$USE_FREE_DOMAIN" = true ]; then
    cat >> "$START_SCRIPT" << 'EOF'
cloudflared tunnel --url http://localhost:3004 2>&1 | tee "$PROJECT_DIR/cloudflare/tunnel-free.log" &
echo $! > "$PROJECT_DIR/cloudflare/tunnel.pid"

# Wait and display URL
sleep 5
TUNNEL_URL=$(grep -o 'https://.*\.trycloudflare\.com' "$PROJECT_DIR/cloudflare/tunnel-free.log" | head -1)
echo ""
echo "Tunnel URL: $TUNNEL_URL"
echo ""
echo "Update your iOS app with this URL"
EOF
else
    cat >> "$START_SCRIPT" << EOF
cloudflared tunnel --config "$CONFIG_FILE" run "$TUNNEL_NAME" &
echo \$! > "\$PROJECT_DIR/cloudflare/tunnel.pid"
echo "Tunnel URL: $TUNNEL_URL"
EOF
fi

chmod +x "$START_SCRIPT"

# Create stop script
STOP_SCRIPT="$PROJECT_DIR/cloudflare/quick-stop.sh"
cat > "$STOP_SCRIPT" << 'EOF'
#!/bin/bash

PROJECT_DIR="$(dirname "$(dirname "$(realpath "$0")")")"

# Stop tunnel
if [ -f "$PROJECT_DIR/cloudflare/tunnel.pid" ]; then
    echo "Stopping tunnel..."
    kill $(cat "$PROJECT_DIR/cloudflare/tunnel.pid") 2>/dev/null
    rm "$PROJECT_DIR/cloudflare/tunnel.pid"
fi

# Stop backend
if [ -f "$PROJECT_DIR/cloudflare/backend.pid" ]; then
    echo "Stopping backend..."
    kill $(cat "$PROJECT_DIR/cloudflare/backend.pid") 2>/dev/null
    rm "$PROJECT_DIR/cloudflare/backend.pid"
fi

echo "All services stopped"
EOF

chmod +x "$STOP_SCRIPT"

# Display summary
echo ""
echo -e "${GREEN}================================================"
echo "   Setup Complete!"
echo "================================================${NC}"
echo ""
echo -e "${CYAN}📱 iOS App Configuration:${NC}"
echo -e "   API URL: ${YELLOW}$TUNNEL_URL${NC}"
echo -e "   WebSocket: ${YELLOW}${TUNNEL_URL/https/wss}/ws${NC}"
echo ""
echo -e "${CYAN}🛠  Quick Commands:${NC}"
echo -e "   Start: ${YELLOW}$START_SCRIPT${NC}"
echo -e "   Stop:  ${YELLOW}$STOP_SCRIPT${NC}"
echo ""
echo -e "${CYAN}📊 Monitoring:${NC}"
echo -e "   Backend log: ${YELLOW}tail -f $PROJECT_DIR/cloudflare/backend.log${NC}"
echo -e "   Tunnel log:  ${YELLOW}tail -f $PROJECT_DIR/cloudflare/tunnel-free.log${NC}"
echo ""

if [ "$USE_FREE_DOMAIN" = true ]; then
    echo -e "${YELLOW}⚠️  Note: Free .trycloudflare.com URLs change on restart${NC}"
    echo -e "${YELLOW}    Run quick-start.sh to get a new URL after restart${NC}"
fi

echo ""
echo -e "${GREEN}The tunnel is now running! Your iOS app can connect from anywhere.${NC}"
echo ""

# Keep script running to show tunnel output
if [ "$USE_FREE_DOMAIN" = true ]; then
    echo -e "${CYAN}Tunnel is running. Press Ctrl+C to stop.${NC}"
    echo ""
    tail -f "$TUNNEL_LOG"
fi