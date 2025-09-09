# Dependencies and Versions Guide

## Core Testing Dependencies

### 1. XCUITest (Built-in)
- **Version**: Included with Xcode 15.4+
- **Minimum iOS**: 17.0
- **Purpose**: UI automation and E2E testing
- **Documentation**: [Apple Developer](https://developer.apple.com/documentation/xctest)

### 2. XCTestHTMLReport
- **Version**: 2.3.0
- **Installation**: `brew install xctesthtmlreport`
- **Purpose**: Rich HTML test reports with screenshots and logs
- **GitHub**: [XCTestHTMLReport](https://github.com/XCTestHTMLReport/XCTestHTMLReport)
- **Features**:
  - Interactive HTML reports
  - Screenshot gallery
  - Test execution timeline
  - Coverage metrics
  - Performance graphs

### 3. FFmpegKit iOS
- **Version**: 6.0.0
- **Installation**: Swift Package Manager
- **Purpose**: Video recording and media capture
- **GitHub**: [FFmpegKit](https://github.com/arthenica/ffmpeg-kit)
- **Architectures**: arm64, x86_64 (simulator)
- **Features**:
  - Screen recording
  - Audio capture
  - Format conversion
  - Streaming support

### 4. TruffleHog
- **Version**: 3.63.0+
- **Installation**: `brew install trufflehog`
- **Purpose**: Secret detection and security scanning
- **GitHub**: [TruffleHog](https://github.com/trufflesecurity/trufflehog)
- **Detectors**:
  - Anthropic API keys
  - AWS credentials
  - GitHub tokens
  - Generic API keys
  - Custom patterns

### 5. Starscream (WebSocket)
- **Version**: 4.0.6
- **Installation**: Swift Package Manager
- **Purpose**: WebSocket client for real-time communication
- **GitHub**: [Starscream](https://github.com/daltoniam/Starscream)
- **Features**:
  - SSL/TLS support
  - Compression
  - Custom headers
  - Reconnection logic

### 6. AsyncHTTPClient
- **Version**: 1.19.0
- **Installation**: Swift Package Manager
- **Purpose**: Async HTTP client for SSE streaming
- **GitHub**: [swift-server/async-http-client](https://github.com/swift-server/async-http-client)
- **Features**:
  - SSE support
  - HTTP/2
  - Connection pooling
  - Streaming responses

## Development Tools

### 7. SwiftLint
- **Version**: 0.53.0
- **Installation**: `brew install swiftlint`
- **Purpose**: Code style and quality enforcement
- **Configuration**: `.swiftlint.yml`
- **Rules**: 50+ enabled rules

### 8. swift-format
- **Version**: 509.0.0
- **Installation**: `brew install swift-format`
- **Purpose**: Code formatting
- **Configuration**: `.swift-format`

### 9. xcbeautify
- **Version**: 1.4.0
- **Installation**: `brew install xcbeautify`
- **Purpose**: Beautiful test output formatting
- **Features**:
  - Colored output
  - Progress indicators
  - Error highlighting

### 10. xcodes
- **Version**: 1.4.1
- **Installation**: `brew install xcodesorg/made/xcodes`
- **Purpose**: Xcode version management
- **Features**:
  - Multiple Xcode versions
  - Automated downloads
  - Version switching

## Testing Utilities

### 11. SnapshotTesting
- **Version**: 1.15.0
- **Installation**: Swift Package Manager
- **Purpose**: Visual regression testing
- **GitHub**: [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)

### 12. Reachability.swift
- **Version**: 5.1.0
- **Installation**: Swift Package Manager
- **Purpose**: Network status monitoring
- **GitHub**: [Reachability.swift](https://github.com/ashleymills/Reachability.swift)

## System Requirements

### Xcode
- **Minimum Version**: 15.4
- **Recommended**: 16.0 Beta
- **Command Line Tools**: Required

### macOS
- **Minimum**: macOS 14.0 (Sonoma)
- **Recommended**: macOS 15.0 (Sequoia)

### iOS Simulator
- **Target**: iOS 17.0+
- **Recommended**: iOS 18.0
- **Device**: iPhone 16 Pro Max

## Environment Variables

```bash
# Required
export CLAUDE_API_KEY="sk-ant-..."

# Optional
export SIMULATOR_DEVICE_ID="..."
export TEST_OUTPUT_DIR="./TestResults"
export ENABLE_VIDEO_RECORDING="true"
export NETWORK_CONDITION="good_wifi"
export TEST_TIMEOUT="60"
```

## Package.swift Dependencies

```swift
dependencies: [
    .package(url: "https://github.com/XCTestHTMLReport/XCTestHTMLReport", from: "2.3.0"),
    .package(url: "https://github.com/arthenica/ffmpeg-kit-ios", from: "6.0.0"),
    .package(url: "https://github.com/daltoniam/Starscream", from: "4.0.0"),
    .package(url: "https://github.com/swift-server/async-http-client", from: "1.19.0"),
    .package(url: "https://github.com/realm/SwiftLint", from: "0.53.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0"),
    .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.1.0")
]
```

## Installation Commands Summary

```bash
# Core tools
brew install xctesthtmlreport ffmpeg trufflehog

# Development tools
brew install swiftlint swift-format xcbeautify

# Xcode management
brew install xcodesorg/made/xcodes

# JSON processing
brew install jq

# Ruby gems (optional)
gem install xcpretty xcov

# Swift packages
swift package resolve
```

## Version Compatibility Matrix

| Tool | Xcode 15.4 | Xcode 16.0 | iOS 17 | iOS 18 |
|------|------------|------------|--------|--------|
| XCUITest | ✅ | ✅ | ✅ | ✅ |
| XCTestHTMLReport | ✅ | ✅ | ✅ | ✅ |
| FFmpegKit | ✅ | ✅ | ✅ | ✅ |
| TruffleHog | ✅ | ✅ | N/A | N/A |
| Starscream | ✅ | ✅ | ✅ | ✅ |
| AsyncHTTPClient | ✅ | ✅ | ✅ | ✅ |
| SwiftLint | ✅ | ✅ | N/A | N/A |
| SnapshotTesting | ✅ | ✅ | ✅ | ✅ |

## Update Commands

```bash
# Update Homebrew packages
brew update && brew upgrade

# Update Swift packages
swift package update

# Update Ruby gems
gem update xcpretty xcov

# Update Xcode
xcodes update
xcodes install 16.0
```

## Troubleshooting

### Common Issues

1. **FFmpegKit build errors**
   - Solution: Ensure architectures match (arm64 for device, x86_64 for simulator)

2. **TruffleHog false positives**
   - Solution: Configure `.trufflehog.yml` with custom patterns

3. **WebSocket connection failures**
   - Solution: Check network conditions and API key validity

4. **Simulator not found**
   - Solution: Run setup script or manually create with xcrun simctl

5. **SwiftLint violations**
   - Solution: Run `swiftlint autocorrect` or adjust rules

## License Information

- **XCUITest**: Apple SDK License
- **XCTestHTMLReport**: MIT
- **FFmpegKit**: LGPL v3.0
- **TruffleHog**: AGPL v3.0
- **Starscream**: Apache 2.0
- **AsyncHTTPClient**: Apache 2.0
- **SwiftLint**: MIT
- **SnapshotTesting**: MIT
- **Reachability.swift**: MIT

---

*Last Updated: September 9, 2025*
*Maintained for Claude Code UI iOS Testing Framework*