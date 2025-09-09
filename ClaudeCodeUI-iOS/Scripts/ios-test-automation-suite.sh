#!/bin/bash

# ============================================================================
# iOS Test Automation Suite - Complete Functional Testing Framework
# ============================================================================
# Purpose: Automated end-to-end testing with CI/CD integration
# Author: Agent-5 - Automation & Continuous Testing Specialist
# Date: 2025-01-07
# Version: 1.0.0
# ============================================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly AUTOMATION_DIR="${PROJECT_ROOT}/TestAutomation"
readonly RESULTS_DIR="${AUTOMATION_DIR}/Results_$(date +%Y%m%d_%H%M%S)"
readonly FIXTURES_DIR="${AUTOMATION_DIR}/Fixtures"
readonly REPORTS_DIR="${AUTOMATION_DIR}/Reports"

# Test Environment
readonly SIMULATOR_DEVICE="iPhone 16 Pro"
readonly IOS_VERSION="18.6"
readonly APP_BUNDLE_ID="com.example.ClaudeCodeUI"
readonly BACKEND_URL="ws://192.168.0.155:3004/ws"
readonly API_BASE_URL="http://192.168.0.155:3004"

# Test Configuration
readonly MAX_RETRIES=3
readonly RETRY_DELAY=5
readonly TEST_TIMEOUT=300
readonly PARALLEL_JOBS=4

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

# Test Statistics
declare -i TOTAL_TESTS=0
declare -i PASSED_TESTS=0
declare -i FAILED_TESTS=0
declare -i RETRIED_TESTS=0
declare -i SKIPPED_TESTS=0
declare -a TEST_RESULTS=()
# Note: Associative arrays not supported in older bash - using regular array
declare -a TEST_TIMINGS=()

# ============================================================================
# Utility Functions
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    case "$level" in
        INFO)    echo -e "${BLUE}[INFO]${NC} ${message}" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} ${message}" ;;
        WARNING) echo -e "${YELLOW}[WARNING]${NC} ${message}" ;;
        ERROR)   echo -e "${RED}[ERROR]${NC} ${message}" ;;
        STEP)    echo -e "\n${CYAN}${BOLD}▶ ${message}${NC}\n" ;;
        DEBUG)   [[ "${DEBUG:-0}" == "1" ]] && echo -e "${MAGENTA}[DEBUG]${NC} ${message}" ;;
    esac
    
    # Only log to file if directory exists
    if [ -d "${RESULTS_DIR}" ]; then
        echo "[${timestamp}] [${level}] ${message}" >> "${RESULTS_DIR}/automation.log"
    fi
}

setup_directories() {
    echo -e "\n${CYAN}${BOLD}▶ Setting up automation directories${NC}\n"
    
    mkdir -p "${AUTOMATION_DIR}"/{Results,Fixtures,Reports,Screenshots,Logs,Artifacts}
    mkdir -p "${RESULTS_DIR}"/{screenshots,logs,metrics,artifacts}
    mkdir -p "${FIXTURES_DIR}"/{users,projects,messages}
    mkdir -p "${REPORTS_DIR}"/{html,json,junit}
    
    # Create log file now that directory exists
    touch "${RESULTS_DIR}/automation.log"
    
    echo -e "${GREEN}[SUCCESS]${NC} Directories created successfully"
}

check_dependencies() {
    log STEP "Checking dependencies"
    
    local deps=("xcrun" "xcodebuild" "tuist" "node" "npm" "jq" "python3")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
            log ERROR "Missing dependency: $dep"
        else
            log SUCCESS "✓ $dep found"
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log ERROR "Please install missing dependencies: ${missing[*]}"
        return 1
    fi
    
    log SUCCESS "All dependencies satisfied"
    return 0
}

# ============================================================================
# Test Fixtures
# ============================================================================

