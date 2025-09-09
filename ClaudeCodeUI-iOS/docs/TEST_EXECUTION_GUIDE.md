# Test Execution & Infrastructure Guide

## Overview

The ClaudeCode iOS Test Infrastructure provides comprehensive end-to-end testing with automated execution, performance monitoring, and continuous integration.

## Quick Start

### Running Complete Test Suite

```bash
# Execute master test runner
./Scripts/master-test-runner.sh

# Run with specific options
./Scripts/master-test-runner.sh --stress --performance
```

### Individual Test Components

```bash
# WebSocket validation
swift Scripts/enhanced-websocket-test.swift --url ws://192.168.0.155:3004/ws

# UI tests only
./Scripts/run-ui-tests.sh

# Performance tests
./Scripts/run-performance-tests.sh
```

## Test Architecture

### Master Test Runner

The `master-test-runner.sh` orchestrates the complete test flow:

1. **Environment Setup**
   - Creates result directories
   - Validates required tools
   - Initializes logging

2. **Backend Server Management**
   - Starts Node.js backend
   - Validates health endpoint
   - Manages server lifecycle

3. **Application Build & Install**
   - Generates Xcode project with Tuist
   - Builds for testing
   - Installs on simulator

4. **Test Execution Phases**
   - App launch validation
   - WebSocket connectivity
   - Project list loading
   - Navigation flows
   - Message interaction
   - Performance metrics

5. **Report Generation**
   - HTML reports with screenshots
   - JSON metrics export
   - Performance analytics

### Test Categories

#### Unit Tests
- Core logic validation
- Model testing
- ViewModel verification
- Service layer tests
- 80% minimum coverage

#### Integration Tests
- API client testing
- WebSocket communication
- Data persistence
- Authentication flows
- Session management

#### UI Tests
- User journey validation
- Navigation testing
- Form interactions
- Gesture recognition
- Accessibility compliance

#### Performance Tests
- Load time metrics
- Memory profiling
- CPU usage monitoring
- Network efficiency
- Scrolling performance

## WebSocket Testing

### Enhanced WebSocket Validator

The enhanced WebSocket test suite validates:

- **Connection establishment** - Handshake and authentication
- **Message exchange** - Request/response patterns
- **Streaming data** - Real-time data flow
- **Performance metrics** - Latency and throughput
- **Stress conditions** - High-volume messaging

### Running WebSocket Tests

```bash
# Basic test
swift Scripts/enhanced-websocket-test.swift

# With performance metrics
swift Scripts/enhanced-websocket-test.swift --performance

# Stress testing
swift Scripts/enhanced-websocket-test.swift --stress --messages 1000
```

### WebSocket Metrics

- **Connection time** - Time to establish connection
- **Average latency** - Round-trip message time
- **P95/P99 latency** - Percentile measurements
- **Throughput** - Messages per second
- **Success rate** - Percentage of successful messages

## Continuous Integration

### GitHub Actions Workflow

The CI pipeline runs on:
- Push to main/develop branches
- Pull requests
- Scheduled daily runs
- Manual dispatch

### Pipeline Stages

1. **Setup** - Environment preparation
2. **Build** - Application compilation
3. **Unit Tests** - Core functionality
4. **Integration Tests** - System integration
5. **UI Tests** - User interface validation
6. **Performance Tests** - Performance benchmarks
7. **Report** - Consolidated reporting
8. **Notify** - Slack/email notifications

### Test Matrix

| Device | iOS Version | Test Suite |
|--------|------------|------------|
| iPhone 15 Pro | 17.2 | Full |
| iPhone 14 | 16.4 | Smoke |
| iPad Pro | 17.2 | Tablet |

## Performance Monitoring

### Metrics Collection

```javascript
// CPU Usage
xcrun simctl get_app_container booted com.example.ClaudeCodeUI data

// Memory Profile
instruments -t "Activity Monitor" -D profile.trace

// Network Activity
nettop -P <app_pid>
```

### Performance Baselines

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| App Launch | <1s | <2s | >3s |
| Project Load | <500ms | <1s | >2s |
| Message Send | <100ms | <200ms | >500ms |
| Scroll FPS | 60 | 30 | <30 |
| Memory | <100MB | <200MB | >300MB |

## Test Reports

### HTML Reports

Generated reports include:
- Test execution summary
- Pass/fail breakdown
- Performance graphs
- Screenshot gallery
- Detailed logs

### Accessing Reports

```bash
# Open latest report
open TestResults_*/test_report.html

# Archive results
tar -czf results.tar.gz TestResults_*
```

### Report Sections

1. **Summary Dashboard**
   - Total tests run
   - Pass rate percentage
   - Execution duration
   - Coverage metrics

2. **Test Details**
   - Individual test results
   - Failure reasons
   - Stack traces
   - Timing information

3. **Performance Analysis**
   - CPU usage graphs
   - Memory consumption
   - Network activity
   - Response times

