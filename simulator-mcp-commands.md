# XcodeBuildMCP Commands for iOS Simulator Automation

This document shows how to use XcodeBuildMCP tools from within Claude to build, test, and run the ClaudeCodeUI iOS app.

## Configuration
- **Simulator UUID**: A707456B-44DB-472F-9722-C88153CDFFA1 (iPhone 16 Pro Max, iOS 18.6)
- **Bundle ID**: com.claudecode.ui
- **Project Path**: /Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj
- **Scheme**: ClaudeCodeUI

## MCP Tool Commands

### 1. Boot Simulator
```javascript
await mcp__XcodeBuildMCP__boot_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1"
})
```

### 2. Open Simulator Window
```javascript
await mcp__XcodeBuildMCP__open_sim()
```

### 3. Build App for Simulator
```javascript
await mcp__XcodeBuildMCP__build_sim({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1",
  configuration: "Debug",
  derivedDataPath: "/Users/nick/Documents/claude-code-ios-ui/build"
})
```

### 4. Get App Path After Build
```javascript
const appPath = await mcp__XcodeBuildMCP__get_sim_app_path({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  platform: "iOS Simulator",
  simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1",
  configuration: "Debug"
})
```

### 5. Install App on Simulator
```javascript
await mcp__XcodeBuildMCP__install_app_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  appPath: appPath  // Use the path from step 4
})
```

### 6. Launch App
```javascript
await mcp__XcodeBuildMCP__launch_app_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  bundleId: "com.claudecode.ui"
})
```

### 7. Stop App (if needed)
```javascript
await mcp__XcodeBuildMCP__stop_app_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  bundleId: "com.claudecode.ui"
})
```

### 8. Run Tests
```javascript
await mcp__XcodeBuildMCP__test_sim({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1",
  configuration: "Debug",
  derivedDataPath: "/Users/nick/Documents/claude-code-ios-ui/build"
})
```

### 9. Take Screenshot
```javascript
await mcp__XcodeBuildMCP__screenshot({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  output_path: "~/Downloads/app-screenshot.png",
  type: "png"
})
```

### 10. UI Automation - Describe UI
```javascript
const uiElements = await mcp__XcodeBuildMCP__describe_ui({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1"
})
```

### 11. UI Automation - Touch
```javascript
// Always use describe_ui first to get exact coordinates
// Then use touch with down/up events (NOT tap)
await mcp__XcodeBuildMCP__touch({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  x: 100,
  y: 200,
  down: true
})

await mcp__XcodeBuildMCP__touch({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  x: 100,
  y: 200,
  up: true
})
```

## Complete Workflow Example

```javascript
// Complete build and run workflow
const SIMULATOR_UUID = "A707456B-44DB-472F-9722-C88153CDFFA1";
const PROJECT_PATH = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj";
const SCHEME = "ClaudeCodeUI";
const BUNDLE_ID = "com.claudecode.ui";

// 1. Boot and open simulator
await mcp__XcodeBuildMCP__boot_sim({ simulatorUuid: SIMULATOR_UUID });
await mcp__XcodeBuildMCP__open_sim();

// 2. Build app
await mcp__XcodeBuildMCP__build_sim({
  projectPath: PROJECT_PATH,
  scheme: SCHEME,
  simulatorId: SIMULATOR_UUID,
  configuration: "Debug",
  derivedDataPath: "/Users/nick/Documents/claude-code-ios-ui/build"
});

// 3. Get app path
const appPath = await mcp__XcodeBuildMCP__get_sim_app_path({
  projectPath: PROJECT_PATH,
  scheme: SCHEME,
  platform: "iOS Simulator",
  simulatorId: SIMULATOR_UUID,
  configuration: "Debug"
});

// 4. Install and launch
await mcp__XcodeBuildMCP__install_app_sim({
  simulatorUuid: SIMULATOR_UUID,
  appPath: appPath
});

await mcp__XcodeBuildMCP__launch_app_sim({
  simulatorUuid: SIMULATOR_UUID,
  bundleId: BUNDLE_ID
});

// 5. Take screenshot for verification
await mcp__XcodeBuildMCP__screenshot({
  simulatorUuid: SIMULATOR_UUID,
  output_path: "~/Downloads/app-launched.png",
  type: "png"
});
```

## Log Capture

For log capture, you should still use the bash script's log capture mechanism as it runs in the background:

```bash
# Start log capture in background before launching app
xcrun simctl spawn A707456B-44DB-472F-9722-C88153CDFFA1 log stream \
    --level=debug \
    --style=syslog \
    --predicate 'processImagePath CONTAINS "ClaudeCode"' \
    > logs/simulator_$(date +%Y%m%d_%H%M%S).log 2>&1 &
```

Or use the bash script:
```bash
./simulator-automation.sh logs  # Just start logs
./simulator-automation.sh all   # Build, install, launch with logging
```

## Notes

- Always use the specific simulator UUID (A707456B-44DB-472F-9722-C88153CDFFA1) rather than simulator names
- The MCP tools handle simulator booting automatically if needed
- For UI automation, always call describe_ui() first to get exact coordinates
- Use touch() with down/up events instead of tap() for more reliable interaction
- Log capture should be started before launching the app to capture all output