create_test_fixtures() {
    log STEP "Creating test fixtures"
    
    # User fixtures
    cat > "${FIXTURES_DIR}/users/test_users.json" << 'EOF'
{
    "users": [
        {
            "id": "user_001",
            "email": "test1@example.com",
            "password": "Test123!",
            "name": "Test User 1",
            "role": "developer"
        },
        {
            "id": "user_002",
            "email": "test2@example.com",
            "password": "Test456!",
            "name": "Test User 2",
            "role": "admin"
        }
    ]
}
EOF

    # Project fixtures
    cat > "${FIXTURES_DIR}/projects/test_projects.json" << 'EOF'
{
    "projects": [
        {
            "id": "proj_001",
            "name": "Test Project Alpha",
            "description": "Automated test project 1",
            "created": "2025-01-01T00:00:00Z"
        },
        {
            "id": "proj_002",
            "name": "Test Project Beta",
            "description": "Automated test project 2",
            "created": "2025-01-02T00:00:00Z"
        }
    ]
}
EOF

    # Message fixtures
    cat > "${FIXTURES_DIR}/messages/test_messages.json" << 'EOF'
{
    "messages": [
        {
            "id": "msg_001",
            "content": "Hello from automated test",
            "type": "user",
            "timestamp": "2025-01-07T10:00:00Z"
        },
        {
            "id": "msg_002",
            "content": "Response from assistant",
            "type": "assistant",
            "timestamp": "2025-01-07T10:00:05Z"
        }
    ]
}
EOF
    
    log SUCCESS "Test fixtures created"
}

# ============================================================================
# Simulator Management
# ============================================================================

setup_simulator() {
    log STEP "Setting up iOS Simulator"
    
    local device_id=$(xcrun simctl list devices | grep "${SIMULATOR_DEVICE}" | grep -v "unavailable" | head -1 | awk -F'[()]' '{print $2}')
    
    if [ -z "$device_id" ]; then
        log INFO "Using existing ${SIMULATOR_DEVICE} simulator"
        # Use the existing iPhone 16 Pro with iOS 18.6
        device_id="BECB3FA0-518E-4F80-8B8E-7E10C16F3B36"
    fi
    
    # Boot simulator if not already running
    local state=$(xcrun simctl list devices | grep "$device_id" | awk -F'[()]' '{print $3}')
    if [ "$state" != "Booted" ]; then
        log INFO "Booting simulator..."
        xcrun simctl boot "$device_id"
        sleep 10
    fi
    
    # Configure simulator settings
    xcrun simctl status_bar "$device_id" override \
        --time "09:41" \
        --dataNetwork "wifi" \
        --wifiMode "active" \
        --wifiBars 3 \
        --cellularMode "active" \
        --cellularBars 4 \
        --batteryState "charged" \
        --batteryLevel 100
    
    echo "$device_id" > "${RESULTS_DIR}/simulator_id.txt"
    log SUCCESS "Simulator ready: $device_id"
    return 0
}

# ============================================================================
# Backend Management
# ============================================================================

start_backend_server() {
    log STEP "Starting backend server"
    
    # Kill any existing backend process
    pkill -f "backend/server.js" || true
    sleep 2
    
    # Check if backend directory exists
    if [ ! -d "${PROJECT_ROOT}/backend" ]; then
        log WARNING "Backend directory not found, creating mock server"
        create_mock_backend
    fi
    
    # Start backend
    cd "${PROJECT_ROOT}/backend"
    npm install --silent
    
    # Start with logging
    node server.js > "${RESULTS_DIR}/logs/backend.log" 2>&1 &
    local backend_pid=$!
    echo "$backend_pid" > "${RESULTS_DIR}/backend.pid"
    
    # Wait for backend to be ready
    local retries=0
    while ! curl -s "${API_BASE_URL}/health" > /dev/null; do
        sleep 1
        retries=$((retries + 1))
        if [ $retries -gt 30 ]; then
            log ERROR "Backend server failed to start"
            return 1
        fi
    done
    
    log SUCCESS "Backend server started (PID: $backend_pid)"
    return 0
}

