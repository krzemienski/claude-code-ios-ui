#!/bin/bash

# Dependency Installation Script for Claude API iOS E2E Testing
# Installs all required tools and libraries for comprehensive testing

set -e

echo "🔧 Installing dependencies for Claude API iOS E2E Testing..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}⚠️  Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update Homebrew
echo -e "${BLUE}📦 Updating Homebrew...${NC}"
brew update

# Install XCTestHTMLReport
echo -e "${BLUE}📊 Installing XCTestHTMLReport for test reporting...${NC}"
if ! command -v xchtmlreport &> /dev/null; then
    brew install xctesthtmlreport
    echo -e "${GREEN}✅ XCTestHTMLReport installed${NC}"
else
    echo "XCTestHTMLReport already installed"
fi

# Install FFmpeg for media capture
echo -e "${BLUE}🎥 Installing FFmpeg for media capture...${NC}"
if ! command -v ffmpeg &> /dev/null; then
    brew install ffmpeg
    echo -e "${GREEN}✅ FFmpeg installed${NC}"
else
    echo "FFmpeg already installed"
fi

# Install TruffleHog for secret scanning
echo -e "${BLUE}🔐 Installing TruffleHog for secret detection...${NC}"
if ! command -v trufflehog &> /dev/null; then
    brew install trufflehog
    echo -e "${GREEN}✅ TruffleHog installed${NC}"
else
    echo "TruffleHog already installed"
fi

# Install jq for JSON processing
echo -e "${BLUE}📄 Installing jq for JSON processing...${NC}"
if ! command -v jq &> /dev/null; then
    brew install jq
    echo -e "${GREEN}✅ jq installed${NC}"
else
    echo "jq already installed"
fi

# Install xcbeautify for better test output
echo -e "${BLUE}✨ Installing xcbeautify for test output formatting...${NC}"
if ! command -v xcbeautify &> /dev/null; then
    brew install xcbeautify
    echo -e "${GREEN}✅ xcbeautify installed${NC}"
else
    echo "xcbeautify already installed"
fi

# Install xcodes for Xcode version management
echo -e "${BLUE}📱 Installing xcodes for Xcode management...${NC}"
if ! command -v xcodes &> /dev/null; then
    brew install xcodesorg/made/xcodes
    echo -e "${GREEN}✅ xcodes installed${NC}"
else
    echo "xcodes already installed"
fi

# Install swift-format for code formatting
echo -e "${BLUE}🎨 Installing swift-format...${NC}"
if ! command -v swift-format &> /dev/null; then
    brew install swift-format
    echo -e "${GREEN}✅ swift-format installed${NC}"
else
    echo "swift-format already installed"
fi

# Install SwiftLint for code quality
echo -e "${BLUE}📏 Installing SwiftLint...${NC}"
if ! command -v swiftlint &> /dev/null; then
    brew install swiftlint
    echo -e "${GREEN}✅ SwiftLint installed${NC}"
else
    echo "SwiftLint already installed"
fi

# Create Package.swift for Swift dependencies
echo -e "${BLUE}📦 Creating Package.swift for iOS dependencies...${NC}"
cat > ../../Package.swift << 'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeCodeUITests",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ClaudeCodeUITests",
            targets: ["ClaudeCodeUITests"])
    ],
    dependencies: [
        // XCTestHTMLReport
        .package(url: "https://github.com/XCTestHTMLReport/XCTestHTMLReport", from: "2.3.0"),
        
        // FFmpegKit for iOS
        .package(url: "https://github.com/arthenica/ffmpeg-kit-ios", from: "6.0.0"),
        
        // Networking library for SSE/WebSocket
        .package(url: "https://github.com/daltoniam/Starscream", from: "4.0.0"),
        
        // AsyncHTTPClient for streaming
        .package(url: "https://github.com/swift-server/async-http-client", from: "1.19.0"),
        
        // SwiftLint Plugin
        .package(url: "https://github.com/realm/SwiftLint", from: "0.53.0"),
        
        // Snapshot Testing
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0"),
        
        // Network Link Conditioner
        .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.1.0")
    ],
    targets: [
        .target(
            name: "ClaudeCodeUITests",
            dependencies: [
                .product(name: "FFmpegKit", package: "ffmpeg-kit-ios"),
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "Reachability", package: "Reachability.swift")
            ],
            path: "Tests"
        ),
        .testTarget(
            name: "ClaudeCodeUITestsTests",
            dependencies: ["ClaudeCodeUITests"]
        )
    ]
)
EOF

# Create .swiftlint.yml configuration
echo -e "${BLUE}📝 Creating SwiftLint configuration...${NC}"
cat > ../../.swiftlint.yml << 'EOF'
# SwiftLint configuration for Claude Code UI iOS Tests

included:
  - Tests
  - ClaudeCodeUI

excluded:
  - Carthage
  - Pods
  - DerivedData
  - .build
  - vendor

opt_in_rules:
  - empty_count
  - closure_spacing
  - collection_alignment
  - contains_over_first_not_nil
  - discouraged_object_literal
  - empty_string
  - first_where
  - force_unwrapping
  - implicit_return
  - last_where
  - legacy_multiple
  - multiline_parameters
  - multiline_arguments
  - operator_usage_whitespace
  - overridden_super_call
  - pattern_matching_keywords
  - prefer_self_type_over_type_of_self
  - redundant_nil_coalescing
  - toggle_bool
  - trailing_closure
  - unneeded_parentheses_in_closure_argument
  - vertical_parameter_alignment_on_call
  - yoda_condition

