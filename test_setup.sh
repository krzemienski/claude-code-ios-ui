#!/bin/bash

# iOS Claude Code UI - Complete Testing Setup Script
# This script starts the backend, boots simulator, builds app, and runs tests

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SIMULATOR_UUID="A707456B-44DB-472F-9722-C88153CDFFA1"  # iPhone 16 Pro Max
PROJECT_PATH="ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj"
SCHEME="ClaudeCodeUI"
BUNDLE_ID="com.claudecode.ui"
BACKEND_DIR="backend"
BACKEND_PORT=3004
LOG_DIR="test_logs"
BUILD_DIR="Build"

# Function to print colored output
print_status() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to check if process is running
is_running() {
    pgrep -f "$1" > /dev/null 2>&1
}

# Function to wait for port to be available
wait_for_port() {
    local port=$1
    local timeout=${2:-30}
    local elapsed=0
    
    print_status "Waiting for port $port to be available..."
    while ! nc -z localhost $port 2>/dev/null; do
        if [ $elapsed -ge $timeout ]; then
            print_error "Timeout waiting for port $port"
            return 1
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    print_success "Port $port is available"
}

# Function to cleanup on exit
cleanup() {
    print_status "Cleaning up..."
    
    # Kill background log streaming if running
    if [ ! -z "$LOG_PID" ]; then
        kill $LOG_PID 2>/dev/null || true
    fi
    
    # Stop backend server if we started it
    if [ ! -z "$BACKEND_PID" ]; then
        print_status "Stopping backend server..."
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    # Close simulator if requested
    if [ "$CLOSE_SIMULATOR" = "true" ]; then
        print_status "Closing simulator..."
        xcrun simctl shutdown $SIMULATOR_UUID 2>/dev/null || true
    fi
}

# Set up trap for cleanup
trap cleanup EXIT INT TERM

# Parse command line arguments
RUN_TESTS=false
RUN_INTEGRATION=false
RUN_UNIT=false
SKIP_BACKEND=false
SKIP_BUILD=false
CLOSE_SIMULATOR=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --tests)
            RUN_TESTS=true
            shift
            ;;
        --integration)
            RUN_INTEGRATION=true
            shift
            ;;
        --unit)
            RUN_UNIT=true
            shift
            ;;
        --skip-backend)
            SKIP_BACKEND=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --close-simulator)
            CLOSE_SIMULATOR=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --tests           Run all tests after setup"
            echo "  --integration     Run only integration tests"
            echo "  --unit            Run only unit tests"
            echo "  --skip-backend    Skip starting backend server"
            echo "  --skip-build      Skip building the app"
            echo "  --close-simulator Close simulator after tests"
            echo "  --verbose         Show detailed output"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create log directory
mkdir -p "$LOG_DIR"

print_status "Starting iOS Claude Code UI Testing Setup"
echo "================================================"

# Step 1: Start Backend Server
if [ "$SKIP_BACKEND" = false ]; then
    print_status "Starting backend server..."
    
    # Check if backend is already running
    if is_running "node.*server.js"; then
        print_warning "Backend server already running"
    else
        # Check if backend directory exists
        if [ ! -d "$BACKEND_DIR" ]; then
            print_error "Backend directory not found: $BACKEND_DIR"
            exit 1
        fi
        
        # Install dependencies if needed
        if [ ! -d "$BACKEND_DIR/node_modules" ]; then
            print_status "Installing backend dependencies..."
            cd "$BACKEND_DIR"
            npm install
            cd ..
        fi
        
        # Start backend server in background
        cd "$BACKEND_DIR"
        if [ "$VERBOSE" = true ]; then
            npm start 2>&1 | tee "../$LOG_DIR/backend.log" &
        else
            npm start > "../$LOG_DIR/backend.log" 2>&1 &
        fi
        BACKEND_PID=$!
        cd ..
        
        # Wait for backend to be ready
        wait_for_port $BACKEND_PORT
        print_success "Backend server started (PID: $BACKEND_PID)"
    fi
else
    print_warning "Skipping backend server startup"
fi

# Step 2: Boot iOS Simulator
print_status "Checking simulator status..."

# Check if simulator is already booted
if xcrun simctl list devices | grep -q "$SIMULATOR_UUID.*Booted"; then
    print_success "Simulator already booted"
else
    print_status "Booting simulator $SIMULATOR_UUID..."
    xcrun simctl boot $SIMULATOR_UUID
    
    # Wait for simulator to be ready
    sleep 5
    
    # Open Simulator app
    open -a Simulator
    print_success "Simulator booted"
fi

# Step 3: Start Log Streaming
print_status "Starting log streaming..."
xcrun simctl spawn $SIMULATOR_UUID log stream \
    --predicate 'processImagePath contains "ClaudeCodeUI"' \
    --level debug \
    > "$LOG_DIR/simulator.log" 2>&1 &