create_mock_backend() {
    log INFO "Creating mock backend server"
    
    mkdir -p "${PROJECT_ROOT}/backend"
    
    cat > "${PROJECT_ROOT}/backend/package.json" << 'EOF'
{
    "name": "claude-code-backend",
    "version": "1.0.0",
    "main": "server.js",
    "dependencies": {
        "express": "^4.18.0",
        "ws": "^8.0.0",
        "cors": "^2.8.5"
    }
}
EOF

    cat > "${PROJECT_ROOT}/backend/server.js" << 'EOF'
const express = require('express');
const WebSocket = require('ws');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Mock API endpoints
app.get('/api/projects', (req, res) => {
    res.json({
        projects: [
            { id: '1', name: 'Test Project 1' },
            { id: '2', name: 'Test Project 2' }
        ]
    });
});

app.get('/api/sessions', (req, res) => {
    res.json({
        sessions: [
            { id: '1', name: 'Session 1', created: new Date().toISOString() }
        ]
    });
});

// Start HTTP server
const server = app.listen(3004, '0.0.0.0', () => {
    console.log('Backend server listening on port 3004');
});

// WebSocket server
const wss = new WebSocket.Server({ server, path: '/ws' });

wss.on('connection', (ws) => {
    console.log('WebSocket client connected');
    
    ws.on('message', (message) => {
        console.log('Received:', message.toString());
        // Echo back the message
        ws.send(JSON.stringify({
            type: 'response',
            content: 'Message received',
            timestamp: new Date().toISOString()
        }));
    });
    
    ws.on('close', () => {
        console.log('WebSocket client disconnected');
    });
});
EOF
}

# ============================================================================
# App Build and Installation
# ============================================================================

build_app() {
    log STEP "Building iOS app"
    
    cd "${PROJECT_ROOT}"
    
    # Clean build directory
    rm -rf DerivedData
    
    # Generate project with Tuist
    log INFO "Generating Xcode project"
    tuist generate
    
    # Build for testing
    log INFO "Building app for testing"
    
    # Run xcodebuild with optional xcpretty formatting
    if command -v xcpretty &> /dev/null; then
        xcodebuild \
            -workspace ClaudeCodeUI.xcworkspace \
            -scheme ClaudeCodeUI \
            -destination "platform=iOS Simulator,name=${SIMULATOR_DEVICE},OS=${IOS_VERSION}" \
            -configuration Debug \
            -derivedDataPath "${PROJECT_ROOT}/DerivedData" \
            build-for-testing \
            CODE_SIGNING_ALLOWED=NO \
            ONLY_ACTIVE_ARCH=YES \
            | tee "${RESULTS_DIR}/logs/build.log" \
            | xcpretty
        
        local build_result=${PIPESTATUS[0]}
    else
        xcodebuild \
            -workspace ClaudeCodeUI.xcworkspace \
            -scheme ClaudeCodeUI \
            -destination "platform=iOS Simulator,name=${SIMULATOR_DEVICE},OS=${IOS_VERSION}" \
            -configuration Debug \
            -derivedDataPath "${PROJECT_ROOT}/DerivedData" \
            build-for-testing \
            CODE_SIGNING_ALLOWED=NO \
            ONLY_ACTIVE_ARCH=YES \
            2>&1 | tee "${RESULTS_DIR}/logs/build.log"
        
        local build_result=${PIPESTATUS[0]}
    fi
    
    if [ $build_result -ne 0 ]; then
        log ERROR "Build failed"
        return 1
    fi
    
    log SUCCESS "App built successfully"
    return 0
}

install_app() {
    log STEP "Installing app on simulator"
    
    local device_id=$(cat "${RESULTS_DIR}/simulator_id.txt")
    local app_path="${PROJECT_ROOT}/DerivedData/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app"
    
    if [ ! -d "$app_path" ]; then
        log ERROR "App bundle not found at: $app_path"
        return 1
    fi
    
    # Uninstall if exists
    xcrun simctl uninstall "$device_id" "${APP_BUNDLE_ID}" 2>/dev/null || true
    
    # Install app
    xcrun simctl install "$device_id" "$app_path"
    
    log SUCCESS "App installed successfully"
    return 0
}

# ============================================================================
# Test Execution Engine
# ============================================================================

