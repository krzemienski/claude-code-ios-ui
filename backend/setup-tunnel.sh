#!/bin/bash

# Master CloudFlare Tunnel Setup Script
# Automatically detects and uses the best available method

set -e

# Colors
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

clear
echo -e "${CYAN}${BOLD}"
cat << "EOF"
   ____  _                    _         ____            _      
  / ___|| |  ___   _   _   __| |  ___  / ___|  ___   __| |  ___ 
 | |    | | / _ \ | | | | / _` | / _ \| |     / _ \ / _` | / _ \
 | |___ | || (_) || |_| || (_| ||  __/| |___ | (_) | (_| ||  __/
  \____||_| \___/  \__,_| \__,_| \___| \____| \___/ \__,_| \___|
                                                                 
          CloudFlare Tunnel Setup - Remote Access Edition
EOF
echo -e "${NC}"
echo -e "${YELLOW}This will expose your local backend to the internet securely${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to get tunnel URL from cloudflared output
get_tunnel_url() {
    local log_file=$1
    local attempts=0
    local max_attempts=15
    local url=""
    
    while [ -z "$url" ] && [ $attempts -lt $max_attempts ]; do
        sleep 2
        url=$(grep -o 'https://.*\.trycloudflare\.com' "$log_file" 2>/dev/null | head -1)
        attempts=$((attempts + 1))
        echo -n "."
    done
    echo ""
    echo "$url"
}

# Detect best setup method
echo -e "${CYAN}🔍 Detecting best setup method...${NC}"
echo ""

METHOD=""
if command_exists docker && docker info &> /dev/null; then
    METHOD="docker"
    echo -e "${GREEN}✓ Docker detected - Best option for isolation${NC}"
elif command_exists cloudflared; then
    METHOD="cloudflared"
    echo -e "${GREEN}✓ cloudflared installed - Using native tunnel${NC}"
elif [[ "$OSTYPE" == "darwin"* ]] && command_exists brew; then
    METHOD="homebrew"
    echo -e "${YELLOW}⚡ Will install cloudflared via Homebrew${NC}"
else
    METHOD="manual"
    echo -e "${YELLOW}⚡ Will download and install cloudflared${NC}"
fi

echo ""
echo -e "${MAGENTA}Choose setup type:${NC}"
echo ""
echo "  1) ${BOLD}Quick Start${NC} - Free .trycloudflare.com domain (No account needed)"
echo "  2) ${BOLD}Custom Domain${NC} - Use your own domain (CloudFlare account required)"
echo "  3) ${BOLD}Docker Mode${NC} - Run everything in containers (Most isolated)"
echo "  4) ${BOLD}Auto Mode${NC} - Let the script decide (Recommended)"
echo ""
read -p "Enter choice [1-4]: " -n 1 -r
echo ""
echo ""

case $REPLY in
    1)
        SETUP_TYPE="quick"
        ;;
    2)
        SETUP_TYPE="custom"
        ;;
    3)
        SETUP_TYPE="docker"
        ;;
    4|"")
        SETUP_TYPE="auto"
        ;;
    *)
        echo -e "${YELLOW}Invalid choice. Using Auto Mode.${NC}"
        SETUP_TYPE="auto"
        ;;
esac

# Handle Docker setup
if [[ "$SETUP_TYPE" == "docker" ]] || ([[ "$SETUP_TYPE" == "auto" ]] && [[ "$METHOD" == "docker" ]]); then
    echo -e "${CYAN}🐳 Setting up with Docker...${NC}"
    echo ""
    
    cd "$CLOUDFLARE_DIR"
    
    # Build and start containers
    echo -e "${YELLOW}Building containers...${NC}"
    docker-compose build
    
    echo -e "${YELLOW}Starting services...${NC}"
    docker-compose up -d
    
    # Wait for tunnel URL
    echo -e "${YELLOW}Waiting for tunnel URL...${NC}"
    sleep 5
    
    # Get tunnel URL from docker logs
    TUNNEL_URL=$(docker logs claude-code-tunnel 2>&1 | grep -o 'https://.*\.trycloudflare\.com' | head -1)
    
    if [ -n "$TUNNEL_URL" ]; then
        echo ""
        echo -e "${GREEN}${BOLD}================================================${NC}"
        echo -e "${GREEN}${BOLD}🎉 SUCCESS! Docker tunnel is running!${NC}"
        echo -e "${GREEN}${BOLD}================================================${NC}"
        echo ""
        echo -e "${CYAN}Your tunnel URL:${NC}"
        echo -e "${YELLOW}${BOLD}$TUNNEL_URL${NC}"
        echo ""
        echo -e "${CYAN}📱 iOS App Configuration:${NC}"
        echo "   API URL: $TUNNEL_URL"
        echo "   WebSocket: ${TUNNEL_URL/https/wss}/ws"
        echo ""
        echo -e "${CYAN}🛠 Docker Commands:${NC}"
        echo "   View logs: docker-compose logs -f"
        echo "   Stop: docker-compose down"
        echo "   Restart: docker-compose restart"
        echo ""
    else
        echo -e "${RED}Failed to get tunnel URL from Docker${NC}"
        echo "Check logs: docker logs claude-code-tunnel"
    fi
    exit 0
