#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 Verifying app launch status...${NC}"

# Get booted simulator
DEVICE_ID=$(xcrun simctl list devices | grep "iPhone" | grep "Booted" | head -1 | awk -F'[()]' '{print $2}')

if [ -z "$DEVICE_ID" ]; then
    echo -e "${RED}❌ No iPhone simulator is running!${NC}"
    exit 1
fi

echo -e "${GREEN}📱 Using simulator: $DEVICE_ID${NC}"

# Check if app is installed
APP_INSTALLED=$(xcrun simctl listapps "$DEVICE_ID" | grep -c "com.claudecode.ui" || true)

if [ "$APP_INSTALLED" -eq 0 ]; then
    echo -e "${RED}❌ App is not installed on simulator!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ App is installed${NC}"

# Check if app process is running
APP_RUNNING=$(ps aux | grep -c "[C]laudeCodeUI.app/ClaudeCodeUI" || true)

if [ "$APP_RUNNING" -gt 0 ]; then
    echo -e "${GREEN}✅ App is running (process found)${NC}"
    
    # Get app state from simulator
    APP_STATE=$(xcrun simctl appinfo "$DEVICE_ID" com.claudecode.ui | grep "ApplicationState" | awk '{print $3}' || echo "Unknown")
    echo -e "${GREEN}📊 App state: $APP_STATE${NC}"
    
    # Check memory usage
    MEM_USAGE=$(ps aux | grep "[C]laudeCodeUI.app/ClaudeCodeUI" | awk '{print $4}')
    echo -e "${GREEN}💾 Memory usage: ${MEM_USAGE}%${NC}"
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ App launched successfully without crashes!${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "${YELLOW}⚠️  App process not found. Attempting to launch...${NC}"
    xcrun simctl launch "$DEVICE_ID" com.claudecode.ui
    sleep 2
    
    # Check again
    APP_RUNNING=$(ps aux | grep -c "[C]laudeCodeUI.app/ClaudeCodeUI" || true)
    if [ "$APP_RUNNING" -gt 0 ]; then
        echo -e "${GREEN}✅ App launched successfully!${NC}"
    else
        echo -e "${RED}❌ App failed to launch or crashed immediately!${NC}"
        exit 1
    fi
fi