LOG_PID=$!
print_success "Log streaming started (PID: $LOG_PID)"

# Step 4: Build iOS App
if [ "$SKIP_BUILD" = false ]; then
    print_status "Building iOS app..."
    
    # Clean build directory
    rm -rf "$BUILD_DIR"
    
    # Build the app
    if [ "$VERBOSE" = true ]; then
        xcodebuild build \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
            -derivedDataPath "$BUILD_DIR" \
            | xcpretty
    else
        xcodebuild build \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
            -derivedDataPath "$BUILD_DIR" \
            -quiet
    fi
    
    if [ $? -eq 0 ]; then
        print_success "App built successfully"
    else
        print_error "Build failed"
        exit 1
    fi
else
    print_warning "Skipping app build"
fi

# Step 5: Install and Launch App
print_status "Installing app on simulator..."

# Find the app bundle
APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
    print_error "App bundle not found"
    exit 1
fi

# Install the app
xcrun simctl install $SIMULATOR_UUID "$APP_PATH"
print_success "App installed"

# Launch the app
print_status "Launching app..."
xcrun simctl launch $SIMULATOR_UUID $BUNDLE_ID
print_success "App launched"

# Wait for app to initialize
sleep 3

# Step 6: Run Tests (if requested)
if [ "$RUN_TESTS" = true ] || [ "$RUN_INTEGRATION" = true ] || [ "$RUN_UNIT" = true ]; then
    echo ""
    print_status "Running tests..."
    echo "================================================"
    
    TEST_ARGS=""
    
    if [ "$RUN_UNIT" = true ] || [ "$RUN_TESTS" = true ]; then
        TEST_ARGS="$TEST_ARGS -only-testing:ClaudeCodeUITests"
    fi
    
    if [ "$RUN_INTEGRATION" = true ] || [ "$RUN_TESTS" = true ]; then
        TEST_ARGS="$TEST_ARGS -only-testing:ClaudeCodeUIIntegrationTests"
    fi
    
    if [ "$VERBOSE" = true ]; then
        xcodebuild test \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
            -derivedDataPath "$BUILD_DIR" \
            $TEST_ARGS \
            | xcpretty --test
    else
        xcodebuild test \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
            -derivedDataPath "$BUILD_DIR" \
            $TEST_ARGS \
            -quiet
    fi
    
    if [ $? -eq 0 ]; then
        print_success "All tests passed"
    else
        print_error "Some tests failed"
        
        # Show recent logs on failure
        print_warning "Recent app logs:"
        tail -20 "$LOG_DIR/simulator.log"
        exit 1
    fi
fi

# Step 7: Health Check
echo ""
print_status "Performing health checks..."
echo "================================================"

# Check backend API
if curl -s -f "http://localhost:$BACKEND_PORT/api/health" > /dev/null 2>&1; then
    print_success "Backend API is healthy"
else
    print_warning "Backend API health check failed"
fi

# Check WebSocket endpoint
if curl -s -f -H "Connection: Upgrade" -H "Upgrade: websocket" \
    "http://localhost:$BACKEND_PORT/ws" 2>&1 | grep -q "Upgrade Required"; then
    print_success "WebSocket endpoint is available"
else
    print_warning "WebSocket endpoint check failed"
fi

# Check app is running
if xcrun simctl listapps $SIMULATOR_UUID | grep -q "$BUNDLE_ID"; then
    print_success "App is installed and ready"
else
    print_error "App not found on simulator"
fi

# Step 8: Show Summary
echo ""
print_status "Setup Complete!"
echo "================================================"
echo "Backend Server:  http://localhost:$BACKEND_PORT"
echo "WebSocket:       ws://localhost:$BACKEND_PORT/ws"
echo "Shell WebSocket: ws://localhost:$BACKEND_PORT/shell"
echo "Simulator UUID:  $SIMULATOR_UUID"
echo "Bundle ID:       $BUNDLE_ID"
echo ""
echo "Log files:"
echo "  Backend:   $LOG_DIR/backend.log"
echo "  Simulator: $LOG_DIR/simulator.log"
echo ""
echo "Useful commands:"
echo "  View logs:        tail -f $LOG_DIR/simulator.log"
echo "  Take screenshot:  xcrun simctl io $SIMULATOR_UUID screenshot screenshot.png"
echo "  Stop backend:     kill $BACKEND_PID"
echo "  Run tests:        $0 --tests"
echo ""

if [ "$RUN_TESTS" = false ]; then
    print_status "App is running. Press Ctrl+C to stop and cleanup."
    
    # Keep script running
    while true; do
        sleep 1
    done
fi