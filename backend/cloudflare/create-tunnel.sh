#!/bin/bash

# CloudFlare Tunnel Creation Script
# Creates and configures a tunnel for the Claude Code UI backend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================"
echo "CloudFlare Tunnel Setup for Claude Code UI"
echo "================================================"

# Configuration
TUNNEL_NAME="claude-code-ui"
BACKEND_PORT="3004"
CONFIG_DIR="$HOME/.cloudflared"
PROJECT_DIR="$(dirname "$(dirname "$(realpath "$0")")")"

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo -e "${RED}cloudflared is not installed. Please run ./install-cloudflared.sh first${NC}"
    exit 1
fi

# Check if already authenticated
echo -e "${YELLOW}Checking CloudFlare authentication...${NC}"
if ! cloudflared tunnel list &> /dev/null; then
    echo -e "${RED}Not authenticated with CloudFlare${NC}"
    echo "Please run: cloudflared tunnel login"
    exit 1
fi

# Check if tunnel already exists
echo -e "${YELLOW}Checking for existing tunnel...${NC}"
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo -e "${YELLOW}Tunnel '$TUNNEL_NAME' already exists${NC}"
    read -p "Do you want to delete and recreate it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deleting existing tunnel...${NC}"
        cloudflared tunnel delete "$TUNNEL_NAME" -f
    else
        echo "Using existing tunnel"
    fi
else
    echo -e "${GREEN}Creating new tunnel '$TUNNEL_NAME'...${NC}"
fi

# Create the tunnel
if ! cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    cloudflared tunnel create "$TUNNEL_NAME"
    echo -e "${GREEN}✓ Tunnel created successfully${NC}"
fi

# Get tunnel UUID
TUNNEL_UUID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
echo -e "${BLUE}Tunnel UUID: $TUNNEL_UUID${NC}"

# Create config.yml for the tunnel
CONFIG_FILE="$CONFIG_DIR/config.yml"
echo -e "${YELLOW}Creating tunnel configuration...${NC}"

cat > "$CONFIG_FILE" << EOF
# CloudFlare Tunnel Configuration for Claude Code UI
tunnel: $TUNNEL_UUID
credentials-file: $CONFIG_DIR/${TUNNEL_UUID}.json

# Ingress rules - route traffic to local services
ingress:
  # Main backend API and WebSocket
  - hostname: claude-code-api.YOURDOMAIN.com
    service: http://localhost:${BACKEND_PORT}
    originRequest:
      noTLSVerify: true
      httpHostHeader: localhost
      connectTimeout: 30s
      # WebSocket support
      originServerName: localhost
    
  # WebSocket specific path (if needed)
  - hostname: claude-code-api.YOURDOMAIN.com
    path: /ws
    service: ws://localhost:${BACKEND_PORT}
    originRequest:
      noTLSVerify: true
      connectTimeout: 60s
  
  # Shell WebSocket
  - hostname: claude-code-api.YOURDOMAIN.com
    path: /shell
    service: ws://localhost:${BACKEND_PORT}
    originRequest:
      noTLSVerify: true
      connectTimeout: 60s
  
  # Static files and frontend (if serving from same domain)
  - hostname: claude-code.YOURDOMAIN.com
    service: http://localhost:${BACKEND_PORT}
    originRequest:
      noTLSVerify: true
  
  # Catch-all rule (required)
  - service: http_status:404
EOF

echo -e "${GREEN}✓ Configuration file created at $CONFIG_FILE${NC}"

# Create .env file for backend if it doesn't exist
ENV_FILE="$PROJECT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cat > "$ENV_FILE" << EOF
# CloudFlare Tunnel Configuration
TUNNEL_UUID=$TUNNEL_UUID
TUNNEL_NAME=$TUNNEL_NAME
BACKEND_PORT=$BACKEND_PORT

# CloudFlare API (optional - for advanced features)
# CF_API_TOKEN=your-api-token-here
# CF_ZONE_ID=your-zone-id-here

# CORS Configuration for CloudFlare Tunnel
ALLOWED_ORIGINS=http://localhost:3001,http://localhost:3004,https://claude-code-api.YOURDOMAIN.com,https://claude-code.YOURDOMAIN.com

# Backend Configuration
PORT=$BACKEND_PORT
NODE_ENV=production
EOF
    echo -e "${GREEN}✓ .env file created${NC}"
else
    echo -e "${YELLOW}.env file already exists, skipping...${NC}"
fi

echo ""
echo "================================================"
echo "Tunnel setup complete!"
echo ""
echo -e "${YELLOW}IMPORTANT: Next steps:${NC}"
echo ""
echo "1. Update the hostname in $CONFIG_FILE"
echo "   Replace 'YOURDOMAIN.com' with your actual domain"
echo ""
echo "2. Add DNS records to CloudFlare:"
echo "   - claude-code-api.yourdomain.com → $TUNNEL_UUID.cfargotunnel.com (CNAME)"
echo "   - claude-code.yourdomain.com → $TUNNEL_UUID.cfargotunnel.com (CNAME)"
echo ""
echo "3. Start the tunnel:"
echo "   ./start-tunnel.sh"
echo ""
echo "4. Update your iOS app configuration:"
echo "   Set API_BASE_URL = https://claude-code-api.yourdomain.com"
echo ""
echo "================================================"