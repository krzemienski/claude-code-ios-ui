# iOS E2E Testing Libraries Installation Guide
## Quick Start for ClaudeCodeUI-iOS Project

---

## Prerequisites

```bash
# Verify Xcode version (15.0+)
xcodebuild -version

# Verify iOS Simulator availability
xcrun simctl list devices | grep "iPhone 16"

# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Ruby gems if needed (for Fastlane)
gem --version
```

---

## Step 1: Core Testing Framework

### Install Fastlane
```bash
# Using RubyGems (recommended)
sudo gem install fastlane -NV

# Or using Homebrew
brew install fastlane

# Initialize in project
cd /Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS
fastlane init

# Select option 2: "Automate beta distribution to TestFlight"
```

### Configure Fastfile
```ruby
# Fastfile
default_platform(:ios)

platform :ios do
  before_all do
    ensure_xcode_version(min: "15.0")
  end

  desc "Run all tests with coverage"
  lane :test do
    scan(
      workspace: "ClaudeCodeUI.xcworkspace",
      scheme: "ClaudeCodeUI",
      devices: ["iPhone 16 Pro Max"],
      code_coverage: true,
      output_types: "html,junit,json",
      output_directory: "./output/test_results",
      formatter: "xcbeautify"
    )
    
    # Generate HTML report
    sh "xchtmlreport -r ./output/test_results/*.xcresult"
  end

  desc "Generate screenshots for all devices"
  lane :screenshots do
    snapshot(
      workspace: "ClaudeCodeUI.xcworkspace",
      scheme: "ClaudeCodeUIUITests",
      devices: [
        "iPhone 16 Pro Max",
        "iPhone 16 Pro",
        "iPad Pro (12.9-inch) (6th generation)"
      ],
      languages: ["en-US", "es-ES", "ja-JP"],
      output_directory: "./output/screenshots",
      clear_previous_screenshots: true
    )
  end

  desc "Video recording of UI tests"
  lane :record_tests do
    sh "xcrun simctl io booted recordVideo --codec=h264 ./output/test_recording.mp4 &"
    
    scan(
      workspace: "ClaudeCodeUI.xcworkspace",
      scheme: "ClaudeCodeUIUITests",
      devices: ["iPhone 16 Pro Max"]
    )
    
    sh "killall simctl"
    
    # Process with FFmpeg
    sh "ffmpeg -i ./output/test_recording.mp4 -vf 'setpts=0.5*PTS' -filter:a 'atempo=2.0' ./output/test_recording_2x.mp4"
  end
end
```

---

## Step 2: Console Output Formatting

```bash
# Install xcbeautify (recommended)
brew install xcbeautify

# Verify installation
xcbeautify --version

# Configure Fastlane to use xcbeautify
echo "export FASTLANE_XCODEBUILD_FORMATTER=xcbeautify" >> ~/.zshrc
source ~/.zshrc
```

---

## Step 3: Test Result Processing

```bash
# Install XCTestHTMLReport
brew install xctesthtmlreport

# Install xcresultparser
git clone https://github.com/a7ex/xcresultparser.git
cd xcresultparser
swift build -c release
sudo cp .build/release/xcresultparser /usr/local/bin/

# Verify installations
xchtmlreport -h
xcresultparser -h
```

### Usage Examples
```bash
# Generate HTML report
xchtmlreport -r TestResults.xcresult

# Generate JUnit report
xcresultparser -o junit -p TestResults.xcresult > junit.xml

# Generate SonarQube report
xcresultparser -o cobertura -p TestResults.xcresult > coverage.xml
```

---

## Step 4: Video Processing

```bash
# Install FFmpeg
brew install ffmpeg

# Verify installation
ffmpeg -version

# Install ffprobe (comes with ffmpeg)
ffprobe -version
```

### Video Processing Scripts
```bash
# Create video processing script
cat > process_test_videos.sh << 'EOF'
#!/bin/bash

INPUT_DIR="./output/recordings"
OUTPUT_DIR="./output/processed"

mkdir -p "$OUTPUT_DIR"

# Process all recordings
for video in "$INPUT_DIR"/*.mp4; do
    filename=$(basename "$video" .mp4)
    
    # Speed up 2x
    ffmpeg -i "$video" -vf "setpts=0.5*PTS" -filter:a "atempo=2.0" "$OUTPUT_DIR/${filename}_2x.mp4"
    
    # Extract segments for validation
    ffmpeg -i "$video" -c copy -map 0 -segment_time 10 -f segment "$OUTPUT_DIR/${filename}_segment_%03d.mp4"
    
    # Validate segments
    for segment in "$OUTPUT_DIR"/${filename}_segment_*.mp4; do
        ffmpeg -v error -i "$segment" -f null - 2>"$OUTPUT_DIR/$(basename $segment .mp4)_validation.log"
    done
done
EOF

chmod +x process_test_videos.sh
```

---

## Step 5: Secret Detection

```bash
# Install TruffleHog
brew install trufflehog

# Verify installation
trufflehog --version
```

### Configure TruffleHog
```yaml
# .trufflehog.yml
detectors:
  - aws
  - github  
  - slack
  - privatekey
  - generic

exclude_paths:
  - "*.xcresult"
  - "DerivedData/"
  - "output/"
  - "*.mp4"
  - "*.png"

exclude_detectors:
  - FalsePositive

allow_list:
  - "example-api-key"
  - "test-token"
```

