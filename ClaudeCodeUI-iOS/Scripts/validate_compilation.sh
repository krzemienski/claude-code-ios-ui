#!/bin/bash

# Compilation Validation Script for iOS E2E Testing
# Agent-001: Git Operations & Compilation Validation Specialist

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS"
OUTPUT_ROOT="/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/output/20250909-122718_ios_e2e_claude"

# Navigate to project root
cd "$PROJECT_ROOT"

echo "====================================="
echo "=== Compilation Validation Starting ==="
echo "====================================="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Project: $PROJECT_ROOT"
echo ""

# Step 1: Clean any previous builds
echo "📦 Step 1: Cleaning previous builds..."
if [ -d ".build" ]; then
    rm -rf .build
fi
if [ -d "build" ]; then
    rm -rf build
fi

# Step 2: Generate project with Tuist
echo "🔧 Step 2: Generating project with Tuist..."
tuist generate
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ERROR: Tuist generation failed${NC}"
    echo "Git status:"
    git status --short
    exit 1
fi
echo -e "${GREEN}✅ Tuist generation successful${NC}"

# Step 3: Check if workspace exists
if [ ! -f "ClaudeCodeUI.xcworkspace/contents.xcworkspacedata" ]; then
    echo -e "${RED}❌ ERROR: Workspace not found after Tuist generation${NC}"
    exit 1
fi

# Step 4: Compile the project
echo "🔨 Step 3: Compiling project..."
xcodebuild -workspace ClaudeCodeUI.xcworkspace \
           -scheme ClaudeCodeUI \
           -sdk iphonesimulator \
           -destination 'platform=iOS Simulator,id=50523130-57AA-48B0-ABD0-4D59CE455F14' \
           clean build \
           -quiet \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           ONLY_ACTIVE_ARCH=YES \
           2>&1 | tee "${OUTPUT_ROOT}/compilation_log.txt" | grep -E '(error:|warning:|BUILD|FAILED|SUCCEEDED)'

COMPILE_RESULT=$?

if [ $COMPILE_RESULT -ne 0 ]; then
    echo -e "${RED}❌ ERROR: Compilation failed${NC}"
    echo "Common issues to check:"
    echo "  - Duplicate method definitions in ChatViewController.swift"
    echo "  - Missing dependencies in Package.swift"
    echo "  - Incorrect Swift version settings"
    echo ""
    echo "Git status after failure:"
    git status --short
    
    # Save error details
    echo "Compilation failed at $(date)" >> "${OUTPUT_ROOT}/compilation_errors.log"
    tail -100 "${OUTPUT_ROOT}/compilation_log.txt" >> "${OUTPUT_ROOT}/compilation_errors.log"
    
    exit 1
fi

echo -e "${GREEN}✅ Compilation successful${NC}"

# Step 5: Verify build artifacts
echo "🔍 Step 4: Verifying build artifacts..."
BUILD_DIR=$(xcodebuild -workspace ClaudeCodeUI.xcworkspace -scheme ClaudeCodeUI -showBuildSettings | grep -m 1 'BUILD_DIR' | sed 's/.*BUILD_DIR = //')
if [ -z "$BUILD_DIR" ]; then
    echo -e "${YELLOW}⚠️  Warning: Could not determine build directory${NC}"
else
    echo "Build directory: $BUILD_DIR"
fi

# Step 6: Create success marker
echo "$(date '+%Y-%m-%d %H:%M:%S'): Compilation successful" >> "${OUTPUT_ROOT}/compilation_success.log"

echo ""
echo "====================================="
echo -e "${GREEN}=== ✅ ALL CHECKS PASSED ✅ ===${NC}"
echo "====================================="
echo "Project compiles successfully!"
echo "Ready for E2E testing"
echo ""

exit 0