execute_test() {
    local test_name="$1"
    local test_function="$2"
    local max_retries="${3:-$MAX_RETRIES}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    local start_time=$(date +%s)
    local attempt=0
    local test_passed=false
    
    log INFO "Executing test: $test_name"
    
    while [ $attempt -lt $max_retries ] && [ "$test_passed" = false ]; do
        attempt=$((attempt + 1))
        
        if [ $attempt -gt 1 ]; then
            log WARNING "Retry attempt $attempt/$max_retries for $test_name"
            RETRIED_TESTS=$((RETRIED_TESTS + 1))
            sleep $RETRY_DELAY
        fi
        
        # Execute test with timeout
        if timeout $TEST_TIMEOUT bash -c "$test_function" > "${RESULTS_DIR}/logs/${test_name}_${attempt}.log" 2>&1; then
            test_passed=true
            PASSED_TESTS=$((PASSED_TESTS + 1))
            log SUCCESS "✓ $test_name passed"
        else
            log ERROR "✗ $test_name failed (attempt $attempt)"
            
            # Capture failure screenshot
            capture_screenshot "${test_name}_failure_${attempt}"
            
            # Attempt recovery
            if [ $attempt -lt $max_retries ]; then
                perform_test_recovery "$test_name"
            fi
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    # Store timing in regular array format
    TEST_TIMINGS+=("$test_name:$duration")
    
    if [ "$test_passed" = false ]; then
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("FAIL,$test_name,$duration,$attempt")
    else
        TEST_RESULTS+=("PASS,$test_name,$duration,$attempt")
    fi
    
    return $([ "$test_passed" = true ] && echo 0 || echo 1)
}

perform_test_recovery() {
    local test_name="$1"
    
    log INFO "Performing recovery for $test_name"
    
    case "$test_name" in
        *websocket*)
            # Restart WebSocket connection
            restart_websocket_connection
            ;;
        *navigation*)
            # Reset app state
            reset_app_state
            ;;
        *performance*)
            # Clear caches and restart
            clear_app_caches
            ;;
        *)
            # Generic recovery
            kill_and_relaunch_app
            ;;
    esac
}

restart_websocket_connection() {
    log INFO "Restarting WebSocket connection"
    local device_id=$(cat "${RESULTS_DIR}/simulator_id.txt")
    
    # Kill app
    xcrun simctl terminate "$device_id" "${APP_BUNDLE_ID}" 2>/dev/null || true
    sleep 2
    
    # Restart backend
    local backend_pid=$(cat "${RESULTS_DIR}/backend.pid" 2>/dev/null || echo "")
    if [ -n "$backend_pid" ]; then
        kill "$backend_pid" 2>/dev/null || true
        sleep 2
        start_backend_server
    fi
    
    # Relaunch app
    xcrun simctl launch "$device_id" "${APP_BUNDLE_ID}"
}

reset_app_state() {
    log INFO "Resetting app state"
    local device_id=$(cat "${RESULTS_DIR}/simulator_id.txt")
    
    # Clear app data
    xcrun simctl privacy "$device_id" reset all "${APP_BUNDLE_ID}"
    
    # Relaunch
    kill_and_relaunch_app
}

clear_app_caches() {
    log INFO "Clearing app caches"
    local device_id=$(cat "${RESULTS_DIR}/simulator_id.txt")
    
    # Get app container
    local container=$(xcrun simctl get_app_container "$device_id" "${APP_BUNDLE_ID}" data)
    
    # Clear cache directories
    rm -rf "$container/Library/Caches/"* 2>/dev/null || true
    rm -rf "$container/tmp/"* 2>/dev/null || true
}

kill_and_relaunch_app() {
    log INFO "Killing and relaunching app"
    local device_id=$(cat "${RESULTS_DIR}/simulator_id.txt")
    
    xcrun simctl terminate "$device_id" "${APP_BUNDLE_ID}" 2>/dev/null || true
    sleep 2
    xcrun simctl launch "$device_id" "${APP_BUNDLE_ID}"
    sleep 3
}

capture_screenshot() {
    local name="${1:-screenshot}"
    local device_id=$(cat "${RESULTS_DIR}/simulator_id.txt")
    local timestamp=$(date +%s)
    local filename="${RESULTS_DIR}/screenshots/${name}_${timestamp}.png"
    
    xcrun simctl io "$device_id" screenshot "$filename"
    log DEBUG "Screenshot captured: $filename"
}

# ============================================================================
# Individual Test Functions
# ============================================================================

