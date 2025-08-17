#!/bin/bash

# Quick test script for iOS ClaudeCodeUI app
# Run this after iOS 18.5 runtime is installed

echo "🚀 iOS ClaudeCodeUI Quick Test Script"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Verify backend is running
echo -e "\n${YELLOW}Step 1: Checking backend server...${NC}"
if curl -s http://localhost:3004/api/health > /dev/null; then
    echo -e "${GREEN}✅ Backend is running at http://localhost:3004${NC}"
else
    echo -e "${RED}❌ Backend is not running! Start it with:${NC}"
    echo "   cd backend && npm start"
    exit 1
fi

# Step 2: Test backend endpoints
echo -e "\n${YELLOW}Step 2: Testing backend endpoints...${NC}"
PROJECTS=$(curl -s http://localhost:3004/api/projects)
if [ ! -z "$PROJECTS" ]; then
    echo -e "${GREEN}✅ Projects endpoint working${NC}"
    echo "   Projects found: $(echo $PROJECTS | grep -o '"name"' | wc -l)"
else
    echo -e "${RED}❌ Projects endpoint not responding${NC}"
fi

# Step 3: Check if iOS runtime is installed
echo -e "\n${YELLOW}Step 3: Checking iOS 18.5 runtime...${NC}"
if xcrun simctl list runtimes | grep -q "iOS 18"; then
    echo -e "${GREEN}✅ iOS 18.x runtime found${NC}"
else
    echo -e "${RED}❌ iOS 18.x runtime not found${NC}"
    echo "   Install via: Xcode → Settings → Platforms → + → iOS 18.5"
fi

# Step 4: List available devices
echo -e "\n${YELLOW}Step 4: Available devices:${NC}"
xcrun simctl list devices | grep -E "(iPhone 16|iPhone 15|iPad)" | head -5

# Step 5: Build the app
echo -e "\n${YELLOW}Step 5: Building iOS app...${NC}"
cd ClaudeCodeUI-iOS

# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/ClaudeCodeUI-*

# Build for generic iOS device (works for both iPhone and iPad)
if xcodebuild build \
    -project ClaudeCodeUI.xcodeproj \
    -scheme ClaudeCodeUI \
    -configuration Debug \
    -destination 'generic/platform=iOS' \
    -quiet; then
    echo -e "${GREEN}✅ App built successfully${NC}"
else
    echo -e "${RED}❌ Build failed - check Xcode for details${NC}"
    exit 1
fi

# Step 6: Check WebSocket implementation
echo -e "\n${YELLOW}Step 6: Verifying Starscream WebSocket is enabled...${NC}"
if grep -q "rolloutPercentage: 100" Core/Services/FeatureFlags.swift; then
    echo -e "${GREEN}✅ Starscream WebSocket enabled at 100%${NC}"
else
    echo -e "${YELLOW}⚠️  Starscream rollout not at 100% - checking...${NC}"
fi

# Step 7: Verify correct URLs in AppConfig
echo -e "\n${YELLOW}Step 7: Checking AppConfig URLs...${NC}"
if grep -q "http://localhost:3004" Core/Config/AppConfig.swift; then
    echo -e "${GREEN}✅ Backend URL correctly set to localhost:3004${NC}"
else
    echo -e "${RED}❌ Backend URL not set to localhost - app won't connect!${NC}"
fi

if grep -q "ws://localhost:3004/ws" Core/Config/AppConfig.swift; then
    echo -e "${GREEN}✅ WebSocket URL correctly set${NC}"
else
    echo -e "${RED}❌ WebSocket URL incorrect${NC}"
fi

# Step 8: Final instructions
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${GREEN}✅ Pre-flight checks complete!${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Open Xcode: open ClaudeCodeUI.xcodeproj"
echo "2. Select your device (iPhone 16 Pro Max or iPad m2)"
echo "3. Press Cmd+R to run"
echo "4. Watch console for WebSocket connection logs"
echo ""
echo "Expected console output:"
echo "  '✅ WebSocket connected to ws://localhost:3004/ws'"
echo "  '✅ Using Starscream WebSocket implementation'"
echo ""
echo "Test sequence:"
echo "  1. Projects should load automatically"
echo "  2. Tap a project to see sessions"
echo "  3. Tap a session to open chat"
echo "  4. Send a test message"
echo ""
echo -e "${GREEN}Good luck! 🚀${NC}"