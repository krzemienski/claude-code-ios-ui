#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔨 Starting rebuild process...${NC}"

# Navigate to project directory
cd "$(dirname "$0")/.."

# Clean build folder (optional, comment out for faster rebuilds)
# echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
# xcodebuild clean -workspace ClaudeCodeUI.xcworkspace \
#   -scheme ClaudeCodeUI \
#   -configuration Debug \
#   -quiet

# Build the app
echo -e "${YELLOW}🏗️  Building app for simulator...${NC}"
xcodebuild build \
  -workspace ClaudeCodeUI.xcworkspace \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -configuration Debug \
  -derivedDataPath ./DerivedData \
  -quiet \
  ONLY_ACTIVE_ARCH=NO 2>&1 | grep -E "(error:|warning:)" || true

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build succeeded!${NC}"
else
    echo -e "${RED}❌ Build failed! Check the errors above.${NC}"
    exit 1
fi

# Find the app bundle
APP_PATH=$(find ./DerivedData -name "*.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Could not find built app!${NC}"
    exit 1
fi
echo -e "${GREEN}📦 App located at: $APP_PATH${NC}"

# Get the first booted iPhone simulator
DEVICE_ID=$(xcrun simctl list devices | grep "iPhone" | grep "Booted" | head -1 | awk -F'[()]' '{print $2}')

if [ -z "$DEVICE_ID" ]; then
    echo -e "${YELLOW}📱 No iPhone simulator running. Starting iPhone 16 Pro...${NC}"
    # Boot iPhone 16 Pro
    DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | head -1 | awk -F'[()]' '{print $2}')
    xcrun simctl boot "$DEVICE_ID"
    sleep 3
fi

echo -e "${YELLOW}📱 Using simulator: $DEVICE_ID${NC}"

# Uninstall previous version (optional, speeds up testing)
echo -e "${YELLOW}🗑️  Removing previous installation...${NC}"
xcrun simctl uninstall "$DEVICE_ID" com.claudecode.ui 2>/dev/null || true

# Install the app
echo -e "${YELLOW}📲 Installing app on simulator...${NC}"
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

# Launch the app
echo -e "${YELLOW}🚀 Launching app...${NC}"
xcrun simctl launch "$DEVICE_ID" com.claudecode.ui

echo -e "${GREEN}✅ App is ready for testing!${NC}"

# Optional: Open Console to see logs
# echo -e "${YELLOW}📋 Opening Console for logs...${NC}"
# xcrun simctl spawn "$DEVICE_ID" log stream --predicate 'processImagePath contains "ClaudeCodeUI"' &

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}App successfully rebuilt and installed!${NC}"
echo -e "${GREEN}========================================${NC}"