fi

# Install cloudflared if needed
if ! command_exists cloudflared; then
    echo -e "${YELLOW}📦 Installing cloudflared...${NC}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install cloudflare/cloudflare/cloudflared
        else
            echo -e "${YELLOW}Installing Homebrew first...${NC}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            brew install cloudflare/cloudflare/cloudflared
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -L --output /tmp/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
        chmod +x /tmp/cloudflared
        sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
    else
        echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ cloudflared installed${NC}"
fi

# Start backend if needed
echo -e "${YELLOW}🔍 Checking backend...${NC}"
if ! curl -s http://localhost:3004/api/health > /dev/null 2>&1; then
    echo -e "${YELLOW}Starting backend server...${NC}"
    cd "$SCRIPT_DIR"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        npm install
    fi
    
    # Start backend
    npm run server > "$CLOUDFLARE_DIR/backend.log" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$CLOUDFLARE_DIR/backend.pid"
    sleep 5
    
    if curl -s http://localhost:3004/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Backend started${NC}"
    else
        echo -e "${RED}✗ Backend failed to start${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Backend already running${NC}"
fi

# Create necessary directories
mkdir -p "$CLOUDFLARE_DIR"

# Handle Quick Start (Free domain)
if [[ "$SETUP_TYPE" == "quick" ]] || [[ "$SETUP_TYPE" == "auto" ]]; then
    echo ""
    echo -e "${CYAN}🚀 Starting free CloudFlare tunnel...${NC}"
    echo -e "${YELLOW}No login required!${NC}"
    echo ""
    
    # Start tunnel and capture output
    LOG_FILE="$CLOUDFLARE_DIR/tunnel.log"
    cloudflared tunnel --url http://localhost:3004 > "$LOG_FILE" 2>&1 &
    TUNNEL_PID=$!
    echo $TUNNEL_PID > "$CLOUDFLARE_DIR/tunnel.pid"
    
    echo -e "${YELLOW}Waiting for tunnel URL${NC}"
    TUNNEL_URL=$(get_tunnel_url "$LOG_FILE")
    
    if [ -n "$TUNNEL_URL" ]; then
        # Save configuration
        cat > "$CLOUDFLARE_DIR/current-config.json" << EOF
{
  "url": "$TUNNEL_URL",
  "apiBaseURL": "$TUNNEL_URL",
  "wsBaseURL": "${TUNNEL_URL/https/wss}",
  "type": "trycloudflare",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
        
        # Display success
        clear
        echo -e "${GREEN}${BOLD}"
        cat << "EOF"
   ____                                     _ 
  / ___| _   _   ___  ___  ___  ___  ___  | |
  \___ \| | | | / __|/ __|/ _ \/ __|/ __| | |
   ___) | |_| || (__| (__|  __/\__ \\__ \ |_|
  |____/ \__,_| \___|\___|\___||___/|___/ (_)
EOF
        echo -e "${NC}"
        echo ""
        echo -e "${GREEN}${BOLD}Your backend is now accessible from anywhere!${NC}"
        echo ""
        echo -e "${CYAN}${BOLD}📱 Tunnel URL:${NC}"
        echo -e "${YELLOW}${BOLD}$TUNNEL_URL${NC}"
        echo ""
        echo -e "${CYAN}Update your iOS app's AppConfig.swift:${NC}"
        echo ""
        echo "    static let apiBaseURL = \"$TUNNEL_URL\""
        echo "    static let wsBaseURL = \"${TUNNEL_URL/https/wss}\""
        echo ""
        
        # Create QR code if possible
        if command_exists qrencode; then
            echo -e "${CYAN}📱 Or scan this QR code:${NC}"
            echo "$TUNNEL_URL" | qrencode -t ANSIUTF8 -s 1
        fi
        
        echo ""
        echo -e "${YELLOW}⚠️  This URL changes on restart${NC}"
        echo -e "${CYAN}Commands:${NC}"
        echo "   Stop:    kill $TUNNEL_PID"
        echo "   Logs:    tail -f $LOG_FILE"
        echo "   Restart: $0"
        echo ""
        echo -e "${GREEN}Press Ctrl+C to stop the tunnel${NC}"
        echo ""
        
        # Keep showing logs
        tail -f "$LOG_FILE"
    else
        echo -e "${RED}✗ Failed to start tunnel${NC}"
        echo "Check logs: $LOG_FILE"
        exit 1
    fi
    
elif [[ "$SETUP_TYPE" == "custom" ]]; then
    # Custom domain setup
    echo -e "${CYAN}Setting up custom domain...${NC}"
    
    # Run the create-tunnel.sh script
    if [ -f "$CLOUDFLARE_DIR/create-tunnel.sh" ]; then
        "$CLOUDFLARE_DIR/create-tunnel.sh"
    else
        echo -e "${RED}Custom domain setup script not found${NC}"
        echo "Please run: $CLOUDFLARE_DIR/auto-setup.sh"
        exit 1
    fi
fi