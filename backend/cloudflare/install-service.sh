#!/bin/bash

# CloudFlare Tunnel Service Installation Script for macOS
# Sets up the tunnel to run automatically on system boot

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================"
echo "Installing CloudFlare Tunnel as macOS Service"
echo "================================================"

# Configuration
TUNNEL_NAME="claude-code-ui"
SERVICE_NAME="com.claudecode.tunnel"
PROJECT_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
CONFIG_DIR="$HOME/.cloudflared"
PLIST_FILE="$HOME/Library/LaunchAgents/${SERVICE_NAME}.plist"

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo -e "${RED}cloudflared is not installed. Please run ./install-cloudflared.sh first${NC}"
    exit 1
fi

# Check if tunnel exists
if ! cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo -e "${RED}Tunnel '$TUNNEL_NAME' not found. Please run ./create-tunnel.sh first${NC}"
    exit 1
fi

# Get cloudflared path
CLOUDFLARED_PATH=$(which cloudflared)

# Create LaunchAgent plist file
echo -e "${YELLOW}Creating LaunchAgent configuration...${NC}"

cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${SERVICE_NAME}</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>${CLOUDFLARED_PATH}</string>
        <string>tunnel</string>
        <string>--config</string>
        <string>${CONFIG_DIR}/config.yml</string>
        <string>run</string>
        <string>${TUNNEL_NAME}</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>${PROJECT_DIR}</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    
    <key>StandardOutPath</key>
    <string>${PROJECT_DIR}/cloudflare/tunnel.log</string>
    
    <key>StandardErrorPath</key>
    <string>${PROJECT_DIR}/cloudflare/tunnel-error.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>
    
    <key>ThrottleInterval</key>
    <integer>30</integer>
</dict>
</plist>
EOF

echo -e "${GREEN}✓ LaunchAgent configuration created${NC}"

# Create backend service plist
BACKEND_SERVICE_NAME="com.claudecode.backend"
BACKEND_PLIST_FILE="$HOME/Library/LaunchAgents/${BACKEND_SERVICE_NAME}.plist"

echo -e "${YELLOW}Creating backend service configuration...${NC}"

cat > "$BACKEND_PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${BACKEND_SERVICE_NAME}</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/node</string>
        <string>${PROJECT_DIR}/server/index.js</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>${PROJECT_DIR}</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    
    <key>StandardOutPath</key>
    <string>${PROJECT_DIR}/logs/backend.log</string>
    
    <key>StandardErrorPath</key>
    <string>${PROJECT_DIR}/logs/backend-error.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>NODE_ENV</key>
        <string>production</string>
        <key>PORT</key>
        <string>3004</string>
    </dict>
    
    <key>ThrottleInterval</key>
    <integer>30</integer>
</dict>
</plist>
EOF

echo -e "${GREEN}✓ Backend service configuration created${NC}"

# Create log directories
mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$PROJECT_DIR/cloudflare"

# Load the services
echo -e "${YELLOW}Loading services...${NC}"

# Unload if already loaded
launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl unload "$BACKEND_PLIST_FILE" 2>/dev/null || true

# Load the services
launchctl load "$PLIST_FILE"
launchctl load "$BACKEND_PLIST_FILE"

echo -e "${GREEN}✓ Services loaded successfully${NC}"

echo ""
echo "================================================"
echo "Service installation complete!"
echo ""
echo "Services installed:"
echo "  - CloudFlare Tunnel: ${SERVICE_NAME}"
echo "  - Backend Server: ${BACKEND_SERVICE_NAME}"
echo ""
echo "Service Management Commands:"
echo "  Start:   launchctl start ${SERVICE_NAME}"
echo "  Stop:    launchctl stop ${SERVICE_NAME}"
echo "  Status:  launchctl list | grep claudecode"
echo ""
echo "Log files:"
echo "  - Tunnel: ${PROJECT_DIR}/cloudflare/tunnel.log"
echo "  - Backend: ${PROJECT_DIR}/logs/backend.log"
echo ""
echo "The services will start automatically on system boot."
echo "================================================"