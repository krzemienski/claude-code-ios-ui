# iOS Functional Testing Guide

## 📋 Overview

This guide provides comprehensive documentation for the iOS Claude Code UI functional testing infrastructure. The testing pipeline ensures all features work correctly with the backend server and provides continuous integration support.

## 🚀 Quick Start

### Prerequisites

1. **Backend Server**: Ensure the backend is running at `http://192.168.0.155:3004`
   ```bash
   cd backend
   npm install
   npm start
   ```

2. **Xcode**: Version 15.0 or later
3. **iOS Simulator**: iPhone 15 with iOS 17.0+
4. **Python 3**: For test result parsing
5. **Node.js**: Version 18+ for backend

### Running Tests Locally

```bash
# Run all functional tests
cd ClaudeCodeUI-iOS/Scripts
./run-functional-tests.sh

# Run with auto backend start
./run-functional-tests.sh --auto-start-backend

# Run with custom backend URL
./run-functional-tests.sh --backend-url http://localhost:3004

# Run with specific simulator
./run-functional-tests.sh --simulator "iPhone 15 Pro"
```

## 🏗️ Test Architecture

### Test Structure

```
ClaudeCodeUI-iOS/
├── ClaudeCodeUITests/              # Unit tests
│   ├── FunctionalTestOrchestrator.swift
│   ├── ChatViewModelTests.swift
│   └── WebSocketMessageParserTests.swift
├── ClaudeCodeUIIntegrationTests/   # Integration tests
│   ├── APIIntegrationTests.swift
│   ├── WebSocketIntegrationTests.swift
│   └── SessionFlowE2ETests.swift
├── ClaudeCodeUIUITests/            # UI tests
│   ├── NavigationFlowTests.swift
│   └── PerformanceTests.swift
├── Scripts/                        # Test automation
│   ├── run-functional-tests.sh
│   └── parse_results.py
└── .github/workflows/              # CI/CD
    └── functional-tests.yml
```

### Test Categories

#### 1. Unit Tests (`ClaudeCodeUITests`)
- **Purpose**: Test individual components in isolation
- **Coverage**: ViewModels, Models, Utilities, Parsers
- **Examples**:
  - `ChatViewModelTests`: Message handling logic
  - `WebSocketMessageParserTests`: JSON parsing
  - `AuthenticationManagerTests`: Token management

#### 2. Integration Tests (`ClaudeCodeUIIntegrationTests`)
- **Purpose**: Test component interactions with backend
- **Coverage**: API calls, WebSocket connections, Data persistence
- **Examples**:
  - `APIIntegrationTests`: REST endpoint testing
  - `WebSocketIntegrationTests`: Real-time messaging
  - `SessionFlowE2ETests`: Complete user workflows

#### 3. UI Tests (`ClaudeCodeUIUITests`)
- **Purpose**: Test user interface and interactions
- **Coverage**: Navigation, User flows, Performance
- **Examples**:
  - `NavigationFlowTests`: Tab navigation
  - `PerformanceTests`: Launch time, scrolling

#### 4. Functional Test Orchestrator
The `FunctionalTestOrchestrator` coordinates comprehensive testing:
- Environment setup validation
- Backend connectivity checks
- WebSocket connection testing
- Project list loading
- Session management
- Message exchange
- Performance metrics
- Error recovery

## 📊 Test Coverage

### Current Coverage (79% API Implementation)

| Category | Implemented | Total | Coverage |
|----------|-------------|-------|----------|
| Authentication | 5 | 5 | 100% |
| Projects | 5 | 5 | 100% |
| Sessions | 6 | 6 | 100% |
| Files | 4 | 4 | 100% |
| Git | 20 | 20 | 100% |
| MCP | 6 | 6 | 100% |
| Search | 2 | 2 | 100% |
| Cursor | 0 | 8 | 0% |
| Transcription | 0 | 1 | 0% |
| Settings | 0 | 2 | 0% |

### Test Flows

1. **Authentication Flow**
   - JWT token validation
   - Session persistence
   - Auto-refresh mechanism

2. **Project Management Flow**
   - List projects
   - Select project
   - Navigate to sessions

3. **Session Management Flow**
   - Create session
   - Load existing sessions
   - Delete sessions
   - Session state persistence

4. **WebSocket Communication Flow**
   - Connect to WebSocket
   - Send messages
   - Receive responses
   - Handle reconnection

5. **File Operations Flow**
   - Browse files
   - Open files
   - Navigate directories

6. **Git Integration Flow**
   - View status
   - Stage changes
   - Commit
   - Push/Pull

## 🔧 Test Automation

### Automation Script Features

The `run-functional-tests.sh` script provides:

1. **Backend Management**
   - Automatic backend startup
   - Health check validation
   - Graceful shutdown

2. **Build Management**
   - Clean builds
   - Dependency resolution
   - Code signing bypass for tests

3. **Test Execution**
   - Sequential test suite execution
   - Parallel test support
   - Result collection

4. **Reporting**
   - Comprehensive test summaries
   - Performance metrics
   - Failure analysis
   - JSON export

