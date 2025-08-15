#!/bin/bash

# CloudFlare Tunnel Setup Script for Claude Code Backend
# This script installs and configures CloudFlare Tunnel for remote access

set -e

echo "═══════════════════════════════════════════════════"
echo "    CloudFlare Tunnel Setup for Claude Code"
echo "═══════════════════════════════════════════════════"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is designed for macOS only.${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Install cloudflared if not already installed
echo -e "${YELLOW}Step 1: Checking for cloudflared installation...${NC}"
if ! command_exists cloudflared; then
    echo "Installing cloudflared via Homebrew..."
    if ! command_exists brew; then
        echo -e "${RED}Homebrew is not installed. Please install Homebrew first:${NC}"
        echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    brew install cloudflare/cloudflare/cloudflared
    echo -e "${GREEN}cloudflared installed successfully!${NC}"
else
    echo -e "${GREEN}cloudflared is already installed.${NC}"
    cloudflared version
fi

# Step 2: Login to CloudFlare (if not already authenticated)
echo ""
echo -e "${YELLOW}Step 2: Authenticating with CloudFlare...${NC}"
if [ ! -f "$HOME/.cloudflared/cert.pem" ]; then
    echo "Please follow the browser prompt to authenticate with CloudFlare:"
    cloudflared tunnel login
    echo -e "${GREEN}Authentication successful!${NC}"
else
    echo -e "${GREEN}Already authenticated with CloudFlare.${NC}"
fi

# Step 3: Create tunnel (if it doesn't exist)
echo ""
echo -e "${YELLOW}Step 3: Setting up CloudFlare tunnel...${NC}"
TUNNEL_NAME="claude-code-backend"

# Check if tunnel exists
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo -e "${GREEN}Tunnel '$TUNNEL_NAME' already exists.${NC}"
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
else
    echo "Creating new tunnel: $TUNNEL_NAME"
    cloudflared tunnel create $TUNNEL_NAME
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    echo -e "${GREEN}Tunnel created successfully! ID: $TUNNEL_ID${NC}"
fi

# Step 4: Create configuration file
echo ""
echo -e "${YELLOW}Step 4: Creating tunnel configuration...${NC}"
CONFIG_DIR="$HOME/.cloudflared"
CONFIG_FILE="$CONFIG_DIR/config.yml"

mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_FILE" << EOF
tunnel: $TUNNEL_ID
credentials-file: $HOME/.cloudflared/$TUNNEL_ID.json

ingress:
  # Main backend API
  - hostname: claude-code-api.YOUR_DOMAIN.com
    service: http://localhost:3004
    originRequest:
      connectTimeout: 30s
      noTLSVerify: false
      
  # WebSocket endpoint for real-time chat
  - hostname: claude-code-ws.YOUR_DOMAIN.com
    service: ws://localhost:3004
    originRequest:
      connectTimeout: 30s
      noTLSVerify: false
      
  # Catch-all rule (required)
  - service: http_status:404
EOF

echo -e "${GREEN}Configuration file created at: $CONFIG_FILE${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: Update the configuration file with your domain:${NC}"
echo "  1. Edit $CONFIG_FILE"
echo "  2. Replace 'YOUR_DOMAIN.com' with your actual domain"
echo "  3. Add DNS CNAME records pointing to:"
echo "     - claude-code-api → $TUNNEL_ID.cfargotunnel.com"
echo "     - claude-code-ws → $TUNNEL_ID.cfargotunnel.com"

# Step 5: Create service files
echo ""
echo -e "${YELLOW}Step 5: Creating service management scripts...${NC}"

# Create start script
cat > "$(dirname "$0")/start-tunnel.sh" << 'EOF'
#!/bin/bash

echo "Starting CloudFlare tunnel..."
cloudflared tunnel run claude-code-backend
EOF

# Create stop script
cat > "$(dirname "$0")/stop-tunnel.sh" << 'EOF'
#!/bin/bash

echo "Stopping CloudFlare tunnel..."
pkill -f "cloudflared tunnel run claude-code-backend" || echo "Tunnel not running"
EOF

# Create status script
cat > "$(dirname "$0")/status-tunnel.sh" << 'EOF'
#!/bin/bash

if pgrep -f "cloudflared tunnel run claude-code-backend" > /dev/null; then
    echo "✅ CloudFlare tunnel is running"
    echo "Process details:"
    ps aux | grep -v grep | grep "cloudflared tunnel run"
else
    echo "❌ CloudFlare tunnel is not running"
fi
EOF

chmod +x "$(dirname "$0")/start-tunnel.sh"
chmod +x "$(dirname "$0")/stop-tunnel.sh"
chmod +x "$(dirname "$0")/status-tunnel.sh"

echo -e "${GREEN}Service scripts created successfully!${NC}"

# Step 6: Create LaunchAgent for auto-start
echo ""
echo -e "${YELLOW}Step 6: Setting up auto-start on system boot...${NC}"
PLIST_FILE="$HOME/Library/LaunchAgents/com.claudecode.tunnel.plist"

cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claudecode.tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/cloudflared</string>
        <string>tunnel</string>
        <string>run</string>
        <string>claude-code-backend</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/cloudflared.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/cloudflared.error.log</string>
</dict>
</plist>
EOF

echo -e "${GREEN}LaunchAgent created at: $PLIST_FILE${NC}"

echo ""
echo "═══════════════════════════════════════════════════"
echo "            Setup Complete!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "1. Update the CloudFlare config file with your domain:"
echo "   ${CONFIG_FILE}"
echo ""
echo "2. Add DNS CNAME records in CloudFlare Dashboard:"
echo "   - claude-code-api → $TUNNEL_ID.cfargotunnel.com"
echo "   - claude-code-ws → $TUNNEL_ID.cfargotunnel.com"
echo ""
echo "3. Start the tunnel:"
echo "   ./cloudflare/start-tunnel.sh"
echo ""
echo "4. Enable auto-start (optional):"
echo "   launchctl load $PLIST_FILE"
echo ""
echo "5. Update your iOS app configuration to use:"
echo "   API: https://claude-code-api.YOUR_DOMAIN.com"
echo "   WebSocket: wss://claude-code-ws.YOUR_DOMAIN.com"
echo ""