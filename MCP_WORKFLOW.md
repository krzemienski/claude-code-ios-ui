# MCP-Based iOS Simulator Workflow

This document contains the complete MCP (Model Context Protocol) workflow that replaces the traditional bash script automation. These commands must be run from within Claude, as MCP tools cannot be invoked from bash scripts.

## Configuration
- **Simulator UUID**: `A707456B-44DB-472F-9722-C88153CDFFA1` (iPhone 16 Pro Max, iOS 18.6)
- **Bundle ID**: `com.claudecode.ui`
- **Project Path**: `/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj`
- **Scheme**: `ClaudeCodeUI`
- **Build Path**: `/Users/nick/Documents/claude-code-ios-ui/build`

## Complete Workflow (Run These Commands in Claude)

### Step 1: Check Simulator Status
```javascript
await mcp__XcodeBuildMCP__list_sims({ enabled: true })
// Verify simulator A707456B-44DB-472F-9722-C88153CDFFA1 is available
```

### Step 2: Boot Simulator (if needed)
```javascript
await mcp__XcodeBuildMCP__boot_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1"
})
```

### Step 3: Open Simulator Window
```javascript
await mcp__XcodeBuildMCP__open_sim()
```

### Step 4: Build the App
```javascript
await mcp__XcodeBuildMCP__build_sim({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1",
  configuration: "Debug",
  derivedDataPath: "/Users/nick/Documents/claude-code-ios-ui/build"
})
```

### Step 5: Get App Path
```javascript
const appPath = await mcp__XcodeBuildMCP__get_sim_app_path({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  platform: "iOS Simulator",
  simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1",
  configuration: "Debug"
})
// Result: /Users/nick/Library/Developer/Xcode/DerivedData/ClaudeCodeUI-gtfztaptdxmysxhixsskktgxefom/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app
```

### Step 6: Get Bundle ID (optional, we know it's com.claudecode.ui)
```javascript
const bundleId = await mcp__XcodeBuildMCP__get_app_bundle_id({
  appPath: appPath
})
// Result: com.claudecode.ui
```

### Step 7: Install the App
```javascript
await mcp__XcodeBuildMCP__install_app_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  appPath: appPath
})
```

### Step 8: Launch App with Log Capture
```javascript
const logSession = await mcp__XcodeBuildMCP__launch_app_logs_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  bundleId: "com.claudecode.ui"
})
// Save the logSessionId for later retrieval
```

### Step 9: Stop and Retrieve Logs
```javascript
const logs = await mcp__XcodeBuildMCP__stop_sim_log_cap({
  logSessionId: logSession.id
})
```

## Alternative: Quick Launch (if app already built)
```javascript
// Just launch with logs
await mcp__XcodeBuildMCP__launch_app_logs_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  bundleId: "com.claudecode.ui"
})
```

## UI Automation Commands

### Take Screenshot
```javascript
await mcp__XcodeBuildMCP__screenshot({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  output_path: "~/Downloads/app-screenshot.png",
  type: "png"
})
```

### Describe UI Elements
```javascript
const uiElements = await mcp__XcodeBuildMCP__describe_ui({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1"
})
```

### Touch Interaction
```javascript
// First describe UI to get coordinates
const ui = await mcp__XcodeBuildMCP__describe_ui({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1"
})

// Then use touch with down/up events
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

## Testing Commands

### Run Tests
```javascript
await mcp__XcodeBuildMCP__test_sim({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1",
  configuration: "Debug",
  derivedDataPath: "/Users/nick/Documents/claude-code-ios-ui/build"
})
```

## Important Notes

1. **MCP tools can only be called from within Claude**, not from bash scripts or external programs
2. Always use the specific simulator UUID (`A707456B-44DB-472F-9722-C88153CDFFA1`), not device names
3. The MCP tools handle simulator booting automatically if needed
4. For UI automation, always call `describe_ui()` first to get exact coordinates
5. Use `touch()` with down/up events instead of `tap()` for more reliable interaction
6. Log capture is built into `launch_app_logs_sim()` - no need for separate log setup

## Fallback: Traditional Bash Script

If you need to run automation outside of Claude, use the traditional bash script:
```bash
./simulator-automation.sh all  # Build, install, launch with file-based logging
```

The bash script uses `xcrun simctl` and `xcodebuild` commands directly, which work outside of Claude but don't have the advanced features of MCP tools.