### Script Options

```bash
Options:
  --backend-url URL      Backend URL (default: http://192.168.0.155:3004)
  --simulator NAME       Simulator name (default: iPhone 15)
  --auto-start-backend   Automatically start backend if not running
  --help                 Show help message
```

## 📈 Test Result Analysis

### Result Parser

The `parse_results.py` script provides:

1. **Metrics Extraction**
   - Test counts (passed/failed/skipped)
   - Execution duration
   - Performance metrics

2. **Failure Analysis**
   - Detailed failure messages
   - File locations
   - Stack traces

3. **Report Generation**
   - Markdown summaries
   - JSON export
   - CI/CD integration

### Performance Metrics

Tracked metrics include:
- **Launch Time**: App startup duration
- **Memory Usage**: Peak memory consumption
- **Frame Rate**: UI rendering performance
- **Response Time**: API call latency
- **WebSocket Latency**: Message round-trip time

## 🚦 CI/CD Integration

### GitHub Actions Workflow

The `.github/workflows/functional-tests.yml` provides:

1. **Trigger Events**
   - Push to main/develop
   - Pull requests
   - Manual dispatch

2. **Test Stages**
   - Environment setup
   - Backend startup
   - Build phase
   - Test execution
   - Result parsing
   - Artifact upload

3. **Configurable Parameters**
   - Backend URL
   - Test type selection
   - Simulator version

### Workflow Dispatch Options

```yaml
inputs:
  backend_url:
    description: 'Backend URL for testing'
    default: 'http://localhost:3004'
  test_type:
    description: 'Type of tests to run'
    options:
      - all
      - unit
      - integration
      - ui
      - performance
```

## 🐛 Troubleshooting

### Common Issues

1. **Simulator Won't Boot**
   ```bash
   # Reset simulator
   xcrun simctl erase all
   
   # Boot specific simulator
   xcrun simctl boot "iPhone 15"
   ```

2. **Backend Connection Failed**
   ```bash
   # Check backend health
   curl http://192.168.0.155:3004/health
   
   # Check network settings
   ifconfig | grep 192.168
   ```

3. **Test Timeouts**
   - Increase timeout values in test code
   - Check backend response times
   - Verify network connectivity

4. **Build Failures**
   ```bash
   # Clean derived data
   rm -rf ~/Library/Developer/Xcode/DerivedData
   
   # Regenerate project
   tuist generate
   ```

### Debug Mode

Enable verbose logging:
```swift
// In test setup
UserDefaults.standard.set(true, forKey: "enableVerboseLogging")
```

View test logs:
```bash
# Real-time log streaming
xcrun simctl spawn booted log stream --level debug --predicate 'processImagePath contains "ClaudeCodeUI"'
```

## 🎯 Best Practices

### Writing Tests

1. **Use Descriptive Names**
   ```swift
   func testWebSocketReconnectsAfterNetworkFailure() { }
   ```

2. **Follow AAA Pattern**
   ```swift
   // Arrange
   let viewModel = ChatViewModel()
   
   // Act
   viewModel.sendMessage("Test")
   
   // Assert
   XCTAssertEqual(viewModel.messages.count, 1)
   ```

3. **Use Expectations for Async**
   ```swift
   let expectation = expectation(description: "API call")
   
   apiClient.fetchData { result in
       XCTAssertNotNil(result)
       expectation.fulfill()
   }
   
   wait(for: [expectation], timeout: 10)
   ```

4. **Clean Up Resources**
   ```swift
   override func tearDown() {
       webSocket?.disconnect()
       super.tearDown()
   }
   ```

### Performance Testing

1. **Measure Critical Paths**
   ```swift
   measure {
       // Code to benchmark
   }
   ```

2. **Set Baselines**
   - Launch time: < 1 second
   - Memory: < 100MB
   - Frame rate: 60 FPS

3. **Monitor Trends**
   - Track metrics over time
   - Alert on regressions

## 📚 Additional Resources

### Documentation
- [Apple Testing Documentation](https://developer.apple.com/documentation/xctest)
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [UI Testing Best Practices](https://developer.apple.com/documentation/xctest/user_interface_tests)

### Tools
- **xcpretty**: Better test output formatting
- **xcov**: Code coverage reporting
- **fastlane**: Automation toolchain
- **Instruments**: Performance profiling

## 🔄 Continuous Improvement

### Adding New Tests

1. **Identify Test Gap**
   - Review coverage reports
   - Analyze bug reports
   - User feedback

2. **Write Test Case**
   - Follow naming conventions
   - Add to appropriate test class
   - Include documentation

3. **Update Automation**
   - Add to test suites
   - Update CI/CD if needed
   - Document changes

### Maintenance

- **Weekly**: Review failing tests
- **Monthly**: Update test data
- **Quarterly**: Coverage analysis
- **Yearly**: Framework updates

## 📞 Support

For issues or questions:
1. Check this documentation
2. Review test logs
3. Consult team lead
4. File GitHub issue

---

*Last Updated: January 2025*
*Version: 2.0*