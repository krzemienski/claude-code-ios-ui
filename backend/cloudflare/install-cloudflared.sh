#!/bin/bash

# CloudFlare Tunnel Installation Script for macOS
# This script installs cloudflared and sets up the initial configuration

set -e

echo "================================================"
echo "CloudFlare Tunnel Installation for Claude Code UI"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is designed for macOS only${NC}"
    exit 1
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install cloudflared using Homebrew
echo -e "${GREEN}Installing cloudflared...${NC}"
brew install cloudflare/cloudflare/cloudflared

# Verify installation
if command -v cloudflared &> /dev/null; then
    echo -e "${GREEN}✓ cloudflared installed successfully${NC}"
    cloudflared --version
else
    echo -e "${RED}✗ cloudflared installation failed${NC}"
    exit 1
fi

# Create configuration directory
CONFIG_DIR="$HOME/.cloudflared"
mkdir -p "$CONFIG_DIR"
echo -e "${GREEN}✓ Configuration directory created at $CONFIG_DIR${NC}"

# Check if user is logged in to CloudFlare
echo ""
echo -e "${YELLOW}Checking CloudFlare authentication...${NC}"
if ! cloudflared tunnel list &> /dev/null; then
    echo -e "${YELLOW}You need to authenticate with CloudFlare${NC}"
    echo "Please run: cloudflared tunnel login"
    echo "This will open a browser for authentication"
else
    echo -e "${GREEN}✓ Already authenticated with CloudFlare${NC}"
fi

echo ""
echo "================================================"
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Run: cloudflared tunnel login (if not already authenticated)"
echo "2. Run: ./create-tunnel.sh to create your tunnel"
echo "3. Run: ./start-tunnel.sh to start the tunnel service"
echo "================================================"