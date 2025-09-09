#!/bin/bash

# iPhone 16 Pro Max Simulator Setup Script for Claude API E2E Testing
# This script creates and configures an optimized iPhone 16 Pro Max simulator

set -e

echo "🚀 Setting up iPhone 16 Pro Max Simulator for Claude API Testing..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SIMULATOR_NAME="iPhone 16 Pro Max - Claude Testing"
DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max"
RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-18-0"

# Function to check if simulator exists
simulator_exists() {
    xcrun simctl list devices | grep -q "$SIMULATOR_NAME"
}

# Function to get simulator ID
get_simulator_id() {
    xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' | head -1
}

# Check for Xcode installation
if ! command -v xcrun &> /dev/null; then
    echo -e "${RED}❌ Xcode command line tools not found. Please install Xcode.${NC}"
    exit 1
fi

# Remove existing simulator if it exists
if simulator_exists; then
    echo -e "${YELLOW}⚠️  Simulator already exists. Removing old instance...${NC}"
    DEVICE_ID=$(get_simulator_id)
    xcrun simctl delete "$DEVICE_ID"
fi

# Create new simulator
echo "📱 Creating iPhone 16 Pro Max simulator..."
xcrun simctl create "$SIMULATOR_NAME" "$DEVICE_TYPE" "$RUNTIME" 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Using iPhone 15 Pro Max as fallback...${NC}"
    DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro-Max"
    RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-17-5"
    xcrun simctl create "$SIMULATOR_NAME" "$DEVICE_TYPE" "$RUNTIME"
}

# Get the new device ID
DEVICE_ID=$(get_simulator_id)
echo "✅ Simulator created with ID: $DEVICE_ID"

# Boot the simulator
echo "🔄 Booting simulator..."
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || echo "Simulator already booted"

# Wait for boot to complete
sleep 5

# Configure simulator settings
echo "⚙️  Configuring simulator settings..."

# Set carrier name for testing
xcrun simctl spawn "$DEVICE_ID" defaults write com.apple.springboard FakeCarrier "Claude Test"

# Show battery percentage
xcrun simctl spawn "$DEVICE_ID" defaults write com.apple.springboard SBShowBatteryPercentage 1

# Disable keyboard autocorrection (useful for testing)
xcrun simctl spawn "$DEVICE_ID" defaults write com.apple.Preferences KeyboardAutocorrection -bool false

# Set locale and language
xcrun simctl spawn "$DEVICE_ID" defaults write .GlobalPreferences AppleLocale "en_US"
xcrun simctl spawn "$DEVICE_ID" defaults write .GlobalPreferences AppleLanguages -array "en"

# Configure network conditions for SSE/WebSocket testing
echo "🌐 Setting up network conditions..."

# Create different network profiles
cat > network_profiles.json << 'EOF'
{
  "profiles": {
    "perfect": {
      "downlink": 1000000,
      "uplink": 1000000,
      "latency": 0,
      "packetLoss": 0
    },
    "good_wifi": {
      "downlink": 40000,
      "uplink": 33000,
      "latency": 10,
      "packetLoss": 0
    },
    "average_lte": {
      "downlink": 10000,
      "uplink": 3000,
      "latency": 50,
      "packetLoss": 0.1
    },
    "poor_3g": {
      "downlink": 780,
      "uplink": 330,
      "latency": 200,
      "packetLoss": 1
    },
    "edge": {
      "downlink": 240,
      "uplink": 200,
      "latency": 400,
      "packetLoss": 2
    }
  }
}
EOF

# Install Claude Code UI test app (if available)
if [ -f "../../DerivedData/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app" ]; then
    echo "📲 Installing Claude Code UI app..."
    xcrun simctl install "$DEVICE_ID" "../../DerivedData/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app"
else
    echo -e "${YELLOW}⚠️  App not found. Build the app first using Xcode or xcodebuild.${NC}"
fi

# Configure permissions
echo "🔐 Setting up permissions..."
xcrun simctl privacy "$DEVICE_ID" grant all com.claudecode.ui

# Enable developer mode
xcrun simctl spawn "$DEVICE_ID" defaults write com.apple.dt.Xcode IDEDiagnosticsEnabled -bool YES

# Configure logging
echo "📝 Setting up enhanced logging..."
xcrun simctl spawn "$DEVICE_ID" log config --mode "level:debug" --subsystem com.claudecode.ui
xcrun simctl spawn "$DEVICE_ID" log config --mode "level:info" --subsystem com.apple.Network

# Create simulator snapshot for quick reset
echo "📸 Creating simulator snapshot..."
xcrun simctl shutdown "$DEVICE_ID"
xcrun simctl clone "$DEVICE_ID" "${SIMULATOR_NAME} - Snapshot"

# Reboot the simulator
xcrun simctl boot "$DEVICE_ID"

# Output configuration summary
echo ""
echo "✅ ${GREEN}iPhone 16 Pro Max Simulator Setup Complete!${NC}"
echo ""
echo "📋 Configuration Summary:"
echo "  • Name: $SIMULATOR_NAME"
echo "  • ID: $DEVICE_ID"
echo "  • Device Type: $DEVICE_TYPE"
echo "  • Runtime: $RUNTIME"
echo ""
echo "🎯 Next Steps:"
echo "  1. Open Xcode and select '$SIMULATOR_NAME' as your target"
echo "  2. Run: xcodebuild test -destination 'id=$DEVICE_ID'"
echo "  3. For network testing: Use network_profiles.json with your tests"
echo ""
echo "💡 Useful Commands:"
echo "  • Open simulator: open -a Simulator --args -CurrentDeviceUDID $DEVICE_ID"
echo "  • Reset simulator: xcrun simctl erase $DEVICE_ID"
echo "  • Shutdown: xcrun simctl shutdown $DEVICE_ID"
echo "  • Take screenshot: xcrun simctl io $DEVICE_ID screenshot test.png"
echo "  • Record video: xcrun simctl io $DEVICE_ID recordVideo test.mp4"
echo ""

# Save device ID for other scripts
echo "$DEVICE_ID" > .simulator_device_id
echo "$SIMULATOR_NAME" > .simulator_name

echo "Device configuration saved to .simulator_device_id and .simulator_name"