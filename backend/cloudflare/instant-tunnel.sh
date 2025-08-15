#!/bin/bash

# Instant CloudFlare Tunnel - One Command Setup
# This script provides the absolute fastest way to expose your backend to the internet

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}⚡ Instant CloudFlare Tunnel for Claude Code${NC}"
echo "================================================"
echo ""

# Quick dependency check and install
if ! command -v cloudflared &> /dev/null; then
    echo "Installing cloudflared (one-time setup)..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install cloudflare/cloudflare/cloudflared --quiet
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -L --output cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
        chmod +x cloudflared
        sudo mv cloudflared /usr/local/bin
    fi
fi

# Start backend if needed
PROJECT_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
if ! curl -s http://localhost:3004/api/health > /dev/null 2>&1; then
    echo "Starting backend server..."
    cd "$PROJECT_DIR"
    npm run server > /dev/null 2>&1 &
    sleep 3
fi

# Start tunnel and capture URL
echo -e "${YELLOW}Starting tunnel (no login required)...${NC}"
echo ""

# Run tunnel and extract URL in real-time
cloudflared tunnel --url http://localhost:3004 2>&1 | while IFS= read -r line; do
    # Look for the tunnel URL
    if echo "$line" | grep -q "https://.*\.trycloudflare\.com"; then
        URL=$(echo "$line" | grep -o 'https://[^[:space:]]*\.trycloudflare\.com')
        
        # Clear screen and show success
        clear
        echo -e "${GREEN}================================================"
        echo -e "   🎉 SUCCESS! Your app is live on the internet!"
        echo -e "================================================${NC}"
        echo ""
        echo -e "${CYAN}📱 iOS App Configuration:${NC}"
        echo ""
        echo -e "   API URL: ${YELLOW}$URL${NC}"
        echo -e "   WebSocket: ${YELLOW}${URL/https/wss}/ws${NC}"
        echo ""
        echo -e "${GREEN}Copy and paste into your iOS app's AppConfig.swift:${NC}"
        echo ""
        echo "   static let apiBaseURL = \"$URL\""
        echo "   static let wsBaseURL = \"${URL/https/wss}\""
        echo ""
        
        # Save to file for reference
        echo "$URL" > "$PROJECT_DIR/cloudflare/current-tunnel-url.txt"
        
        # Also create a QR code if qrencode is available
        if command -v qrencode &> /dev/null; then
            echo -e "${CYAN}📱 Scan QR code with your phone:${NC}"
            qrencode -t ANSIUTF8 "$URL"
        fi
        
        echo ""
        echo -e "${YELLOW}⚠️  This URL changes on restart. Press Ctrl+C to stop.${NC}"
        echo "================================================"
        echo ""
    fi
    
    # Show other relevant output
    echo "$line"
done