# Simulator Automation Fixes - Summary

## What Was Fixed

### 1. simulator-automation.sh
✅ **Fixed iOS Version References**
- Changed from "iOS 26.0" to "iOS 18.6" (correct version)
- Updated device name to "iPhone 16 Pro Max" for consistency

✅ **Improved Build Configuration**
- Added `-configuration Debug` flag for consistent builds
- Added `CODE_SIGN_IDENTITY=""` and `CODE_SIGNING_REQUIRED=NO` to prevent signing issues
- Build path now explicitly looks for app at: `/build/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app`

✅ **Log Capture Already Working**
- Log capture was already correctly configured to run in background
- Outputs to timestamped file in `logs/` directory
- Creates symlink to `latest.log` for easy access

### 2. Created MCP Tool Documentation
📄 **simulator-mcp-commands.md**
- Complete reference for using XcodeBuildMCP tools from within Claude
- Shows all available MCP commands with correct parameters
- Includes complete workflow example with proper simulator UUID

### 3. Created Helper Scripts
🐍 **mcp-simulator-helper.py**
- Python script that demonstrates MCP tool usage patterns
- Shows the MCP commands that would be called
- Falls back to xcrun commands for actual execution
- Can be used as a reference or standalone tool

## How to Use

### Option 1: Bash Script (Traditional)
```bash
# Build, install, and launch with logging
./simulator-automation.sh all

# Just build
./simulator-automation.sh build

# Just launch (after build)
./simulator-automation.sh launch

# Just capture logs
./simulator-automation.sh logs
```

### Option 2: From Within Claude (Using MCP Tools)
Use the commands documented in `simulator-mcp-commands.md`. For example:
```javascript
// Boot simulator
await mcp__XcodeBuildMCP__boot_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1"
})

// Build app
await mcp__XcodeBuildMCP__build_sim({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1"
})
```

### Option 3: Python Helper
```bash
# Run complete workflow
python3 mcp-simulator-helper.py all

# Just build
python3 mcp-simulator-helper.py build
```

## Key Configuration
- **Simulator UUID**: `A707456B-44DB-472F-9722-C88153CDFFA1` (iPhone 16 Pro Max, iOS 18.6)
- **Bundle ID**: `com.claudecode.ui`
- **Scheme**: `ClaudeCodeUI`
- **Build Output**: `/Users/nick/Documents/claude-code-ios-ui/build/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app`
- **Logs**: `/Users/nick/Documents/claude-code-ios-ui/logs/latest.log`

## Important Notes
1. Always use the specific simulator UUID, not device names
2. Log capture runs in background and outputs to file (already working correctly)
3. The app path after build is: `build/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app`
4. MCP tools can only be called from within Claude, not from bash scripts
5. The bash script now works correctly with proper paths and configuration