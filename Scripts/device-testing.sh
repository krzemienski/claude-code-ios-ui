#!/bin/bash

# Physical Device Testing Script for Claude Code iOS UI
# This script helps set up and test the app on real iPhone/iPad devices

set -e

echo "📱 Physical Device Testing Setup"
echo "================================"

# Configuration
PROJECT_PATH="ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj"
SCHEME="ClaudeCodeUI"
CONFIGURATION="Debug"
APP_BUNDLE_ID="com.claudecode.ui"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

# Function to list connected devices
list_devices() {
    echo ""
    echo "📱 Connected Devices:"
    echo "--------------------"
    
    xcrun devicectl list devices | grep -E "iPhone|iPad" || {
        print_warning "No devices found. Please connect your device via USB or enable WiFi debugging."
        return 1
    }
}

# Function to check device requirements
check_device() {
    local device_id=$1
    
    print_info "Checking device $device_id..."
    
    # Check iOS version
    ios_version=$(xcrun devicectl device info --device "$device_id" | grep "iOS" | awk '{print $2}')
    
    if [[ -z "$ios_version" ]]; then
        print_error "Could not determine iOS version"
        return 1
    fi
    
    # Check if iOS 17.0 or later
    major_version=$(echo "$ios_version" | cut -d. -f1)
    if [ "$major_version" -lt 17 ]; then
        print_error "Device requires iOS 17.0 or later (found: $ios_version)"
        return 1
    fi
    
    print_status "iOS version compatible: $ios_version"
}

# Function to prepare device
prepare_device() {
    local device_id=$1
    
    print_info "Preparing device for development..."
    
    # Enable developer mode if needed
    xcrun devicectl developer-mode enable --device "$device_id" 2>/dev/null || {
        print_warning "Developer mode may need to be enabled manually on device"
        echo "  Go to: Settings → Privacy & Security → Developer Mode"
    }
    
    # Trust computer if needed
    print_info "Please unlock your device and trust this computer if prompted"
    sleep 3
}

# Function to build for device
build_for_device() {
    local device_id=$1
    
    print_info "Building app for device..."
    
    xcodebuild build \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination "id=$device_id" \
        -derivedDataPath ./build/device \
        DEVELOPMENT_TEAM="YOUR_TEAM_ID" \
        CODE_SIGN_STYLE="Automatic" || {
            print_error "Build failed! Check your provisioning profile and team ID"
            return 1
        }
    
    print_status "Build completed successfully"
}

# Function to install on device
install_on_device() {
    local device_id=$1
    
    print_info "Installing app on device..."
    
    # Find the .app bundle
    APP_PATH=$(find ./build/device -name "ClaudeCodeUI.app" -type d | head -1)
    
    if [[ -z "$APP_PATH" ]]; then
        print_error "App bundle not found!"
        return 1
    fi
    
    # Install using devicectl
    xcrun devicectl app install --device "$device_id" "$APP_PATH" || {
        print_error "Installation failed!"
        return 1
    }
    
    print_status "App installed successfully"
}

# Function to launch app
launch_on_device() {
    local device_id=$1
    
    print_info "Launching app on device..."
    
    xcrun devicectl app launch --device "$device_id" "$APP_BUNDLE_ID" || {
        print_warning "Could not launch app automatically. Please launch manually."
    }
    
    print_status "App should now be running on your device"
}

# Function to stream device logs
stream_logs() {
    local device_id=$1
    
    print_info "Streaming device logs (Press Ctrl+C to stop)..."
    
    xcrun devicectl device log stream \
        --device "$device_id" \
        --process "ClaudeCodeUI" \
        --level debug
}

# Function to capture performance metrics
capture_metrics() {
    local device_id=$1
    
    print_info "Capturing performance metrics..."
    
    # Create metrics directory
    mkdir -p DeviceMetrics
    
    # Capture CPU usage
    xcrun xctrace record \
        --device "$device_id" \
        --template "CPU Profiler" \
        --output DeviceMetrics/cpu_profile.trace \
        --time-limit 30s \
        --target-name "ClaudeCodeUI" &
    
    local trace_pid=$!
    
    print_info "Recording 30 seconds of performance data..."
    wait $trace_pid
    
    print_status "Performance metrics saved to DeviceMetrics/"
}

# Function to run automated tests
run_device_tests() {
    local device_id=$1
    
    print_info "Running automated tests on device..."
    
    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "id=$device_id" \
        -only-testing:ClaudeCodeUITests \
        -resultBundlePath DeviceMetrics/test_results.xcresult || {
            print_warning "Some tests failed. Check results for details."
        }
    
    print_status "Test results saved to DeviceMetrics/test_results.xcresult"
}

# Main menu
show_menu() {
    echo ""
    echo "================================"
    echo "📱 Physical Device Testing Menu"
    echo "================================"
    echo "1. List connected devices"
    echo "2. Build and install on device"
    echo "3. Launch app on device"
    echo "4. Stream device logs"
    echo "5. Capture performance metrics"
    echo "6. Run automated tests"
    echo "7. Full test cycle (all of above)"
    echo "8. Setup WiFi debugging"
    echo "9. Exit"
    echo ""
    read -p "Select option (1-9): " option
    
    case $option in
        1)
            list_devices
            show_menu
            ;;
        2)
            list_devices
            read -p "Enter device ID: " device_id
            check_device "$device_id"
            prepare_device "$device_id"
            build_for_device "$device_id"
            install_on_device "$device_id"
            show_menu
            ;;
        3)
            list_devices
            read -p "Enter device ID: " device_id
            launch_on_device "$device_id"
            show_menu
            ;;
        4)
            list_devices
            read -p "Enter device ID: " device_id
            stream_logs "$device_id"
            show_menu
            ;;
        5)
            list_devices
            read -p "Enter device ID: " device_id
            capture_metrics "$device_id"
            show_menu
            ;;
        6)
            list_devices
            read -p "Enter device ID: " device_id
            run_device_tests "$device_id"
            show_menu
            ;;
        7)
            list_devices
            read -p "Enter device ID: " device_id
            check_device "$device_id"
            prepare_device "$device_id"
            build_for_device "$device_id"
            install_on_device "$device_id"
            launch_on_device "$device_id"
            capture_metrics "$device_id"
            run_device_tests "$device_id"
            show_menu
            ;;
        8)
            setup_wifi_debugging
            show_menu
            ;;
        9)
            echo "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option"
            show_menu
            ;;
    esac
}

# WiFi debugging setup
setup_wifi_debugging() {
    print_info "Setting up WiFi debugging..."
    echo ""
    echo "To enable WiFi debugging:"
    echo "1. Connect device via USB first"
    echo "2. Open Xcode → Window → Devices and Simulators"
    echo "3. Select your device"
    echo "4. Check 'Connect via network'"
    echo "5. Disconnect USB cable"
    echo ""
    echo "Device should now appear with (Network) suffix"
    
    read -p "Press Enter when ready..."
}

# Main execution
main() {
    # Check prerequisites
    if ! command -v xcrun &> /dev/null; then
        print_error "Xcode command line tools not found"
        exit 1
    fi
    
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode not found"
        exit 1
    fi
    
    # Show initial device list
    list_devices
    
    # Show menu
    show_menu
}

# Run main
main "$@"