disabled_rules:
  - todo
  - trailing_whitespace

line_length:
  warning: 120
  error: 200
  ignores_function_declarations: true
  ignores_comments: true

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 600
  error: 1200

function_body_length:
  warning: 50
  error: 100

cyclomatic_complexity:
  warning: 15
  error: 20

identifier_name:
  min_length:
    warning: 2
  max_length:
    warning: 40
    error: 50
  excluded:
    - id
    - URL
    - url
    - UI
EOF

# Create TruffleHog configuration
echo -e "${BLUE}🔒 Creating TruffleHog configuration...${NC}"
cat > ../../.trufflehog.yml << 'EOF'
# TruffleHog configuration for secret scanning

detectors:
  - type: "aws"
  - type: "github"
  - type: "anthropic"
  - type: "openai"
  - type: "stripe"
  - type: "slack"
  - type: "generic_api_key"

exclude_paths:
  - .git/
  - .build/
  - DerivedData/
  - "*.xcodeproj"
  - "*.xcworkspace"
  - node_modules/
  - vendor/
  - Pods/

custom_patterns:
  - name: "Claude API Key"
    regex: 'sk-ant-[a-zA-Z0-9]{40,}'
    
  - name: "iOS Provisioning Profile"
    regex: '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}'

verification:
  - anthropic:
      verify: true
      
output:
  format: json
  file: .trufflehog-report.json
EOF

# Create test configuration file
echo -e "${BLUE}⚙️  Creating test configuration...${NC}"
cat > ../../test-config.json << 'EOF'
{
  "test_settings": {
    "claude_api": {
      "base_url": "https://api.anthropic.com/v1",
      "timeout": 60,
      "max_retries": 3,
      "stream_enabled": true,
      "models": [
        "claude-3-opus-20240229",
        "claude-3-sonnet-20240229",
        "claude-3-haiku-20240307"
      ]
    },
    "simulator": {
      "device": "iPhone 16 Pro Max",
      "os_version": "18.0",
      "locale": "en_US",
      "timezone": "America/New_York"
    },
    "media_capture": {
      "screenshots": true,
      "video_recording": true,
      "network_logs": true,
      "performance_metrics": true,
      "format": "mp4",
      "quality": "high",
      "fps": 30
    },
    "reporting": {
      "html_report": true,
      "junit_xml": true,
      "coverage_report": true,
      "performance_report": true,
      "screenshot_on_failure": true
    },
    "network_conditions": [
      {
        "name": "WiFi",
        "profile": "good_wifi"
      },
      {
        "name": "LTE",
        "profile": "average_lte"
      },
      {
        "name": "3G",
        "profile": "poor_3g"
      }
    ],
    "test_data": {
      "sample_prompts": [
        "Hello Claude, can you help me with Swift?",
        "Write a function to sort an array",
        "Explain async/await in Swift",
        "Debug this iOS crash log"
      ],
      "expected_response_time": {
        "first_token": 2000,
        "streaming_chunk": 100,
        "complete_response": 30000
      }
    }
  }
}
EOF

# Install Ruby gems for additional tools
echo -e "${BLUE}💎 Installing Ruby gems...${NC}"
gem install xcpretty --user-install 2>/dev/null || true
gem install xcov --user-install 2>/dev/null || true

# Create directories for test outputs
echo -e "${BLUE}📁 Creating test output directories...${NC}"
mkdir -p ../../TestResults
mkdir -p ../../TestReports
mkdir -p ../../TestVideos
mkdir -p ../../TestScreenshots
mkdir -p ../../Coverage

# Verify installations
echo ""
echo -e "${GREEN}✅ Dependency Installation Complete!${NC}"
echo ""
echo "📋 Installed Tools:"
command -v xchtmlreport &> /dev/null && echo "  ✓ XCTestHTMLReport $(xchtmlreport version 2>&1 | head -1)"
command -v ffmpeg &> /dev/null && echo "  ✓ FFmpeg $(ffmpeg -version 2>&1 | head -1 | cut -d' ' -f3)"
command -v trufflehog &> /dev/null && echo "  ✓ TruffleHog $(trufflehog --version 2>&1)"
command -v jq &> /dev/null && echo "  ✓ jq $(jq --version)"
command -v xcbeautify &> /dev/null && echo "  ✓ xcbeautify $(xcbeautify --version)"
command -v swift-format &> /dev/null && echo "  ✓ swift-format"
command -v swiftlint &> /dev/null && echo "  ✓ SwiftLint $(swiftlint version)"

echo ""
echo "📁 Created Configurations:"
echo "  • Package.swift - Swift package dependencies"
echo "  • .swiftlint.yml - Code quality rules"
echo "  • .trufflehog.yml - Secret scanning config"
echo "  • test-config.json - Test settings"

echo ""
echo "🎯 Next Steps:"
echo "  1. Run: swift package resolve"
echo "  2. Configure API keys in environment variables"
echo "  3. Run: ./setup_iphone16_pro_max.sh"
echo "  4. Execute tests with: xcodebuild test"

echo ""
echo -e "${YELLOW}⚠️  Important: Set your Claude API key:${NC}"
echo "  export CLAUDE_API_KEY='your-api-key-here'"