### Pre-commit Hook
```bash
# .git/hooks/pre-commit
#!/bin/bash
trufflehog filesystem . --no-update --fail --json | jq -r '.SourceMetadata.Data.Filesystem.file' | while read file; do
    echo "⚠️  Secret detected in: $file"
    exit 1
done
```

---

## Step 6: API Streaming Libraries

### Swift Package Manager Configuration
```swift
// Package.swift
import PackageDescription

let package = Package(
    name: "ClaudeCodeUI",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        // SSE Support
        .package(url: "https://github.com/launchdarkly/swift-eventsource.git", from: "3.2.1"),
        
        // WebSocket Support (choose one)
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.14.0"),
        // OR
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.6"),
        
        // Result Processing
        .package(url: "https://github.com/davidahouse/XCResultKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ClaudeCodeUI",
            dependencies: [
                .product(name: "LDSwiftEventSource", package: "swift-eventsource"),
                .product(name: "WebSocketKit", package: "websocket-kit"),
                "XCResultKit"
            ]
        ),
        .testTarget(
            name: "ClaudeCodeUITests",
            dependencies: ["ClaudeCodeUI"]
        )
    ]
)
```

### Xcode Integration
```bash
# If using Xcode project
xed .

# In Xcode:
# 1. Select project in navigator
# 2. Select project name under "PROJECT"
# 3. Select "Package Dependencies" tab
# 4. Click "+" to add packages
# 5. Enter package URLs from above
```

---

## Step 7: CI/CD Integration

### GitHub Actions
```yaml
# .github/workflows/test.yml
name: iOS Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-14
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Install dependencies
      run: |
        brew install xcbeautify
        brew install xctesthtmlreport
        brew install ffmpeg
        brew install trufflehog
        gem install fastlane
    
    - name: Secret scan
      run: |
        trufflehog filesystem . --fail
    
    - name: Run tests
      run: |
        fastlane test
    
    - name: Generate reports
      run: |
        xchtmlreport -r output/test_results/*.xcresult
        
    - name: Upload results
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: output/
```

---

## Step 8: Validation Script

```bash
#!/bin/bash
# validate_setup.sh

echo "🔍 Validating iOS E2E Testing Setup..."

# Check tools
tools=(
    "fastlane:gem"
    "xcbeautify:brew"
    "xchtmlreport:brew"
    "ffmpeg:brew"
    "trufflehog:brew"
)

for tool_info in "${tools[@]}"; do
    IFS=':' read -r tool method <<< "$tool_info"
    if command -v $tool &> /dev/null; then
        echo "✅ $tool installed ($(command -v $tool))"
    else
        echo "❌ $tool not found. Install with: $method install $tool"
    fi
done

# Check Xcode
if xcodebuild -version &> /dev/null; then
    echo "✅ Xcode installed: $(xcodebuild -version | head -1)"
else
    echo "❌ Xcode not found"
fi

# Check simulators
if xcrun simctl list devices | grep -q "iPhone 16"; then
    echo "✅ iPhone 16 simulators available"
else
    echo "⚠️  iPhone 16 simulators not found. Download from Xcode"
fi

echo "🎉 Validation complete!"
```

---

## Quick Test Commands

```bash
# Run basic test
fastlane test

# Generate screenshots
fastlane screenshots

# Record and process video
fastlane record_tests

# Secret scan
trufflehog filesystem . --no-update

# Generate HTML report from existing results
xchtmlreport -r ./output/test_results/*.xcresult

# Convert to JUnit
xcresultparser -o junit -p ./output/test_results/*.xcresult > junit.xml

# Process videos
./process_test_videos.sh

# Full test suite with all reports
fastlane test && \
xchtmlreport -r ./output/test_results/*.xcresult && \
xcresultparser -o junit -p ./output/test_results/*.xcresult > ./output/junit.xml && \
trufflehog filesystem ./output --no-update
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `xcbeautify not found` | Run: `brew install xcbeautify` |
| `gem permission denied` | Use: `sudo gem install fastlane` |
| `FFmpeg codec not found` | Reinstall: `brew reinstall ffmpeg --with-libvpx` |
| `Simulator not found` | Download from Xcode > Preferences > Components |
| `TruffleHog false positives` | Add to `.trufflehog.yml` exclude_paths |
| `WebSocket reconnection issues` | Use SwiftNIO instead of URLSessionWebSocketTask |

---

## Next Steps

1. ✅ Run validation script
2. ✅ Create first XCUITest
3. ✅ Configure Fastlane for your project
4. ✅ Set up CI/CD pipeline
5. ✅ Add pre-commit hooks
6. ✅ Create test documentation

---

## Support Resources

- [Fastlane Documentation](https://docs.fastlane.tools)
- [XCUITest Guide](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [TruffleHog Wiki](https://github.com/trufflesecurity/trufflehog/wiki)
- [Swift Package Manager](https://www.swift.org/package-manager/)

---

**Total Setup Time**: ~2 hours
**Disk Space Required**: ~2 GB
**System Requirements**: macOS 14+, Xcode 15+, 16GB RAM recommended