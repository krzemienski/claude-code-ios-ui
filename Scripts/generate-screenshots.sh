#!/bin/bash

# Screenshot Generation Script for App Store
# Captures screenshots from simulator for all required device sizes

set -e

echo "📸 Generating App Store Screenshots"
echo "==================================="

# Configuration
SIMULATORS=(
    "6520A438-0B1F-485B-9037-F346837B6D14:iPhone 16 Pro Max:1320x2868"
    "iPhone 15 Pro:1179x2556"
    "iPad Pro (12.9-inch):2048x2732"
)

# Screenshot scenarios
SCENARIOS=(
    "projects-list"
    "chat-interface"
    "terminal-view"
    "file-explorer"
    "settings-screen"
)

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

# Create screenshots directory
mkdir -p Screenshots/{iPhone-6.9,iPhone-6.1,iPad-12.9}

# Function to capture screenshot
capture_screenshot() {
    local device_id=$1
    local device_name=$2
    local scenario=$3
    local output_dir=$4
    
    echo -e "${GREEN}[📸]${NC} Capturing $scenario on $device_name..."
    
    # Boot simulator if needed
    xcrun simctl boot "$device_id" 2>/dev/null || true
    
    # Launch app
    xcrun simctl launch "$device_id" com.claudecode.ui
    
    # Wait for app to load
    sleep 3
    
    # Navigate to specific screen based on scenario
    case $scenario in
        "projects-list")
            # Already on main screen
            ;;
        "chat-interface")
            # Navigate to chat
            echo "Navigating to chat..."
            # Add navigation commands here
            ;;
        "terminal-view")
            # Navigate to terminal
            echo "Navigating to terminal..."
            # Add navigation commands here
            ;;
        "file-explorer")
            # Navigate to files
            echo "Navigating to files..."
            # Add navigation commands here
            ;;
        "settings-screen")
            # Navigate to settings
            echo "Navigating to settings..."
            # Add navigation commands here
            ;;
    esac
    
    # Capture screenshot
    xcrun simctl io "$device_id" screenshot "$output_dir/${scenario}.png"
    
    echo "  ✓ Screenshot saved: $output_dir/${scenario}.png"
}

# Generate screenshots for each device
for simulator_info in "${SIMULATORS[@]}"; do
    IFS=':' read -r device_id device_name resolution <<< "$simulator_info"
    
    # Determine output directory based on device
    if [[ $device_name == *"iPhone 16"* ]]; then
        output_dir="Screenshots/iPhone-6.9"
    elif [[ $device_name == *"iPhone 15"* ]]; then
        output_dir="Screenshots/iPhone-6.1"
    else
        output_dir="Screenshots/iPad-12.9"
    fi
    
    echo ""
    echo "Processing $device_name ($resolution)..."
    echo "-----------------------------------"
    
    # Capture all scenarios
    for scenario in "${SCENARIOS[@]}"; do
        capture_screenshot "$device_id" "$device_name" "$scenario" "$output_dir"
    done
done

echo ""
echo "==================================="
echo "✅ Screenshot generation complete!"
echo ""
echo "Screenshots saved in:"
echo "  • Screenshots/iPhone-6.9/ (iPhone 16 Pro Max)"
echo "  • Screenshots/iPhone-6.1/ (iPhone 15 Pro)"
echo "  • Screenshots/iPad-12.9/ (iPad Pro)"
echo ""
echo "Next steps:"
echo "1. Review and edit screenshots if needed"
echo "2. Add device frames using Figma or Screenshot"
echo "3. Upload to App Store Connect"