# iOS Functional Test Automation Guide

## Complete Working Commands and Configuration

### 1. iOS Simulator Control Commands

#### List Available Simulators
```bash
# List all available iOS simulators
xcrun simctl list devices available

# Filter for iPhone simulators only
xcrun simctl list devices available | grep "iPhone"

# Get booted simulators
xcrun simctl list devices | grep "Booted"
```

#### Currently Available Simulators (January 2025)
- iPhone 16 Pro: `BECB3FA0-518E-4F80-8B8E-7E10C16F3B36` (Booted)
- iPhone 16 Pro Max: `50523130-57AA-48B0-ABD0-4D59CE455F14` (Booted)

#### Simulator Control Commands
```bash
# Boot a specific simulator
xcrun simctl boot BECB3FA0-518E-4F80-8B8E-7E10C16F3B36

# Shutdown simulator
xcrun simctl shutdown BECB3FA0-518E-4F80-8B8E-7E10C16F3B36

# Erase simulator (reset to factory)
xcrun simctl erase BECB3FA0-518E-4F80-8B8E-7E10C16F3B36

# Open Simulator app
open -a Simulator

# Install app on simulator
xcrun simctl install BECB3FA0-518E-4F80-8B8E-7E10C16F3B36 /path/to/ClaudeCodeUI.app

# Launch app on simulator
xcrun simctl launch BECB3FA0-518E-4F80-8B8E-7E10C16F3B36 com.claudecode.ClaudeCodeUI

# Terminate app
xcrun simctl terminate BECB3FA0-518E-4F80-8B8E-7E10C16F3B36 com.claudecode.ClaudeCodeUI
```

### 2. Network Configuration for Backend Connection

#### Update Backend URL to 192.168.0.155:3004

The app needs to connect to the backend at `http://192.168.0.155:3004`. Configure this in multiple places:

#### A. Launch Arguments (Recommended)
```swift
// In test setup
app.launchArguments = [
    "UI-Testing",
    "--backend-url", "http://192.168.0.155:3004",
    "--no-mocks",
    "--real-backend"
]

app.launchEnvironment = [
    "TESTING_MODE": "true",
    "BACKEND_URL": "http://192.168.0.155:3004",
    "USE_REAL_BACKEND": "true"
]
```

#### B. Info.plist Configuration
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>192.168.0.155</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 3. Building and Running Tests

#### Build the App
```bash
# Build for testing
xcodebuild build-for-testing \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,id=BECB3FA0-518E-4F80-8B8E-7E10C16F3B36' \
    -derivedDataPath build

# Location of built app
find build -name "*.app" -type d
```

#### Run UI Tests
```bash
# Run specific test class
xcodebuild test \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,id=BECB3FA0-518E-4F80-8B8E-7E10C16F3B36' \
    -only-testing:ClaudeCodeUIUITests/ClaudeCodeUIUITests/testChatMessagingWithRealBackend

# Run all UI tests
xcodebuild test \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination 'platform=iOS Simulator,id=BECB3FA0-518E-4F80-8B8E-7E10C16F3B36' \
    -only-testing:ClaudeCodeUIUITests
```

### 4. WebSocket Connection Testing

#### Direct WebSocket Test Script
```bash
# Run the WebSocket test script
swift /Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Scripts/test-websocket-connection.swift

# Test with custom URL
echo 'ws://192.168.0.155:3004' | swift Scripts/test-websocket-connection.swift
```

#### Verify Backend is Running
```bash
# Check if backend is accessible
curl -I http://192.168.0.155:3004/health

# Test WebSocket endpoint
curl -i -N \
    -H "Connection: Upgrade" \
    -H "Upgrade: websocket" \
    -H "Sec-WebSocket-Version: 13" \
    -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
    http://192.168.0.155:3004/ws
```

### 5. UI Element Identification

#### Common UI Elements in ClaudeCodeUI
```swift
// Tab Bar Navigation
app.tabBars.buttons["Projects"].tap()
app.tabBars.buttons["Sessions"].tap()
app.tabBars.buttons["Chat"].tap()

// Projects List
app.collectionViews.firstMatch  // Grid view
app.tables.firstMatch            // List view
app.collectionViews.cells.firstMatch.tap()

// Sessions List
app.tables.cells.firstMatch.tap()
app.navigationBars.buttons["Add"].tap()

// Chat Interface
app.textViews["messageInput"]
app.buttons["sendButton"]
app.scrollViews["chatScrollView"]
app.tables["messagesTable"]
```

### 6. Complete Test Execution Flow

```bash
#!/bin/bash
# Complete test execution script

# 1. Start backend (if not running)
echo "Starting backend server..."
cd backend && npm start &
BACKEND_PID=$!
sleep 5

# 2. Boot simulator
SIMULATOR_ID="BECB3FA0-518E-4F80-8B8E-7E10C16F3B36"
echo "Booting simulator..."
xcrun simctl boot $SIMULATOR_ID || true

# 3. Build app
echo "Building app..."
xcodebuild build-for-testing \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath build

# 4. Install app
APP_PATH=$(find build -name "ClaudeCodeUI.app" -type d | head -1)
echo "Installing app from: $APP_PATH"
xcrun simctl install $SIMULATOR_ID "$APP_PATH"

# 5. Run tests
echo "Running UI tests..."
xcodebuild test \
    -workspace ClaudeCodeUI.xcworkspace \
    -scheme ClaudeCodeUI \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -only-testing:ClaudeCodeUIUITests \
    -resultBundlePath TestResults.xcresult

# 6. Generate report
xcrun xcresulttool get --path TestResults.xcresult --format json > test-results.json

# Cleanup
kill $BACKEND_PID
```

### 7. Debugging Commands

```bash
# View simulator logs
xcrun simctl spawn booted log stream --level debug --predicate 'subsystem == "com.claudecode.ClaudeCodeUI"'

# Screenshot
xcrun simctl io booted screenshot test-screenshot.png

# Record video
xcrun simctl io booted recordVideo test-recording.mov

# Open app data container
xcrun simctl get_app_container booted com.claudecode.ClaudeCodeUI data
```

### 8. Environment Variables for Testing

```bash
export SIMULATOR_UUID="BECB3FA0-518E-4F80-8B8E-7E10C16F3B36"
export BACKEND_URL="http://192.168.0.155:3004"
export USE_REAL_BACKEND="true"
export TESTING_MODE="true"
```

## Important Notes

1. **No Mocks**: All tests run against the REAL backend at 192.168.0.155:3004
2. **Network Access**: Ensure the simulator can reach the backend IP address
3. **Backend Must Be Running**: Start the backend before running tests
4. **Simulator State**: Reset simulator if tests fail due to app state issues
5. **Bundle ID**: The app bundle ID is `com.claudecode.ClaudeCodeUI`