4. **Screenshots**
   - Key interaction points
   - Failure captures
   - Before/after states

## Troubleshooting

### Common Issues

#### Backend Connection Failed
```bash
# Check backend status
curl http://192.168.0.155:3004/health

# Restart backend
pkill -f "backend/server.js"
node backend/server.js &
```

#### Simulator Issues
```bash
# Reset simulator
xcrun simctl erase all

# Boot specific device
xcrun simctl boot "iPhone 15 Pro"
```

#### Test Timeouts
```bash
# Increase timeout in test
export TEST_TIMEOUT=600

# Run with extended timeout
./Scripts/master-test-runner.sh --timeout 600
```

### Debug Mode

Enable verbose logging:
```bash
export DEBUG=true
export VERBOSE_LOGGING=1
./Scripts/master-test-runner.sh
```

### Log Locations

- Build logs: `TestResults_*/build.log`
- Test logs: `TestResults_*/*.log`
- Backend logs: `TestResults_*/backend.log`
- Performance data: `TestResults_*/metrics/`

## Best Practices

### Writing Tests

1. **Use Page Object Pattern**
   ```swift
   class ProjectListPage {
       func tapProject(named: String) { }
       func verifyProjectVisible(named: String) { }
   }
   ```

2. **Implement Proper Waits**
   ```swift
   let element = app.buttons["Continue"]
   XCTAssertTrue(element.waitForExistence(timeout: 5))
   ```

3. **Clean Test Data**
   ```swift
   override func tearDown() {
       // Clean up test data
       super.tearDown()
   }
   ```

### Test Naming

- Descriptive names: `testUserCanNavigateFromProjectListToChat`
- Given-When-Then format
- Include expected outcome

### Test Organization

```
Tests/
├── Unit/
│   ├── Models/
│   ├── ViewModels/
│   └── Services/
├── Integration/
│   ├── API/
│   ├── WebSocket/
│   └── Database/
└── UI/
    ├── Flows/
    ├── Screens/
    └── Components/
```

## Maintenance

### Regular Tasks

#### Weekly
- Review test failures
- Update performance baselines
- Clean old test results

#### Monthly
- Update device matrix
- Review test coverage
- Optimize slow tests

#### Quarterly
- Audit test infrastructure
- Update CI/CD pipeline
- Performance benchmarking

### Updating Tests

1. **Add New Test**
   ```swift
   func testNewFeature() {
       // Test implementation
   }
   ```

2. **Update Test Runner**
   ```bash
   # Add to master-test-runner.sh
   run_test "new_feature" "test_new_feature"
   ```

3. **Update CI Pipeline**
   ```yaml
   # Add to continuous-testing.yml
   - name: Run new feature tests
     run: xcodebuild test -only-testing:NewFeatureTests
   ```

## Advanced Configuration

### Environment Variables

```bash
# Backend configuration
export BACKEND_URL="ws://192.168.0.155:3004/ws"
export BACKEND_TIMEOUT=30

# Test configuration
export TEST_TIMEOUT=300
export SCREENSHOT_ON_FAILURE=true
export PERFORMANCE_TRACKING=true

# Reporting
export REPORT_FORMAT="html"
export SEND_NOTIFICATIONS=true
```

### Custom Test Schemes

Create custom test plans in Xcode:
1. Product → Scheme → Edit Scheme
2. Test → Info → Add Test Plan
3. Configure test selection
4. Save as `.xctestplan`

### Parallel Execution

```bash
# Run tests in parallel
xcodebuild test \
  -parallel-testing-enabled YES \
  -maximum-concurrent-test-simulator-destinations 4
```

## Resources

### Documentation
- [Apple Testing Documentation](https://developer.apple.com/documentation/xctest)
- [Tuist Documentation](https://docs.tuist.io)
- [GitHub Actions for iOS](https://docs.github.com/en/actions)

### Tools
- **Xcode** - IDE and testing tools
- **Tuist** - Project generation
- **xcpretty** - Test output formatting
- **Instruments** - Performance profiling
- **Charles Proxy** - Network debugging

### Support

For issues or questions:
1. Check troubleshooting guide above
2. Review test logs in `TestResults_*`
3. Contact team via Slack #ios-testing
4. Create GitHub issue with logs attached

---

## Quick Reference

### Essential Commands

```bash
# Run all tests
./Scripts/master-test-runner.sh

# Run specific test suite
xcodebuild test -only-testing:ClaudeCodeUITests

# Generate report
python3 Scripts/generate_test_report.py \
  --results-dir TestResults_* \
  --output-file report.html

# Clean test data
rm -rf TestResults_*
xcrun simctl erase all
```

### Test Status Indicators

- ✅ **PASSED** - Test completed successfully
- ❌ **FAILED** - Test failed, needs investigation
- ⏭️ **SKIPPED** - Test was not executed
- 🔄 **RUNNING** - Test currently executing
- ⚠️ **WARNING** - Test passed with warnings

---

Last Updated: January 2025
Version: 1.0.0