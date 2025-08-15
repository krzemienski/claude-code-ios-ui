#!/bin/bash

# CloudFlare Tunnel Service Installation Script
# This script sets up cloudflared to run as a service on macOS

set -e

echo "🔧 Installing CloudFlare Tunnel as a Service"
echo "==========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if cloudflared is installed
if ! command -v cloudflared >/dev/null 2>&1; then
    echo -e "${RED}cloudflared is not installed. Please run setup-tunnel.sh first.${NC}"
    exit 1
fi

# Get tunnel name
TUNNEL_NAME="claude-code-ui-backend"

# Check if tunnel exists
if ! cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo -e "${RED}Tunnel '$TUNNEL_NAME' does not exist. Please run setup-tunnel.sh first.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Installing cloudflared service...${NC}"

# Install the service using cloudflared's built-in command
sudo cloudflared service install

echo -e "${GREEN}✓ Service installed${NC}"

# Create a launch daemon plist for automatic startup
echo -e "\n${YELLOW}Creating LaunchDaemon for automatic startup...${NC}"

PLIST_PATH="/Library/LaunchDaemons/com.cloudflare.cloudflared.plist"

# Create the plist file
sudo tee "$PLIST_PATH" > /dev/null << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cloudflare.cloudflared</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/cloudflared</string>
        <string>tunnel</string>
        <string>run</string>
        <string>${TUNNEL_NAME}</string>
    </array>
    
    <key>StandardOutPath</key>
    <string>/var/log/cloudflared.log</string>
    
    <key>StandardErrorPath</key>
    <string>/var/log/cloudflared.error.log</string>
    
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
        <key>NetworkState</key>
        <true/>
    </dict>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>ThrottleInterval</key>
    <integer>30</integer>
    
    <key>WorkingDirectory</key>
    <string>/Users/${USER}</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>/Users/${USER}</string>
    </dict>
</dict>
</plist>
EOF

# Set proper permissions
sudo chown root:wheel "$PLIST_PATH"
sudo chmod 644 "$PLIST_PATH"

# Load the launch daemon
echo -e "\n${YELLOW}Loading launch daemon...${NC}"
sudo launchctl load -w "$PLIST_PATH"

# Check if service is running
sleep 2
if sudo launchctl list | grep -q "com.cloudflare.cloudflared"; then
    echo -e "${GREEN}✓ CloudFlare Tunnel service is running${NC}"
else
    echo -e "${RED}⚠ Service may not be running. Check logs at /var/log/cloudflared.error.log${NC}"
fi

echo -e "\n${GREEN}✅ Installation complete!${NC}"
echo ""
echo "The CloudFlare Tunnel will now:"
echo "  • Start automatically when your Mac boots"
echo "  • Restart automatically if it crashes"
echo "  • Reconnect when network becomes available"
echo ""
echo "Useful commands:"
echo "  • Check status: sudo launchctl list | grep cloudflared"
echo "  • View logs: tail -f /var/log/cloudflared.log"
echo "  • View errors: tail -f /var/log/cloudflared.error.log"
echo "  • Stop service: sudo launchctl unload $PLIST_PATH"
echo "  • Start service: sudo launchctl load $PLIST_PATH"
echo ""