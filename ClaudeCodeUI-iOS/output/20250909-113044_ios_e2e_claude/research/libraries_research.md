# iOS Testing Libraries Research for Claude API E2E Testing

## Executive Summary
This document provides comprehensive research on iOS testing libraries and patterns specifically tailored for testing Claude API integration with real SSE/WebSocket streaming, complete media capture, and iPhone 16 Pro Max simulator optimization.

## 1. Core Testing Framework: XCUITest

### Overview
XCUITest is Apple's native UI testing framework, providing robust capabilities for E2E testing with direct simulator control.

### Key Features for Claude API Testing
- **Accessibility Inspector Integration**: Essential for identifying UI elements during streaming responses
- **Performance Testing**: Built-in metrics for measuring response times and UI rendering
- **Network Condition Simulation**: Test Claude API under various network conditions
- **Async Testing Support**: Critical for SSE/WebSocket validation

### Code Pattern for SSE Testing
```swift
class ClaudeAPIStreamingTests: XCTestCase {
    func testClaudeSSEStreaming() {
        let app = XCUIApplication()
        app.launch()
        
        // Start Claude API request
        app.buttons["Send to Claude"].tap()
        
        // Wait for SSE stream to begin
        let streamingIndicator = app.otherElements["streaming_indicator"]
        XCTAssertTrue(streamingIndicator.waitForExistence(timeout: 5))
        
        // Validate progressive text appearance
        let responseTextView = app.textViews["claude_response"]
        let predicate = NSPredicate(format: "value CONTAINS[c] %@", "Claude is responding")
        expectation(for: predicate, evaluatedWith: responseTextView, handler: nil)
        waitForExpectations(timeout: 30)
        
        // Capture performance metrics
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Measure streaming performance
        }
    }
}
```

## 2. XCTestHTMLReport Integration

### Installation & Setup
```bash
# Install via Homebrew
brew install xctesthtmlreport

# Or via Swift Package Manager
.package(url: "https://github.com/XCTestHTMLReport/XCTestHTMLReport", from: "2.3.0")
```

### Configuration for Rich Reports
```swift
// In your test scheme's Test action
// Add post-action script:
#!/bin/bash
xchtmlreport -r "$BUILT_PRODUCTS_DIR/TestResults.xcresult" \
             -o "$PROJECT_DIR/TestReports" \
             --enable-coverage \
             --screenshots \
             --activity-logs
```

### Enhanced Report Features
- **Screenshot Capture**: Automatic capture at failure points
- **Network Request Logs**: Full Claude API request/response logging
- **Performance Graphs**: Visual representation of streaming latency
- **Video Attachments**: Full test execution recordings

## 3. FFmpegKit Integration for Media Capture

### Installation
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/arthenica/ffmpeg-kit-ios", from: "6.0.0")
]
```

### Screen Recording Implementation
```swift
import FFmpegKitSwift

class MediaCaptureHelper {
    static func startRecording(outputPath: String) {
        let command = "-f avfoundation -i '1:0' -c:v libx264 -preset ultrafast -pix_fmt yuv420p \(outputPath)"
        FFmpegKit.executeAsync(command) { session in
            guard let session = session else { return }
            print("Recording started: \(session.getState())")
        }
    }
    
    static func captureStreamingSession(testName: String) -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(testName)_\(Date().timeIntervalSince1970).mp4")
        
        startRecording(outputPath: outputURL.path)
        return outputURL
    }
}
```

## 4. WebSocket/SSE Testing Patterns

### Real Claude API Testing Setup
```swift
import Network

class ClaudeAPIWebSocketTester {
    private var connection: NWConnection?
    private var messageBuffer: [String] = []
    
    func connectToClaudeSSE(apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = createClaudeRequestBody()
        
        // SSE streaming session
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request)
        task.resume()
        
        // Capture streaming data
        let delegate = SSEDelegate { data in
            self.messageBuffer.append(data)
            completion(.success(data))
        }
    }
    
    private func createClaudeRequestBody() -> Data {
        let body: [String: Any] = [
            "model": "claude-3-opus-20240229",
            "messages": [["role": "user", "content": "Hello Claude"]],
            "stream": true
        ]
        return try! JSONSerialization.data(withJSONObject: body)
    }
}
```

### SSE Event Parser
```swift
class SSEEventParser {
    enum EventType {
        case message(String)
        case error(String)
        case ping
        case completion
    }
    
    func parse(data: Data) -> EventType {
        guard let string = String(data: data, encoding: .utf8) else {
            return .error("Invalid UTF-8")
        }
        
        let lines = string.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("data: ") {
                let content = String(line.dropFirst(6))
                if content == "[DONE]" {
                    return .completion
                }
                return .message(content)
            }
        }
        return .ping
    }
}
```

## 5. iPhone 16 Pro Max Simulator Optimization

### Simulator Configuration
```bash
#!/bin/bash
# setup_iphone16_pro_max.sh

# Create iPhone 16 Pro Max simulator
xcrun simctl create "iPhone 16 Pro Max - Testing" \
    "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max" \
    "com.apple.CoreSimulator.SimRuntime.iOS-18-0"

# Boot the simulator
DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro Max - Testing" | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')
xcrun simctl boot $DEVICE_ID

