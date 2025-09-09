#!/bin/bash

# ============================================
# iOS Functional Test Suite Runner v2.0
# ============================================
# Automated test execution with backend integration
# Author: Claude Code Integration Agent
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="$(dirname "$0")/../../backend"
BACKEND_URL="${BACKEND_URL:-http://192.168.0.155:3004}"
BACKEND_HEALTH_URL="$BACKEND_URL/health"
TEST_RESULTS_DIR="$(dirname "$0")/../TestResults"
XCRESULT_FILE="$TEST_RESULTS_DIR/FunctionalTests.xcresult"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DERIVED_DATA_PATH="$(dirname "$0")/../DerivedData"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if backend is already running
check_backend() {
    if curl -s -f "$BACKEND_HEALTH_URL" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Start backend if not running
start_backend() {
    if check_backend; then
        log_info "Backend is already running at $BACKEND_URL"
        return 0
    fi
    
    log_info "Starting backend server..."
    
    if [ ! -d "$BACKEND_DIR" ]; then
        log_error "Backend directory not found at $BACKEND_DIR"
        exit 1
    fi
    
    cd "$BACKEND_DIR"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        log_info "Installing backend dependencies..."
        npm install
    fi
    
    # Start backend in background
    npm start > "$TEST_RESULTS_DIR/backend.log" 2>&1 &
    BACKEND_PID=$!
    
    log_info "Backend started with PID: $BACKEND_PID"
    
    # Wait for backend to be ready
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if check_backend; then
            log_info "Backend is ready!"
            return 0
        fi
        
        log_info "Waiting for backend to start... (attempt $((attempt + 1))/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "Backend failed to start after $max_attempts attempts"
    if [ -n "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    exit 1
}

# Build the app for testing
build_for_testing() {
    log_info "🔨 Building app for testing..."
    
    xcodebuild build-for-testing \
        -workspace "../ClaudeCodeUI.xcworkspace" \
        -scheme "ClaudeCodeUI" \
        -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        2>&1 | tee "$TEST_RESULTS_DIR/build.log"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_info "✅ Build completed successfully"
        return 0
    else
        log_error "Build failed"
        return 1
    fi
}

# Run the tests
run_tests() {
    log_info "🧪 Running functional tests..."
    
    # Create results directory
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Build first
    if ! build_for_testing; then
        return 1
    fi
    
    # Run test suites in sequence
    local overall_status=0
    
    # Unit Tests
    log_info "Running Unit Tests..."
    xcodebuild test-without-building \
        -workspace "../ClaudeCodeUI.xcworkspace" \
        -scheme "ClaudeCodeUI" \
        -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -resultBundlePath "$TEST_RESULTS_DIR/UnitTests_${TIMESTAMP}.xcresult" \
        -only-testing:ClaudeCodeUITests \
        2>&1 | tee "$TEST_RESULTS_DIR/unit-tests.log"
    
    [ ${PIPESTATUS[0]} -ne 0 ] && overall_status=1
    
    # Integration Tests
    log_info "Running Integration Tests..."
    xcodebuild test-without-building \
        -workspace "../ClaudeCodeUI.xcworkspace" \
        -scheme "ClaudeCodeUI" \
        -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -resultBundlePath "$TEST_RESULTS_DIR/IntegrationTests_${TIMESTAMP}.xcresult" \
        -only-testing:ClaudeCodeUIIntegrationTests \
        2>&1 | tee "$TEST_RESULTS_DIR/integration-tests.log"
    
    [ ${PIPESTATUS[0]} -ne 0 ] && overall_status=1
    
    # UI Tests
    log_info "Running UI Tests..."
    xcodebuild test-without-building \
        -workspace "../ClaudeCodeUI.xcworkspace" \
        -scheme "ClaudeCodeUI" \
        -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -resultBundlePath "$TEST_RESULTS_DIR/UITests_${TIMESTAMP}.xcresult" \
        -only-testing:ClaudeCodeUIUITests \
        2>&1 | tee "$TEST_RESULTS_DIR/ui-tests.log"
    
    [ ${PIPESTATUS[0]} -ne 0 ] && overall_status=1
    
    return $overall_status
}

# Generate test report
generate_report() {
    log_info "Generating test report..."
    
    if [ -f "$XCRESULT_FILE" ]; then
        # Extract test results as JSON
        xcrun xcresulttool get \
            --format json \
            --path "$XCRESULT_FILE" \
            > "$TEST_RESULTS_DIR/test-results.json"
        
        # Generate human-readable summary
        generate_summary
    else
        log_warning "No test results found at $XCRESULT_FILE"
    fi
}

# Generate test summary
generate_summary() {
    local summary_file="$TEST_RESULTS_DIR/test-summary_${TIMESTAMP}.md"
    
    # Parse test results from logs
    local unit_passed=$(grep -c "Test Suite.*passed" "$TEST_RESULTS_DIR/unit-tests.log" 2>/dev/null || echo "0")
    local integration_passed=$(grep -c "Test Suite.*passed" "$TEST_RESULTS_DIR/integration-tests.log" 2>/dev/null || echo "0")
    local ui_passed=$(grep -c "Test Suite.*passed" "$TEST_RESULTS_DIR/ui-tests.log" 2>/dev/null || echo "0")
    
    # Parse JSON results if Python parser is available
    if [ -f "$(dirname "$0")/parse_results.py" ]; then
        python3 "$(dirname "$0")/parse_results.py" "$TEST_RESULTS_DIR" > "$TEST_RESULTS_DIR/parsed-results.txt"
    fi
    
    # Generate comprehensive summary
    cat > "$summary_file" << EOF
# 📊 iOS Functional Test Report

Generated: $(date)

## 🌐 Environment
- **Backend URL**: $BACKEND_URL
- **Simulator**: iPhone 15
- **Build Configuration**: Debug
- **Test Timestamp**: $TIMESTAMP

## ✅ Test Results Summary

### Unit Tests
- **Status**: $([ "$unit_passed" -gt 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- **Test Suites Passed**: $unit_passed
- **Log**: \`unit-tests.log\`
- **Result Bundle**: \`UnitTests_${TIMESTAMP}.xcresult\`

### Integration Tests
- **Status**: $([ "$integration_passed" -gt 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- **Test Suites Passed**: $integration_passed
- **Log**: \`integration-tests.log\`
- **Result Bundle**: \`IntegrationTests_${TIMESTAMP}.xcresult\`

### UI Tests
- **Status**: $([ "$ui_passed" -gt 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- **Test Suites Passed**: $ui_passed
- **Log**: \`ui-tests.log\`
- **Result Bundle**: \`UITests_${TIMESTAMP}.xcresult\`

## 📈 Performance Metrics
$(grep -E "launch_time|memory_usage|frame_rate" "$TEST_RESULTS_DIR"/*.log 2>/dev/null | head -10 || echo "- No performance metrics collected")

## 🔍 Key Issues Found
$(grep -E "XCTAssertTrue failed|XCTAssertEqual failed|Test Case.*failed" "$TEST_RESULTS_DIR"/*.log 2>/dev/null | head -10 || echo "- No test failures detected")

## 📁 Test Artifacts
- **Build Log**: \`$TEST_RESULTS_DIR/build.log\`
- **Test Logs**: \`$TEST_RESULTS_DIR/*.log\`
- **Result Bundles**: \`$TEST_RESULTS_DIR/*.xcresult\`
- **JSON Results**: \`$TEST_RESULTS_DIR/*.json\`

## 🚀 Next Steps
$(if [ "$unit_passed" -eq 0 ] || [ "$integration_passed" -eq 0 ] || [ "$ui_passed" -eq 0 ]; then
    echo "1. Review failed test logs for details"
    echo "2. Fix identified issues"
    echo "3. Re-run failed test suites"
else
    echo "1. All tests passing - ready for deployment"
    echo "2. Review performance metrics for optimization opportunities"
    echo "3. Consider adding more test coverage"
fi)

---
*Report generated by iOS Functional Test Suite v2.0*
EOF
    
    log_info "📊 Test summary saved to $summary_file"
}

# Cleanup function
cleanup() {
    if [ -n "$BACKEND_PID" ] && [ "$BACKEND_STARTED_BY_SCRIPT" = "true" ]; then
        log_info "Stopping backend (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null || true
    fi
}

# Main execution
main() {
    log_info "Starting functional test execution..."
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Check/start backend
    BACKEND_STARTED_BY_SCRIPT=false
    if ! check_backend; then
        BACKEND_STARTED_BY_SCRIPT=true
        start_backend
    fi
    
    # Run tests
    if run_tests; then
        log_info "All tests passed successfully!"
        generate_report
        exit 0
    else
        log_error "Some tests failed. Check the results for details."
        generate_report
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-backend)
            SKIP_BACKEND=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --skip-backend    Skip backend startup check"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main