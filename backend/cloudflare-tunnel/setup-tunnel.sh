#!/bin/bash

# CloudFlare Tunnel Setup Script for Claude Code UI Backend
# This script sets up a CloudFlare tunnel to expose your local backend to the internet

set -e

echo "🚀 CloudFlare Tunnel Setup for Claude Code UI Backend"
echo "======================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is designed for macOS${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Check and install Homebrew if needed
echo -e "\n${YELLOW}Step 1: Checking Homebrew...${NC}"
if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${GREEN}✓ Homebrew is installed${NC}"
fi

# Step 2: Install cloudflared
echo -e "\n${YELLOW}Step 2: Installing CloudFlare Tunnel (cloudflared)...${NC}"
if ! command_exists cloudflared; then
    brew install cloudflared
    echo -e "${GREEN}✓ cloudflared installed${NC}"
else
    echo -e "${GREEN}✓ cloudflared is already installed${NC}"
    cloudflared version
fi

# Step 3: Authenticate with CloudFlare
echo -e "\n${YELLOW}Step 3: Authenticating with CloudFlare...${NC}"
echo "This will open a browser window for authentication."
echo "Please log in to your CloudFlare account."
echo ""
read -p "Press Enter to continue..."

cloudflared tunnel login

echo -e "${GREEN}✓ Authentication successful${NC}"

# Step 4: Create a tunnel
echo -e "\n${YELLOW}Step 4: Creating CloudFlare Tunnel...${NC}"
TUNNEL_NAME="claude-code-ui-backend"

# Check if tunnel already exists
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo "Tunnel '$TUNNEL_NAME' already exists"
    read -p "Do you want to delete and recreate it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cloudflared tunnel delete "$TUNNEL_NAME" -f
        cloudflared tunnel create "$TUNNEL_NAME"
    fi
else
    cloudflared tunnel create "$TUNNEL_NAME"
fi

# Get tunnel ID
TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
echo -e "${GREEN}✓ Tunnel created with ID: $TUNNEL_ID${NC}"

# Step 5: Create configuration file
echo -e "\n${YELLOW}Step 5: Creating tunnel configuration...${NC}"

# Ask for domain
echo "Please enter your CloudFlare domain (e.g., example.com):"
read -r DOMAIN

# Ask for subdomain
echo "Please enter the subdomain for your backend (e.g., claude-backend):"
echo "This will create: ${subdomain}.${DOMAIN}"
read -r SUBDOMAIN

# Full hostname
HOSTNAME="${SUBDOMAIN}.${DOMAIN}"

# Create config directory
CONFIG_DIR="$HOME/.cloudflared"
mkdir -p "$CONFIG_DIR"

# Create configuration file
cat > "$CONFIG_DIR/config.yml" << EOF
tunnel: $TUNNEL_ID
credentials-file: $CONFIG_DIR/${TUNNEL_ID}.json

ingress:
  # Main backend server
  - hostname: ${HOSTNAME}
    service: http://localhost:3004
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
      httpHostHeader: localhost
      originServerName: localhost
    
  # WebSocket support for real-time chat
  - hostname: ${HOSTNAME}
    path: /ws
    service: http://localhost:3004
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
      httpHostHeader: localhost
      originServerName: localhost
    
  # Shell WebSocket support
  - hostname: ${HOSTNAME}
    path: /shell
    service: http://localhost:3004
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
      httpHostHeader: localhost
      originServerName: localhost
    
  # Catch-all rule
  - service: http_status:404
EOF

echo -e "${GREEN}✓ Configuration file created at $CONFIG_DIR/config.yml${NC}"

# Step 6: Create DNS record
echo -e "\n${YELLOW}Step 6: Creating DNS record...${NC}"
cloudflared tunnel route dns "$TUNNEL_NAME" "$HOSTNAME"
echo -e "${GREEN}✓ DNS record created for ${HOSTNAME}${NC}"

# Step 7: Test the tunnel
echo -e "\n${YELLOW}Step 7: Testing tunnel connection...${NC}"
echo "Starting tunnel in test mode..."
echo "Press Ctrl+C to stop the test"
echo ""
cloudflared tunnel run "$TUNNEL_NAME"