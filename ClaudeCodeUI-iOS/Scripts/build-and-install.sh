#!/bin/bash

# Build and Install Script for ClaudeCodeUI iOS App
# This script builds the app and installs it on the iPhone simulator

set -e

# Configuration
SCHEME="ClaudeCodeUI"
CONFIG="Debug"
SIMULATOR_NAME="iPhone 16 Pro"
BACKEND_HOST="192.168.0.155"
BACKEND_PORT="3004"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} ClaudeCodeUI iOS Build & Install Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Change to project directory
cd "$(dirname "$0")/.."

# Get the simulator UUID
echo -e "${YELLOW}Finding simulator...${NC}"
SIMULATOR_UUID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -E '\([A-F0-9-]+\)' | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')

if [ -z "$SIMULATOR_UUID" ]; then
    echo -e "${RED}Error: Could not find simulator '$SIMULATOR_NAME'${NC}"
    echo "Available simulators:"
    xcrun simctl list devices | grep -E "iPhone|iPad"
    exit 1
fi

echo -e "${GREEN}Found simulator: $SIMULATOR_NAME ($SIMULATOR_UUID)${NC}"

# Boot the simulator if not already booted
SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_UUID" | grep -o "(Booted)" || true)
if [ -z "$SIMULATOR_STATE" ]; then
    echo -e "${YELLOW}Booting simulator...${NC}"
    xcrun simctl boot "$SIMULATOR_UUID" || true
    sleep 5
else
    echo -e "${GREEN}Simulator already booted${NC}"
fi

# Clean build directory
echo -e "${YELLOW}Cleaning build directory...${NC}"
xcodebuild clean -scheme "$SCHEME" -configuration "$CONFIG" > /dev/null 2>&1 || true

# Build the app
echo -e "${YELLOW}Building app...${NC}"
BUILD_OUTPUT=$(xcodebuild \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
    -configuration "$CONFIG" \
    build 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    echo "$BUILD_OUTPUT" | grep -A 5 -B 5 "error:"
    exit 1
fi

echo -e "${GREEN}Build succeeded!${NC}"

# Get the app path
APP_PATH=$(echo "$BUILD_OUTPUT" | grep -o '/.*\.app' | head -1)

if [ -z "$APP_PATH" ]; then
    # Alternative method to find app path
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ClaudeCodeUI.app" -type d | grep "Debug-iphonesimulator" | head -1)
fi

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}Error: Could not find built app${NC}"
    exit 1
fi

echo -e "${GREEN}App built at: $APP_PATH${NC}"

# Uninstall existing app if present
echo -e "${YELLOW}Removing existing app (if any)...${NC}"
xcrun simctl uninstall "$SIMULATOR_UUID" com.claudecode.ui 2>/dev/null || true

# Install the app
echo -e "${YELLOW}Installing app on simulator...${NC}"
xcrun simctl install "$SIMULATOR_UUID" "$APP_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}App installed successfully!${NC}"
else
    echo -e "${RED}Failed to install app${NC}"
    exit 1
fi

# Configure simulator network settings
echo -e "${YELLOW}Configuring simulator network settings...${NC}"
echo -e "Backend configured for: ${GREEN}http://$BACKEND_HOST:$BACKEND_PORT${NC}"

# Create a plist file with environment variables for the app
ENV_PLIST="/tmp/claudecode_env.plist"
cat > "$ENV_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BACKEND_HOST</key>
    <string>$BACKEND_HOST</string>
    <key>BACKEND_PORT</key>
    <string>$BACKEND_PORT</string>
</dict>
</plist>
EOF

# Launch the app
echo -e "${YELLOW}Launching app...${NC}"
xcrun simctl launch "$SIMULATOR_UUID" com.claudecode.ui

if [ $? -eq 0 ]; then
    echo -e "${GREEN}App launched successfully!${NC}"
else
    echo -e "${RED}Failed to launch app${NC}"
    exit 1
fi

# Open the simulator window
echo -e "${YELLOW}Opening simulator window...${NC}"
open -a Simulator

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "App Details:"
echo "  - Bundle ID: com.claudecode.ui"
echo "  - Configuration: $CONFIG"
echo "  - Simulator: $SIMULATOR_NAME"
echo "  - Backend: http://$BACKEND_HOST:$BACKEND_PORT"
echo ""
echo "To view logs, run:"
echo "  xcrun simctl spawn $SIMULATOR_UUID log stream --predicate 'processImagePath endswith \"ClaudeCodeUI\"'"
echo ""
echo "To restart the app:"
echo "  xcrun simctl terminate $SIMULATOR_UUID com.claudecode.ui"
echo "  xcrun simctl launch $SIMULATOR_UUID com.claudecode.ui"