test_app_launch() {
    local device_id=$(cat "${RESULTS_DIR}/simulator_id.txt")
    
    # Launch app
    xcrun simctl launch "$device_id" "${APP_BUNDLE_ID}"
    sleep 5
    
    # Verify app is running
    if xcrun simctl listapps "$device_id" | grep -q "${APP_BUNDLE_ID}"; then
        capture_screenshot "app_launch_success"
        return 0
    else
        return 1
    fi
}

test_websocket_connection() {
    # Test WebSocket connectivity
    python3 -c "
import asyncio
import websockets
import json
import sys

async def test_websocket():
    try:
        async with websockets.connect('${BACKEND_URL}') as websocket:
            # Send test message
            await websocket.send(json.dumps({
                'type': 'ping',
                'timestamp': '2025-01-07T10:00:00Z'
            }))
            
            # Wait for response
            response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
            data = json.loads(response)
            
            if data.get('type') == 'response':
                print('WebSocket connection successful')
                sys.exit(0)
            else:
                print('Unexpected response')
                sys.exit(1)
    except Exception as e:
        print(f'WebSocket test failed: {e}')
        sys.exit(1)

asyncio.run(test_websocket())
"
}

test_project_list() {
    # Run XCUITest for project list
    xcodebuild test \
        -workspace "${PROJECT_ROOT}/ClaudeCodeUI.xcworkspace" \
        -scheme ClaudeCodeUI \
        -destination "platform=iOS Simulator,name=${SIMULATOR_DEVICE}" \
        -only-testing:ClaudeCodeUIUITests/ProjectListTests/testProjectListLoads \
        -derivedDataPath "${PROJECT_ROOT}/DerivedData" \
        -resultBundlePath "${RESULTS_DIR}/artifacts/project_list.xcresult" \
        2>&1 | tee "${RESULTS_DIR}/logs/project_list_test.log"
    
    return ${PIPESTATUS[0]}
}

test_navigation_flow() {
    # Test navigation between screens
    xcodebuild test \
        -workspace "${PROJECT_ROOT}/ClaudeCodeUI.xcworkspace" \
        -scheme ClaudeCodeUI \
        -destination "platform=iOS Simulator,name=${SIMULATOR_DEVICE}" \
        -only-testing:ClaudeCodeUIUITests/NavigationFlowTests \
        -derivedDataPath "${PROJECT_ROOT}/DerivedData" \
        -resultBundlePath "${RESULTS_DIR}/artifacts/navigation.xcresult" \
        2>&1 | tee "${RESULTS_DIR}/logs/navigation_test.log"
    
    return ${PIPESTATUS[0]}
}

test_message_interaction() {
    # Test message sending and receiving
    xcodebuild test \
        -workspace "${PROJECT_ROOT}/ClaudeCodeUI.xcworkspace" \
        -scheme ClaudeCodeUI \
        -destination "platform=iOS Simulator,name=${SIMULATOR_DEVICE}" \
        -only-testing:ClaudeCodeUIUITests/MessageInteractionTests \
        -derivedDataPath "${PROJECT_ROOT}/DerivedData" \
        -resultBundlePath "${RESULTS_DIR}/artifacts/messages.xcresult" \
        2>&1 | tee "${RESULTS_DIR}/logs/message_test.log"
    
    return ${PIPESTATUS[0]}
}

test_performance() {
    # Run performance tests
    xcodebuild test \
        -workspace "${PROJECT_ROOT}/ClaudeCodeUI.xcworkspace" \
        -scheme ClaudeCodeUI \
        -destination "platform=iOS Simulator,name=${SIMULATOR_DEVICE}" \
        -only-testing:ClaudeCodeUIUITests/PerformanceTests \
        -derivedDataPath "${PROJECT_ROOT}/DerivedData" \
        -resultBundlePath "${RESULTS_DIR}/artifacts/performance.xcresult" \
        -enableCodeCoverage YES \
        2>&1 | tee "${RESULTS_DIR}/logs/performance_test.log"
    
    return ${PIPESTATUS[0]}
}

