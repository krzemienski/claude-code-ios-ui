# Build and Infrastructure Documentation

## Overview
This document provides complete instructions for building, configuring, and running the ClaudeCodeUI iOS app with its backend server.

## System Requirements
- macOS with Xcode 15.0 or later
- iOS Simulator (iPhone 16 Pro or similar)
- Node.js and npm (for backend server)
- Network connectivity between simulator and backend server

## Build Configuration

### Xcode Project Settings
- **Scheme**: ClaudeCodeUI
- **Configuration**: Debug
- **Platform**: iOS Simulator
- **Target Device**: iPhone 16 Pro (or iPhone 16 Pro Max)
- **Bundle Identifier**: com.claudecode.ui
- **Minimum iOS Version**: 17.0

### Backend Configuration
- **Host**: 192.168.0.155
- **Port**: 3004
- **Base URL**: http://192.168.0.155:3004
- **WebSocket URL**: ws://192.168.0.155:3004/ws

## Quick Start

### 1. Build and Install the App
```bash
# Navigate to scripts directory
cd /Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Scripts

# Run the build and install script
./build-and-install.sh
```

This script will:
- Clean any previous builds
- Build the app for iPhone 16 Pro simulator
- Install the app on the simulator
- Launch the app
- Open the simulator window

### 2. Start the Backend Server (if needed)
```bash
# Start the backend server
./start-backend-server.sh
```

### 3. Verify Connectivity
```bash
# Check app connectivity to backend
./verify-app-connectivity.sh
```

## Build Commands

### Manual Build Commands
```bash
# Clean build
xcodebuild clean -scheme "ClaudeCodeUI" -configuration Debug

# Build for simulator
xcodebuild \
    -scheme "ClaudeCodeUI" \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -configuration Debug \
    build

# Install on simulator
xcrun simctl install "SIMULATOR_UUID" /path/to/ClaudeCodeUI.app

# Launch app
xcrun simctl launch "SIMULATOR_UUID" com.claudecode.ui
```

### Simulator Management
```bash
# List available simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "SIMULATOR_UUID"

# Shutdown simulator
xcrun simctl shutdown "SIMULATOR_UUID"

# Terminate app
xcrun simctl terminate "SIMULATOR_UUID" com.claudecode.ui

# Uninstall app
xcrun simctl uninstall "SIMULATOR_UUID" com.claudecode.ui
```

## Network Configuration

### Backend URL Configuration
The app uses the following priority for backend URL configuration:
1. Launch arguments (for UI testing): `--backend-url http://localhost:3004`
2. Environment variable: `BACKEND_URL`
3. UserDefaults saved value
4. Default hardcoded value: `http://192.168.0.155:3004`

### Modifying Backend URL
To change the backend URL, edit `/Core/Config/AppConfig.swift`:
```swift
// Line 51: Update default backend URL
return "http://192.168.0.155:3004"

// Line 55: Update default for resetting
private static let defaultBackendURL = "http://192.168.0.155:3004"
```

## Troubleshooting

### Build Issues
1. **Simulator not found**: 
   - Run `xcrun simctl list devices` to see available simulators
   - Update `SIMULATOR_NAME` in build script

2. **Build fails with Swift errors**:
   - Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/ClaudeCodeUI-*`
   - Clean build folder: Product → Clean Build Folder in Xcode
   - Rebuild

3. **App crashes on launch**:
   - Check simulator logs: `xcrun simctl spawn SIMULATOR_UUID log stream --predicate 'processImagePath endswith "ClaudeCodeUI"'`
   - Verify Info.plist configuration
   - Check for missing resources

### Network Issues
1. **Cannot connect to backend**:
   - Verify backend is running: `curl http://192.168.0.155:3004/api/health`
   - Check firewall settings
   - Ensure devices are on same network
   - Verify backend URL in AppConfig.swift

2. **WebSocket connection fails**:
   - Check WebSocket URL format (ws:// not http://)
   - Verify WebSocket endpoint is accessible
   - Check for proxy or VPN interference

## Scripts Documentation

### build-and-install.sh
Main build script that handles the complete build and installation process.
- Cleans previous builds
- Builds the app
- Installs on simulator
- Launches the app
- Opens simulator window

### start-backend-server.sh
Starts the backend Node.js server.
- Locates backend directory
- Installs dependencies if needed
- Kills existing process on port 3004
- Starts server in background
- Verifies server is running

### verify-app-connectivity.sh
Tests connectivity between app and backend.
- Checks backend health endpoint
- Verifies WebSocket availability
- Monitors app logs for connection attempts
- Tests API endpoints

### configure-simulator-network.sh
Configures network settings for simulator.
- Tests backend connectivity from host
- Creates configuration files
- Provides network diagnostics

## Build Artifacts

### Build Output Location
```
~/Library/Developer/Xcode/DerivedData/ClaudeCodeUI-*/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app
```

### Logs Location
- Build logs: `./build_output_*.log`
- Backend logs: `/tmp/claudecode_backend_*.log`
- App logs: `/tmp/claudecode_connectivity_*.log`

## Testing the Installation

### Basic Functionality Test
1. Launch the app on simulator
2. Check if login screen appears
3. Verify no crash logs
4. Check network connectivity indicator

### API Connectivity Test
```bash
# From host machine
curl http://192.168.0.155:3004/api/health
curl http://192.168.0.155:3004/api/auth/status
```

### WebSocket Test
```bash
# Test WebSocket upgrade
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==" \
  -H "Sec-WebSocket-Version: 13" \
  http://192.168.0.155:3004/ws
```

## Production Deployment Notes

For production deployment:
1. Change backend URL from local IP to production domain
2. Update from http:// to https:// for SSL
3. Update WebSocket from ws:// to wss://
4. Set appropriate build configuration (Release)
5. Configure proper code signing
6. Update bundle identifier for App Store
7. Set up proper provisioning profiles

## Code Changes Made

No code changes were required. The app was already properly configured with:
- Correct backend URL (192.168.0.155:3004)
- Proper WebSocket configuration
- Appropriate network settings
- Working build configuration

## Verified Components

✅ Xcode project builds successfully
✅ App installs on iPhone 16 Pro simulator
✅ App launches without crashes
✅ Backend URL properly configured
✅ Network configuration scripts created
✅ Build automation scripts functional
✅ Documentation complete

## Next Steps for Testing

1. Start the backend server using the provided script
2. Run connectivity verification
3. Test login functionality
4. Verify WebSocket connection for real-time features
5. Test core app features (projects, sessions, chat)