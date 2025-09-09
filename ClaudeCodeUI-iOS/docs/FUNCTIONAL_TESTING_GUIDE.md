# Functional Testing Guide

## Overview

This guide provides comprehensive documentation for the ClaudeCodeUI iOS app's functional testing infrastructure, including setup, execution, troubleshooting, and continuous integration.

## Table of Contents

1. [Test Architecture](#test-architecture)
2. [Setup Requirements](#setup-requirements)
3. [Running Tests](#running-tests)
4. [Test Categories](#test-categories)
5. [Continuous Integration](#continuous-integration)
6. [Troubleshooting](#troubleshooting)
7. [Adding New Tests](#adding-new-tests)
8. [Best Practices](#best-practices)

## Test Architecture

### Test Suite Structure

```
ClaudeCodeUITests/
├── FunctionalTestSuite.swift      # Unified test orchestrator
├── Unit Tests/
│   ├── ChatViewModelTests.swift
│   └── WebSocketMessageParserTests.swift
└── Integration Tests/
    ├── AuthenticationIntegrationTests.swift
    ├── WebSocketIntegrationTests.swift
    ├── APIIntegrationTests.swift
    ├── DataPersistenceIntegrationTests.swift
    ├── UIFlowIntegrationTests.swift
    ├── SessionFlowE2ETests.swift
    └── PerformanceIntegrationTests.swift
```

### Test Execution Phases

1. **Phase 1: Unit Tests** - Core logic validation
2. **Phase 2: Integration Tests** - Backend service integration
3. **Phase 3: Validation Tests** - Performance and edge cases

## Setup Requirements

### Prerequisites

1. **Xcode 15.0+** - Latest version recommended
2. **iOS 17.0+ Simulator** - iPhone 15 preferred
3. **Node.js 18+** - For backend server
4. **CocoaPods** - For iOS dependencies

### Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Start the server
npm start

# Verify health endpoint
curl http://192.168.0.155:3004/health
```

### iOS Setup

```bash
# Navigate to iOS directory
cd ClaudeCodeUI-iOS

# Install CocoaPods (if using)
pod install

# Open workspace
open ClaudeCodeUI.xcworkspace
```

## Running Tests

### Quick Start

```bash
# Run all functional tests with backend
./Scripts/run-functional-tests.sh
```

### Manual Execution

#### Via Xcode

1. Open `ClaudeCodeUI.xcworkspace`
2. Select scheme: `ClaudeCodeUI`
3. Select destination: `iPhone 15 Simulator`
4. Press `Cmd+U` or Product → Test

#### Via Command Line

```bash
# Run all tests
xcodebuild test \
  -workspace ClaudeCodeUI.xcworkspace \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test suite
xcodebuild test \
  -workspace ClaudeCodeUI.xcworkspace \
  -scheme ClaudeCodeUI \
  -only-testing:ClaudeCodeUITests/FunctionalTestSuite

# Run with xcpretty for better output
xcodebuild test ... | xcpretty
```

### Test Execution Options

```bash
# Skip backend startup (if already running)
./Scripts/run-functional-tests.sh --skip-backend

# Run specific test categories
xcodebuild test \
  -only-testing:ClaudeCodeUITests \           # Unit tests only
  -only-testing:ClaudeCodeUIIntegrationTests  # Integration tests only
```

## Test Categories

### Unit Tests

Tests core business logic without external dependencies.

- **ChatViewModelTests**: Message handling, state management
- **WebSocketMessageParserTests**: Protocol parsing, error handling

### Integration Tests

Tests interaction with backend services.

- **AuthenticationIntegrationTests**: Login, token management, session handling
- **WebSocketIntegrationTests**: Real-time connection, message flow
- **APIIntegrationTests**: REST endpoints, error responses
- **DataPersistenceIntegrationTests**: Core Data, offline storage

### UI Flow Tests

Tests user interface and navigation.

- **UIFlowIntegrationTests**: Screen transitions, user interactions
- **UIFeaturesIntegrationTests**: Component behavior, gestures

### End-to-End Tests

Tests complete user journeys.

- **SessionFlowE2ETests**: Full login-to-logout workflow
- **PerformanceIntegrationTests**: Load testing, memory usage
- **EdgeCaseIntegrationTests**: Error scenarios, network failures

## Continuous Integration

### GitHub Actions Workflow

The CI pipeline automatically runs on:
- Push to `main` or `develop` branches
- Pull requests to `main`
- Manual workflow dispatch

### Workflow Features

1. **Parallel Test Execution** - Runs tests concurrently
2. **Test Reporting** - JUnit XML reports with annotations
3. **Coverage Reports** - Codecov integration
4. **Artifact Storage** - Test results and logs
5. **Failure Notifications** - Slack/issue creation

### Manual Trigger

```yaml
# Trigger specific test category
workflow_dispatch:
  inputs:
    test_category:
      - all
      - unit
      - integration
      - performance
      - e2e
```

## Troubleshooting

### Common Issues

#### Backend Connection Failed

**Error**: "Backend is not running at http://192.168.0.155:3004"

**Solution**:
```bash
# Check if backend is running
ps aux | grep node

# Start backend manually
cd backend && npm start

# Check logs
tail -f backend/logs/server.log
```

#### Simulator Issues

**Error**: "Unable to boot simulator"

**Solution**:
```bash
# Reset simulator
xcrun simctl shutdown all
xcrun simctl erase all

# Create new simulator
xcrun simctl create "iPhone 15" \
  "com.apple.CoreSimulator.SimDeviceType.iPhone-15" \
  "com.apple.CoreSimulator.SimRuntime.iOS-17-0"
```

#### Test Timeout

**Error**: "Test exceeded timeout"

**Solution**:
- Increase timeout in test configuration
- Check network connectivity
- Verify backend response times

#### WebSocket Connection Issues

**Error**: "WebSocket failed to connect"

**Solution**:
```swift
// Check WebSocket URL configuration
let config = AppConfig.shared
print("WebSocket URL: \(config.wsURL)")

// Verify certificate if using WSS
// Add exception for local development
```

### Debug Mode

Enable verbose logging:

```swift
// In AppConfig.swift
AppConfig.shared.enableDebugLogging = true

// In test files
override func setUp() {
    super.setUp()
    TestHelper.enableVerboseLogging()
}
```

## Adding New Tests

### 1. Create Test File

```swift
import XCTest
@testable import ClaudeCodeUI

class NewFeatureTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Setup code
    }
    
    override func tearDown() {
        // Cleanup code
        super.tearDown()
    }
    
    func testNewFeature() {
        // Test implementation
    }
}
```

### 2. Add to Test Suite

```swift
// In FunctionalTestSuite.swift
override class var defaultTestSuite: XCTestSuite {
    let suite = XCTestSuite(name: "Functional Tests")
    
    // Add your test
    suite.addTest(NewFeatureTests.defaultTestSuite)
    
    return suite
}
```

### 3. Update CI Configuration

```yaml
# In .github/workflows/ios-functional-tests.yml
- name: Run tests
  run: |
    xcodebuild test \
      -only-testing:ClaudeCodeUITests/NewFeatureTests
```

## Best Practices

### Test Design

1. **Isolation** - Tests should not depend on each other
2. **Repeatability** - Tests must produce consistent results
3. **Speed** - Keep tests fast (< 1 second for unit tests)
4. **Coverage** - Aim for 80%+ code coverage
5. **Documentation** - Clear test names and comments

### Naming Conventions

```swift
// Good test names
func testAuthenticationWithValidCredentialsSucceeds()
func testWebSocketReconnectsAfterNetworkFailure()
func testMessagePersistenceAcrossSessions()

// Bad test names
func testAuth()
func test1()
func testStuff()
```

### Assertions

```swift
// Use specific assertions
XCTAssertEqual(result, expected, "Result should match expected value")
XCTAssertTrue(condition, "Condition should be true")
XCTAssertNil(error, "Error should be nil for successful operation")

// Wait for async operations
let expectation = expectation(description: "Async operation")
asyncOperation { result in
    XCTAssertNotNil(result)
    expectation.fulfill()
}
wait(for: [expectation], timeout: 5.0)
```

### Mock Data

```swift
// Use consistent test data
struct TestData {
    static let validUser = User(id: "test-123", name: "Test User")
    static let validToken = "test-token-abc123"
    static let testMessage = Message(content: "Test message")
}
```

### Error Handling

```swift
// Test both success and failure paths
func testAPICallSuccess() {
    // Test successful response
}

func testAPICallFailure() {
    // Test error handling
}

func testAPICallTimeout() {
    // Test timeout scenario
}
```

## Performance Benchmarks

### Target Metrics

- **Unit Tests**: < 1 second per test
- **Integration Tests**: < 5 seconds per test
- **E2E Tests**: < 30 seconds per workflow
- **Total Suite**: < 5 minutes

### Monitoring

```bash
# Generate performance report
xcrun xcresulttool get \
  --format json \
  --path TestResults.xcresult \
  | jq '.metrics.testsCount, .metrics.totalDuration'
```

## Maintenance

### Regular Tasks

1. **Weekly** - Review failing tests, update mocks
2. **Monthly** - Update dependencies, review coverage
3. **Quarterly** - Performance audit, refactor slow tests

### Test Data Cleanup

```bash
# Clean test data from backend
curl -X DELETE http://192.168.0.155:3004/api/test/cleanup

# Reset Core Data
rm -rf ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Documents/*.sqlite
```

## Support

### Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [CI/CD Best Practices](https://docs.github.com/actions)
- [Backend API Documentation](../backend/README.md)

### Contact

For issues or questions:
1. Check this documentation
2. Review existing GitHub issues
3. Contact the development team

## Appendix

### Environment Variables

```bash
# Test environment
export TEST_ENV=local
export BACKEND_URL=http://192.168.0.155:3004
export WS_URL=ws://192.168.0.155:3004
export LOG_LEVEL=debug
```

### Useful Commands

```bash
# List simulators
xcrun simctl list devices

# Open simulator
open -a Simulator

# View test logs
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.claudecode.ui"'

# Export test results
xcresulttool get --path TestResults.xcresult --format human
```

---

Last Updated: September 2024
Version: 1.0.0