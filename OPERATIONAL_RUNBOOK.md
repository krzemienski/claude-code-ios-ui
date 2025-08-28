# iOS Claude Code UI - Operational Runbook

## Overview
This runbook provides step-by-step procedures for building, testing, and debugging the iOS Claude Code UI app using XcodeBuildMCP tools with background-first logging to prevent app restarts and oversized log files.

## Critical Configuration
- **Simulator UUID**: `A707456B-44DB-472F-9722-C88153CDFFA1` (iPhone 16 Pro Max, iOS 18.6)
- **Bundle ID**: `com.claudecode.ui`
- **Backend Server**: `http://192.168.0.43:3004` (for iOS simulator)
- **WebSocket**: `ws://192.168.0.43:3004/ws` (chat), `ws://192.168.0.43:3004/shell` (terminal)

## Prerequisites Checklist
- [ ] Backend server running on port 3004
- [ ] Xcode installed and configured
- [ ] Simulator UUID A707456B-44DB-472F-9722-C88153CDFFA1 available
- [ ] Project cloned and up to date
- [ ] MCP tools accessible from Claude

## Workflow 1: Background-First Development Cycle

### Phase 1: Start Background Logging (ALWAYS FIRST)
```bash
# 1. Make script executable (first time only)
chmod +x /Users/nick/Documents/claude-code-ios-ui/background-logging-system.sh

# 2. Start background logging
./background-logging-system.sh start-logs

# 3. Verify logging is active
./background-logging-system.sh status
# Expected: "Logging is ACTIVE (PID: xxxxx)"

# 4. Note the log file path
ls -t logs/runtime/*.log | head -1
```

### Phase 2: Build and Install App (From Claude)
```javascript
// 1. Boot simulator if needed
await mcp__XcodeBuildMCP__boot_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1"
});

// 2. Open simulator window
await mcp__XcodeBuildMCP__open_sim();

// 3. Build app with minimal interference
await mcp__XcodeBuildMCP__build_sim({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1",
  configuration: "Debug",
  derivedDataPath: "/Users/nick/Documents/claude-code-ios-ui/build",
  extraArgs: ["-quiet", "-parallelizeTargets", "CODE_SIGN_IDENTITY=\"\"", "CODE_SIGNING_REQUIRED=NO"]
});

// 4. Get app path
const appPath = await mcp__XcodeBuildMCP__get_sim_app_path({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  platform: "iOS Simulator",
  simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1"
});

// 5. Install app
await mcp__XcodeBuildMCP__install_app_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  appPath: appPath
});
```

### Phase 3: Launch App (WITHOUT Log Restart)
```javascript
// CRITICAL: Use launch_app_sim NOT launch_app_logs_sim
await mcp__XcodeBuildMCP__launch_app_sim({
  simulatorUuid: "A707456B-44DB-472F-9722-C88153CDFFA1",
  bundleId: "com.claudecode.ui"
});
```

### Phase 4: Monitor Logs (Background Process)
```bash
# View recent logs without loading entire file
tail -100 $(ls -t logs/runtime/*.log | head -1)

# Search for errors
grep -i error $(ls -t logs/runtime/*.log | head -1) | tail -20

# Monitor log size
./background-logging-system.sh check-size

# Rotate if needed
./background-logging-system.sh rotate-if-needed
```

## Workflow 2: Debugging Common Issues

### Issue: App Won't Launch (FBSOpenApplicationServiceErrorDomain)
```bash
# 1. Check if app is installed
xcrun simctl get_app_container A707456B-44DB-472F-9722-C88153CDFFA1 com.claudecode.ui

# 2. Uninstall and reinstall
xcrun simctl uninstall A707456B-44DB-472F-9722-C88153CDFFA1 com.claudecode.ui

# 3. Clean build and retry
rm -rf /Users/nick/Documents/claude-code-ios-ui/build

# 4. Rebuild with MCP tools (see Phase 2)
```

### Issue: Logging Process Dies
```bash
# 1. Stop all logging
./background-logging-system.sh stop-logs

# 2. Check for zombie processes
ps aux | grep -E "simctl|log" | grep -v grep

# 3. Kill any orphaned processes
pkill -f "simctl spawn.*log stream"

# 4. Restart logging
./background-logging-system.sh start-logs
```

### Issue: Build Fails
```javascript
// Use verbose mode for debugging
await mcp__XcodeBuildMCP__build_sim({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1",
  extraArgs: ["-verbose"] // Remove -quiet for debugging
});
```

### Issue: Oversized Logs
```bash
# 1. Force rotation
./background-logging-system.sh rotate

# 2. Archive old logs
./background-logging-system.sh archive

# 3. Clear old archives if needed
rm -rf logs/archive/*.tar.gz
```

## Workflow 3: Testing Procedures