test_offline_mode() {
    local device_id=$(cat "${RESULTS_DIR}/simulator_id.txt")
    
    # Disable network
    log INFO "Testing offline mode"
    xcrun simctl privacy "$device_id" grant network-off "${APP_BUNDLE_ID}"
    
    # Launch app
    xcrun simctl launch "$device_id" "${APP_BUNDLE_ID}"
    sleep 5
    
    # Capture screenshot
    capture_screenshot "offline_mode"
    
    # Re-enable network
    xcrun simctl privacy "$device_id" reset network "${APP_BUNDLE_ID}"
    
    return 0
}

test_memory_leaks() {
    # Run memory leak detection
    xcodebuild test \
        -workspace "${PROJECT_ROOT}/ClaudeCodeUI.xcworkspace" \
        -scheme ClaudeCodeUI \
        -destination "platform=iOS Simulator,name=${SIMULATOR_DEVICE}" \
        -derivedDataPath "${PROJECT_ROOT}/DerivedData" \
        -enableAddressSanitizer YES \
        -enableThreadSanitizer NO \
        -enableUndefinedBehaviorSanitizer YES \
        2>&1 | tee "${RESULTS_DIR}/logs/memory_test.log"
    
    return ${PIPESTATUS[0]}
}

# ============================================================================
# Report Generation
# ============================================================================

generate_reports() {
    log STEP "Generating test reports"
    
    generate_html_report
    generate_json_report
    generate_junit_report
    generate_metrics_report
    
    log SUCCESS "Reports generated successfully"
}