# Configure for optimal performance
xcrun simctl spawn $DEVICE_ID defaults write com.apple.springboard FakeCarrier "Testing"
xcrun simctl spawn $DEVICE_ID defaults write com.apple.springboard SBShowBatteryPercentage 1

# Set network conditions for SSE testing
xcrun simctl spawn $DEVICE_ID setnetworkcondition wifi "Good 3G"

# Enable verbose logging
xcrun simctl spawn $DEVICE_ID log config --mode "level:debug" --subsystem com.claudecode.ui

echo "iPhone 16 Pro Max simulator configured with ID: $DEVICE_ID"
```

### Performance Tuning
```swift
class SimulatorOptimization {
    static func configureForTesting() {
        // Disable animations for faster testing
        UIView.setAnimationsEnabled(false)
        
        // Configure for iPhone 16 Pro Max specs
        let device = UIDevice.current
        if device.userInterfaceIdiom == .phone {
            // Set optimal content size for 6.9" display
            let window = UIApplication.shared.windows.first
            window?.overrideUserInterfaceStyle = .light
        }
        
        // Network optimization for SSE
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        config.allowsExpensiveNetworkAccess = true
    }
}
```

## 6. TruffleHog Integration for Secret Detection

### Installation & Setup
```bash
# Install TruffleHog
brew install trufflehog

# Or via Docker
docker pull trufflesecurity/trufflehog:latest
```

### Pre-Test Secret Scanning
```swift
class SecretScanner {
    static func scanForSecrets(in directory: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/trufflehog")
        process.arguments = [
            "filesystem",
            directory,
            "--json",
            "--no-verification",
            "--exclude-paths", ".trufflehog-exclude"
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                print("⚠️ Secrets detected! Review before committing.")
                return false
            }
        } catch {
            print("Error running TruffleHog: \(error)")
        }
        return true
    }
}
```

### CI/CD Integration
```yaml
# .github/workflows/secret-scan.yml
name: Secret Scanning
on: [push, pull_request]

jobs:
  trufflehog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: TruffleHog OSS
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
```

## 7. Complete Testing Architecture

### Test Structure
```
ClaudeCodeUI-iOS/
├── Tests/
│   ├── E2E/
│   │   ├── ClaudeAPITests/
│   │   │   ├── StreamingTests.swift
│   │   │   ├── WebSocketTests.swift
│   │   │   └── ResponseValidation.swift
│   │   ├── MediaCapture/
│   │   │   ├── ScreenRecording.swift
│   │   │   └── PerformanceCapture.swift
│   │   └── Integration/
│   │       ├── SecretScanning.swift
│   │       └── ReportGeneration.swift
│   ├── Helpers/
│   │   ├── SimulatorHelper.swift
│   │   ├── NetworkMocker.swift
│   │   └── AssertionHelpers.swift
│   └── Resources/
│       ├── TestData/
│       └── Configurations/
```

## 8. Performance Benchmarks

### Expected Metrics for Claude API
- **Initial Response Time**: < 2 seconds
- **Streaming Latency**: < 100ms between chunks
- **Total Response Time**: Varies (5-30 seconds typical)
- **Memory Usage**: < 150MB during streaming
- **CPU Usage**: < 30% during text rendering

### Measurement Code
```swift
class PerformanceMetrics {
    static func measureStreamingPerformance() -> XCTMetric {
        let metrics = [
            XCTClockMetric(), // Time measurement
            XCTMemoryMetric(), // Memory usage
            XCTCPUMetric(), // CPU usage
            XCTStorageMetric(), // Disk I/O
            XCTApplicationLaunchMetric() // Cold start time
        ]
        
        return XCTMetric.combine(metrics)
    }
}
```

## 9. Best Practices & Recommendations

### Do's
1. **Always use real API endpoints** - No mocking for E2E tests
2. **Implement retry logic** - Network requests can fail
3. **Capture all media** - Screenshots, videos, and logs
4. **Test edge cases** - Slow networks, interruptions, large responses
5. **Clean up resources** - Close connections, delete temp files

### Don'ts
1. **Don't hardcode API keys** - Use environment variables
2. **Don't skip error scenarios** - Test failure paths
3. **Don't ignore performance** - Monitor and benchmark
4. **Don't test in isolation** - Consider full user workflows

## 10. Quick Start Commands

```bash
# Install all dependencies
brew install xctesthtmlreport trufflehog ffmpeg

# Setup simulator
./tests/setup/setup_iphone16_pro_max.sh

# Run tests with full reporting
xcodebuild test \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max - Testing' \
    -resultBundlePath TestResults.xcresult \
    -enableCodeCoverage YES

# Generate HTML report
xchtmlreport -r TestResults.xcresult -o TestReports

# Scan for secrets
trufflehog filesystem . --json
```

## Resources & References

- [XCUITest Documentation](https://developer.apple.com/documentation/xctest/xcuiapplication)
- [XCTestHTMLReport GitHub](https://github.com/XCTestHTMLReport/XCTestHTMLReport)
- [FFmpegKit iOS](https://github.com/arthenica/ffmpeg-kit)
- [TruffleHog Documentation](https://github.com/trufflesecurity/trufflehog)
- [Apple Performance Testing Guide](https://developer.apple.com/documentation/xctest/performance_tests)
- [Server-Sent Events Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)

---

*Last Updated: September 9, 2025*
*Research conducted for Claude Code UI iOS E2E Testing Framework*