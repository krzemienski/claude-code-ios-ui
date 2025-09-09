#!/bin/bash

# ClaudeCodeUI iOS Test Runner Script
# Executes all test suites and generates coverage reports

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="ClaudeCodeUI-Tests"
SIMULATOR="iPhone 16 Pro Max"
IOS_VERSION="18.0"
COVERAGE_DIR="$PROJECT_DIR/TestResults/Coverage"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     ClaudeCodeUI iOS Test Runner${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# Function to print section headers
print_section() {
    echo -e "\n${GREEN}▶ $1${NC}"
    echo -e "${GREEN}$(printf '─%.0s' {1..60})${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check for Xcode
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}✗ Xcode not found. Please install Xcode.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Xcode found${NC}"
    
    # Check for Tuist
    if ! command -v tuist &> /dev/null; then
        echo -e "${YELLOW}⚠ Tuist not found. Installing...${NC}"
        curl -Ls https://install.tuist.io | bash
    fi
    echo -e "${GREEN}✓ Tuist found${NC}"
    
    # Check for xcpretty (optional, for prettier output)
    if ! command -v xcpretty &> /dev/null; then
        echo -e "${YELLOW}⚠ xcpretty not found. Install with: gem install xcpretty${NC}"
    fi
}

# Function to clean build artifacts
clean_build() {
    print_section "Cleaning Build Artifacts"
    
    cd "$PROJECT_DIR"
    rm -rf Build/
    rm -rf DerivedData/
    rm -rf "$COVERAGE_DIR"
    mkdir -p "$COVERAGE_DIR"
    
    echo -e "${GREEN}✓ Build artifacts cleaned${NC}"
}

# Function to generate Xcode project with Tuist
generate_project() {
    print_section "Generating Xcode Project with Tuist"
    
    cd "$PROJECT_DIR"
    tuist generate
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Xcode project generated successfully${NC}"
    else
        echo -e "${RED}✗ Failed to generate Xcode project${NC}"
        exit 1
    fi
}