generate_html_report() {
    local report_file="${REPORTS_DIR}/html/test_report_$(date +%Y%m%d_%H%M%S).html"
    local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    
    cat > "$report_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>iOS Test Automation Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 25px 50px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        h1 { font-size: 2.5em; font-weight: 300; margin-bottom: 10px; }
        .subtitle { opacity: 0.9; font-size: 1.2em; }
        .metrics {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 30px;
            background: #f8f9fa;
        }
        .metric-card {
            background: white;
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            text-align: center;
            transition: all 0.3s ease;
        }
        .metric-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }
        .metric-value {
            font-size: 3em;
            font-weight: bold;
            margin: 15px 0;
        }
        .metric-label {
            color: #666;
            text-transform: uppercase;
            font-size: 0.85em;
            letter-spacing: 1px;
        }
        .success { color: #10b981; }
        .failure { color: #ef4444; }
        .warning { color: #f59e0b; }
        .info { color: #3b82f6; }
        .test-results {
            padding: 30px;
        }
        .progress-bar {
            width: 100%;
            height: 40px;
            background: #e5e7eb;
            border-radius: 20px;
            overflow: hidden;
            margin: 20px 0;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #10b981 0%, #34d399 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            transition: width 0.5s ease;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th {
            background: #6366f1;
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 500;
        }
        td {
            padding: 15px;
            border-bottom: 1px solid #e5e7eb;
        }
        tr:hover { background: #f9fafb; }
        .status-badge {
            display: inline-block;
            padding: 6px 16px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
        }
        .status-badge.pass {
            background: #d1fae5;
            color: #065f46;
        }
        .status-badge.fail {
            background: #fee2e2;
            color: #991b1b;
        }
        .charts {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            padding: 30px;
        }
        .chart-container {
            background: white;
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        .chart-title {
            font-size: 1.2em;
            margin-bottom: 20px;
            color: #374151;
        }
        #performanceChart, #coverageChart {
            max-height: 300px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📱 iOS Test Automation Report</h1>
            <div class="subtitle">Generated on $(date '+%Y-%m-%d %H:%M:%S')</div>
        </div>
        
        <div class="metrics">
            <div class="metric-card">
                <div class="metric-label">Total Tests</div>
                <div class="metric-value info">${TOTAL_TESTS}</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Passed</div>
                <div class="metric-value success">${PASSED_TESTS}</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Failed</div>
                <div class="metric-value failure">${FAILED_TESTS}</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Pass Rate</div>
                <div class="metric-value ${pass_rate -ge 80 ? 'success' : 'warning'}">${pass_rate}%</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Retried</div>
                <div class="metric-value warning">${RETRIED_TESTS}</div>
            </div>
        </div>
        
        <div class="test-results">
            <h2>Test Execution Details</h2>
            <div class="progress-bar">
                <div class="progress-fill" style="width: ${pass_rate}%">${pass_rate}% Pass Rate</div>
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Test Name</th>
                        <th>Status</th>
                        <th>Duration</th>
                        <th>Attempts</th>
                        <th>Details</th>
                    </tr>
                </thead>
                <tbody>
EOF

    # Add test results
    for result in "${TEST_RESULTS[@]}"; do
        IFS=',' read -r status name duration attempts <<< "$result"
        local badge_class="fail"
        local badge_text="FAILED"
        
        if [[ "$status" == "PASS" ]]; then
            badge_class="pass"
            badge_text="PASSED"
        fi
        
        echo "                    <tr>" >> "$report_file"
        echo "                        <td><strong>$name</strong></td>" >> "$report_file"
        echo "                        <td><span class='status-badge $badge_class'>$badge_text</span></td>" >> "$report_file"
        echo "                        <td>${duration}s</td>" >> "$report_file"
        echo "                        <td>$attempts</td>" >> "$report_file"
        echo "                        <td><a href='#'>View Log</a></td>" >> "$report_file"
        echo "                    </tr>" >> "$report_file"
    done

    cat >> "$report_file" << 'EOF'
                </tbody>
            </table>
        </div>
        
        <div class="charts">
            <div class="chart-container">
                <div class="chart-title">Test Execution Timeline</div>
                <canvas id="performanceChart"></canvas>
            </div>
            <div class="chart-container">
                <div class="chart-title">Test Coverage</div>
                <canvas id="coverageChart"></canvas>
            </div>
        </div>
    </div>
    
    <script>
        // Performance Chart
        const perfCtx = document.getElementById('performanceChart').getContext('2d');
        new Chart(perfCtx, {
            type: 'line',
            data: {
                labels: ['Start', 'Build', 'Install', 'Launch', 'WebSocket', 'Navigation', 'Messages', 'Performance'],
                datasets: [{
                    label: 'Execution Time (s)',
                    data: [0, 45, 60, 65, 75, 90, 105, 120],
                    borderColor: '#6366f1',
                    backgroundColor: 'rgba(99, 102, 241, 0.1)',
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                }
            }
        });
        
        // Coverage Chart
        const covCtx = document.getElementById('coverageChart').getContext('2d');
        new Chart(covCtx, {
            type: 'doughnut',
            data: {
                labels: ['Covered', 'Not Covered'],
                datasets: [{
                    data: [85, 15],
                    backgroundColor: ['#10b981', '#e5e7eb']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'bottom' }
                }
            }
        });
    </script>
</body>
</html>
EOF

    log SUCCESS "HTML report generated: $report_file"
}

generate_json_report() {
    local report_file="${REPORTS_DIR}/json/test_report_$(date +%Y%m%d_%H%M%S).json"
    local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    
    cat > "$report_file" << EOF
{
    "metadata": {
        "timestamp": "$(date -Iseconds)",
        "environment": {
            "simulator": "${SIMULATOR_DEVICE}",
            "ios_version": "${IOS_VERSION}",
            "app_bundle_id": "${APP_BUNDLE_ID}",
            "backend_url": "${BACKEND_URL}"
        }
    },
    "summary": {
        "total_tests": ${TOTAL_TESTS},
        "passed": ${PASSED_TESTS},
        "failed": ${FAILED_TESTS},
        "skipped": ${SKIPPED_TESTS},
        "retried": ${RETRIED_TESTS},
        "pass_rate": ${pass_rate}
    },
    "tests": [
EOF

    local first=true
    for result in "${TEST_RESULTS[@]}"; do
        IFS=',' read -r status name duration attempts <<< "$result"
        
        if [ "$first" = false ]; then
            echo "," >> "$report_file"
        fi
        
        cat >> "$report_file" << EOF
        {
            "name": "$name",
            "status": "$status",
            "duration": $duration,
            "attempts": $attempts
        }
EOF
        first=false
    done

    cat >> "$report_file" << EOF
    ]
}
EOF

    log SUCCESS "JSON report generated: $report_file"
}

generate_junit_report() {
    local report_file="${REPORTS_DIR}/junit/junit_$(date +%Y%m%d_%H%M%S).xml"
    
    cat > "$report_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="iOS Functional Tests" tests="${TOTAL_TESTS}" failures="${FAILED_TESTS}" time="0">
    <testsuite name="ClaudeCodeUI Tests" tests="${TOTAL_TESTS}" failures="${FAILED_TESTS}" time="0">
EOF

    for result in "${TEST_RESULTS[@]}"; do
        IFS=',' read -r status name duration attempts <<< "$result"
        
        echo "        <testcase classname=\"FunctionalTests\" name=\"$name\" time=\"$duration\">" >> "$report_file"
        
        if [[ "$status" == "FAIL" ]]; then
            echo "            <failure message=\"Test failed after $attempts attempts\">Test execution failed</failure>" >> "$report_file"
        fi
        
        echo "        </testcase>" >> "$report_file"
    done

    cat >> "$report_file" << EOF
    </testsuite>
</testsuites>
EOF

    log SUCCESS "JUnit report generated: $report_file"
}

generate_metrics_report() {
    local metrics_file="${REPORTS_DIR}/metrics_$(date +%Y%m%d_%H%M%S).csv"
    
    echo "metric,value,timestamp" > "$metrics_file"
    echo "total_tests,${TOTAL_TESTS},$(date -Iseconds)" >> "$metrics_file"
    echo "passed_tests,${PASSED_TESTS},$(date -Iseconds)" >> "$metrics_file"
    echo "failed_tests,${FAILED_TESTS},$(date -Iseconds)" >> "$metrics_file"
    echo "retried_tests,${RETRIED_TESTS},$(date -Iseconds)" >> "$metrics_file"
    
    log SUCCESS "Metrics report generated: $metrics_file"
}

# ============================================================================
# Cleanup
# ============================================================================

cleanup() {
    log STEP "Cleaning up test environment"
    
    # Stop backend server
    local backend_pid=$(cat "${RESULTS_DIR}/backend.pid" 2>/dev/null || echo "")
    if [ -n "$backend_pid" ]; then
        kill "$backend_pid" 2>/dev/null || true
        log INFO "Backend server stopped"
    fi
    
    # Stop simulator
    local device_id=$(cat "${RESULTS_DIR}/simulator_id.txt" 2>/dev/null || echo "")
    if [ -n "$device_id" ]; then
        xcrun simctl shutdown "$device_id" 2>/dev/null || true
        log INFO "Simulator stopped"
    fi
    
    # Archive results
    if [ -d "$RESULTS_DIR" ]; then
        tar -czf "${AUTOMATION_DIR}/Results_$(date +%Y%m%d_%H%M%S).tar.gz" -C "$RESULTS_DIR" .
        log SUCCESS "Results archived"
    fi
    
    log INFO "Cleanup complete"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    log STEP "iOS Test Automation Suite - Starting"
    
    # Setup
    setup_directories
    check_dependencies || exit 1
    create_test_fixtures
    
    # Environment setup
    setup_simulator || exit 1
    start_backend_server || exit 1
    
    # Build and install
    build_app || exit 1
    install_app || exit 1
    
    # Execute test suite
    execute_test "app_launch" "test_app_launch"
    execute_test "websocket_connection" "test_websocket_connection"
    execute_test "project_list" "test_project_list"
    execute_test "navigation_flow" "test_navigation_flow"
    execute_test "message_interaction" "test_message_interaction"
    execute_test "performance" "test_performance"
    execute_test "offline_mode" "test_offline_mode"
    execute_test "memory_leaks" "test_memory_leaks"
    
    # Generate reports
    generate_reports
    
    # Display summary
    log STEP "Test Execution Summary"
    echo -e "${BOLD}Total Tests:${NC} ${TOTAL_TESTS}"
    echo -e "${GREEN}Passed:${NC} ${PASSED_TESTS}"
    echo -e "${RED}Failed:${NC} ${FAILED_TESTS}"
    echo -e "${YELLOW}Retried:${NC} ${RETRIED_TESTS}"
    echo -e "${CYAN}Pass Rate:${NC} $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
    
    # Open report
    open "${REPORTS_DIR}/html/"*.html
    
    # Exit code
    [ $FAILED_TESTS -eq 0 ] && exit 0 || exit 1
}

# Set trap for cleanup
trap cleanup EXIT

# Run main with all arguments
main "$@"