### UI Testing with Background Logging
```javascript
// 1. Ensure logging is active
const logStatus = await mcp__desktop-commander__start_process({
  command: "./background-logging-system.sh status",
  timeout_ms: 2000
});

// 2. Run UI tests
await mcp__XcodeBuildMCP__test_sim({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1"
});

// 3. Get test logs
const testLogs = await mcp__desktop-commander__start_process({
  command: "grep -i test $(ls -t logs/runtime/*.log | head -1) | tail -50",
  timeout_ms: 3000
});
```

### WebSocket Testing
```bash
# 1. Check backend is running
curl -I http://192.168.0.43:3004/api/health

# 2. Monitor WebSocket messages in logs
grep -i websocket $(ls -t logs/runtime/*.log | head -1) | tail -f

# 3. Test specific message flow
grep -E "claude-command|assistant-response" $(ls -t logs/runtime/*.log | head -1)
```

## Workflow 4: Production Deployment Preparation

### Pre-Deployment Checklist
- [ ] All tests passing
- [ ] No memory leaks (< 150MB baseline)
- [ ] WebSocket reconnection working
- [ ] Launch time < 2 seconds
- [ ] No critical errors in logs
- [ ] Backend API fully integrated

### Archive Build for TestFlight
```javascript
// 1. Clean build folder
await mcp__XcodeBuildMCP__clean({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  platform: "iOS"
});

// 2. Build for device
await mcp__XcodeBuildMCP__build_device({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  configuration: "Release"
});
```

## Key Insights and Best Practices

### DO's
1. **ALWAYS start logging BEFORE build/launch**
2. **Use launch_app_sim (NOT launch_app_logs_sim)**
3. **Use tail/grep for log access (not full file reads)**
4. **Monitor log sizes and rotate proactively**
5. **Use -quiet flag for builds to reduce noise**
6. **Check simulator is booted before operations**
7. **Use specific UUID, never simulator names**

### DON'Ts
1. **Never use launch_app_logs_sim (causes restart)**
2. **Never load entire log files into memory**
3. **Never use clean build unless necessary**
4. **Never skip logging setup**
5. **Never ignore log rotation warnings**
6. **Never use relative paths in scripts**
7. **Never call MCP tools from bash scripts**

## Emergency Procedures

### Complete Reset
```bash
# 1. Stop everything
./background-logging-system.sh stop-logs
xcrun simctl shutdown all

# 2. Clean everything
rm -rf ~/Library/Developer/Xcode/DerivedData/ClaudeCodeUI-*
rm -rf /Users/nick/Documents/claude-code-ios-ui/build
rm -rf /Users/nick/Documents/claude-code-ios-ui/logs/runtime/*

# 3. Reset simulator
xcrun simctl erase A707456B-44DB-472F-9722-C88153CDFFA1

# 4. Start fresh
./background-logging-system.sh start-logs
# Then rebuild and install from Claude
```

### Log Recovery
```bash
# If logs are corrupted or oversized
# 1. Stop logging
./background-logging-system.sh stop-logs

# 2. Move corrupted logs
mv logs/runtime/*.log logs/archive/corrupted_$(date +%Y%m%d_%H%M%S).log

# 3. Restart fresh
./background-logging-system.sh start-logs
```

## Monitoring Commands

### Health Check Script
```bash
#!/bin/bash
# health-check.sh
echo "=== System Health Check ==="
echo "1. Backend Status:"
curl -s http://192.168.0.43:3004/api/health || echo "Backend DOWN"

echo "2. Simulator Status:"
xcrun simctl list devices | grep A707456B-44DB-472F-9722-C88153CDFFA1

echo "3. Logging Status:"
./background-logging-system.sh status

echo "4. App Installation:"
xcrun simctl get_app_container A707456B-44DB-472F-9722-C88153CDFFA1 com.claudecode.ui 2>&1

echo "5. Log Size:"
./background-logging-system.sh check-size

echo "6. Recent Errors:"
grep -i error $(ls -t logs/runtime/*.log | head -1) | tail -5
```

## Support and Troubleshooting

### Log Locations
- Runtime logs: `logs/runtime/app_*.log`
- Archived logs: `logs/archive/*.tar.gz`
- Process PIDs: `logs/pids/`
- Latest log symlink: `logs/runtime/latest.log`

### Key Files
- Logging script: `background-logging-system.sh`
- MCP workflow: `mcp-logging-workflow.md`
- Simulator automation: `simulator-automation.sh`
- This runbook: `OPERATIONAL_RUNBOOK.md`

### Contact Points
- GitHub Issues: https://github.com/anthropics/claude-code/issues
- Backend logs: Check terminal running `npm start`
- Xcode console: View → Debug Area → Console

## Version History
- v1.0 - Initial runbook with background-first logging
- Created: January 28, 2025
- Last Updated: January 28, 2025

---

*This runbook is maintained as part of the iOS Claude Code UI project. Always use the latest version from the repository.*