# Function to build the app
build_app() {
    print_section "Building Application"
    
    xcodebuild build \
        -workspace "$PROJECT_DIR/ClaudeCodeUI.xcworkspace" \
        -scheme "ClaudeCodeUI" \
        -destination "platform=iOS Simulator,name=$SIMULATOR,OS=$IOS_VERSION" \
        -configuration Debug \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        | xcpretty 2>/dev/null || true
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✓ Application built successfully${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
}

# Function to run unit tests
run_unit_tests() {
    print_section "Running Unit Tests"
    
    xcodebuild test \
        -workspace "$PROJECT_DIR/ClaudeCodeUI.xcworkspace" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$SIMULATOR,OS=$IOS_VERSION" \
        -only-testing:ClaudeCodeUITests \
        -enableCodeCoverage YES \
        -resultBundlePath "$PROJECT_DIR/TestResults/UnitTests.xcresult" \
        | xcpretty -r junit -o "$PROJECT_DIR/TestResults/unit-tests.xml" 2>/dev/null || true
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✓ Unit tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Unit tests failed${NC}"
        return 1
    fi
}

# Function to run integration tests
run_integration_tests() {
    print_section "Running Integration Tests"
    
    # Check if backend is running
    if ! curl -s http://192.168.0.43:3004/health > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Backend server not running. Some integration tests may fail.${NC}"
    fi
    
    xcodebuild test \
        -workspace "$PROJECT_DIR/ClaudeCodeUI.xcworkspace" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$SIMULATOR,OS=$IOS_VERSION" \
        -only-testing:ClaudeCodeUIIntegrationTests \
        -enableCodeCoverage YES \
        -resultBundlePath "$PROJECT_DIR/TestResults/IntegrationTests.xcresult" \
        | xcpretty -r junit -o "$PROJECT_DIR/TestResults/integration-tests.xml" 2>/dev/null || true
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✓ Integration tests passed${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Some integration tests failed${NC}"
        return 1
    fi
}

# Function to run UI tests
run_ui_tests() {
    print_section "Running UI Tests"
    
    xcodebuild test \
        -workspace "$PROJECT_DIR/ClaudeCodeUI.xcworkspace" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$SIMULATOR,OS=$IOS_VERSION" \
        -only-testing:ClaudeCodeUIUITests \
        -resultBundlePath "$PROJECT_DIR/TestResults/UITests.xcresult" \
        | xcpretty -r junit -o "$PROJECT_DIR/TestResults/ui-tests.xml" 2>/dev/null || true
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✓ UI tests passed${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Some UI tests failed${NC}"
        return 1
    fi
}

# Function to generate coverage report
generate_coverage_report() {
    print_section "Generating Code Coverage Report"
    
    # Find the most recent xcresult bundle
    XCRESULT=$(find "$PROJECT_DIR/TestResults" -name "*.xcresult" -type d | head -1)
    
    if [ -z "$XCRESULT" ]; then
        echo -e "${YELLOW}⚠ No xcresult bundle found${NC}"
        return
    fi
    
    # Export coverage data
    xcrun xccov view --report --json "$XCRESULT" > "$COVERAGE_DIR/coverage.json"
    
    # Generate human-readable report
    xcrun xccov view --report "$XCRESULT" > "$COVERAGE_DIR/coverage.txt"
    
    # Extract coverage percentage
    COVERAGE=$(xcrun xccov view --report "$XCRESULT" | grep "ClaudeCodeUI.app" | head -1 | awk '{print $NF}')
    
    echo -e "${GREEN}✓ Coverage report generated${NC}"
    echo -e "${BLUE}  Coverage: ${COVERAGE}${NC}"
    
    # Check if coverage meets target
    if (( $(echo "$COVERAGE 75" | awk '{print ($1 >= $2)}') )); then
        echo -e "${GREEN}✓ Coverage target (75%) met!${NC}"
    else
        echo -e "${YELLOW}⚠ Coverage below target (75%)${NC}"
    fi
}

# Function to print summary
print_summary() {
    print_section "Test Execution Summary"
    
    echo -e "Test Results:"
    
    if [ $UNIT_TEST_RESULT -eq 0 ]; then
        echo -e "  ${GREEN}✓ Unit Tests: PASSED${NC}"
    else
        echo -e "  ${RED}✗ Unit Tests: FAILED${NC}"
    fi
    
    if [ $INTEGRATION_TEST_RESULT -eq 0 ]; then
        echo -e "  ${GREEN}✓ Integration Tests: PASSED${NC}"
    else
        echo -e "  ${YELLOW}⚠ Integration Tests: PARTIAL${NC}"
    fi
    
    if [ $UI_TEST_RESULT -eq 0 ]; then
        echo -e "  ${GREEN}✓ UI Tests: PASSED${NC}"
    else
        echo -e "  ${YELLOW}⚠ UI Tests: PARTIAL${NC}"
    fi
    
    echo -e "\nReports available at:"
    echo -e "  📊 Coverage: $COVERAGE_DIR/coverage.txt"
    echo -e "  📋 JUnit XML: $PROJECT_DIR/TestResults/*.xml"
    echo -e "  📦 XCResult: $PROJECT_DIR/TestResults/*.xcresult"
}

# Main execution
main() {
    START_TIME=$(date +%s)
    
    check_prerequisites
    clean_build
    generate_project
    build_app
    
    # Run tests and capture results
    UNIT_TEST_RESULT=0
    INTEGRATION_TEST_RESULT=0
    UI_TEST_RESULT=0
    
    run_unit_tests || UNIT_TEST_RESULT=$?
    run_integration_tests || INTEGRATION_TEST_RESULT=$?
    run_ui_tests || UI_TEST_RESULT=$?
    
    generate_coverage_report
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    print_summary
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Total execution time: ${DURATION} seconds${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    # Exit with appropriate code
    if [ $UNIT_TEST_RESULT -ne 0 ]; then
        exit 1
    fi
    
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit-only)
            UNIT_ONLY=true
            shift
            ;;
        --integration-only)
            INTEGRATION_ONLY=true
            shift
            ;;
        --ui-only)
            UI_ONLY=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--unit-only] [--integration-only] [--ui-only] [--skip-build]"
            exit 1
            ;;
    esac
done

# Run main function
main