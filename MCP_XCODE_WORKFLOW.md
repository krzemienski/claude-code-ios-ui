# MCP XcodeBuild Workflow with Background-First Logging

## Overview

This document describes the **background-first logging workflow** that prevents app restarts and log size issues when using XcodeBuildMCP tools from Claude. The workflow separates logging from build/launch operations to maintain continuous log streams without interruption.

## Problem Solved

Previously, when using `launch_app_logs_sim` or similar commands, the app would restart and logs would grow excessively large, causing:
- Loss of log context from previous runs
- App restart errors (FBSOpenApplicationServiceErrorDomain)
- Oversized log files that slow down the system
- Interrupted log streams during build operations

## Solution: Background-First Logging

The solution implements a **3-phase workflow**:

1. **Start background logging FIRST** (before any build/launch)
2. **Build/Install without creating new log streams**
3. **Launch app attached to existing logs**

## Quick Start

### From Terminal (Recommended)

```bash
# Complete workflow - logs → build → install → launch
./simulator-automation.sh workflow

# Or use the MCP preparation mode
./simulator-automation.sh mcp-build
```

### From Claude with MCP Tools

```javascript
// CRITICAL: Always use this simulator UUID
const SIMULATOR_UUID = "A707456B-44DB-472F-9722-C88153CDFFA1";

// Step 1: Start background logging via bash FIRST
await Bash({ 
  command: "./simulator-automation.sh mcp-build",
  timeout_ms: 10000
});

// Step 2: Build and run using MCP (single command works best)
await mcp__XcodeBuildMCP__build_run_sim({
  projectPath: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj",
  scheme: "ClaudeCodeUI",
  simulatorId: SIMULATOR_UUID  // ALWAYS use UUID, never name
});

// Step 3: Get UI for testing
const ui = await mcp__XcodeBuildMCP__describe_ui({ 
  simulatorUuid: SIMULATOR_UUID 
});
```

## Architecture

### Background Logging System (`background-logging-system.sh`)

**Key Features:**
- **Log Rotation**: Automatic rotation at 50MB with compression
- **Non-Intrusive Build**: Builds without launching or attaching new streams
- **Process Isolation**: Separate PIDs for log stream, monitor, and build
- **Health Checks**: Verifies logging is active before operations
- **Graceful Recovery**: Handles interruptions and resumes logging

### Simulator Automation (`simulator-automation.sh`)

**Integration Points:**
- Delegates to `background-logging-system.sh` for all operations
- Ensures logging is active before any build/launch
- Provides MCP-friendly commands for Claude integration

## Command Reference

### Background Logging System

```bash
# Start logging only
./background-logging-system.sh start-logs

# Build without restart
./background-logging-system.sh build

# Install without launch
./background-logging-system.sh install

# Launch attached to logs
./background-logging-system.sh launch

# Complete workflow
./background-logging-system.sh workflow

# Check health
./background-logging-system.sh health
```

### Simulator Automation (MCP-Ready)

```bash
# Complete workflow (recommended)
./simulator-automation.sh workflow

# Prepare for MCP builds
./simulator-automation.sh mcp-build

# Individual operations
./simulator-automation.sh logs    # Start background logging
./simulator-automation.sh build   # Build (auto-starts logs if needed)
./simulator-automation.sh install # Install without launch
./simulator-automation.sh launch  # Launch with existing logs

# Management
./simulator-automation.sh status  # Check system status
./simulator-automation.sh stop    # Stop logging
./simulator-automation.sh clean   # Clean all artifacts
```

## MCP Tool Best Practices

### DO ✅

1. **Always start background logging first**
   ```bash
   ./simulator-automation.sh mcp-build
   ```

2. **Use `build_run_sim` for single-command execution**
   ```javascript
   await mcp__XcodeBuildMCP__build_run_sim({...});
   ```

3. **Always use simulator UUID, not name**
   ```javascript
   simulatorId: "A707456B-44DB-472F-9722-C88153CDFFA1"
   ```

4. **Use `describe_ui()` before interactions**
   ```javascript
   const ui = await describe_ui({ simulatorUuid: SIMULATOR_UUID });
   ```

5. **Use `touch()` with down/up, not `tap()`**
   ```javascript
   touch({ simulatorUuid: UUID, x: 100, y: 200, down: true });
   touch({ simulatorUuid: UUID, x: 100, y: 200, up: true });
   ```

### DON'T ❌

1. **Don't use `launch_app_logs_sim`** - Causes app restart
2. **Don't use separate install + launch** - May trigger errors
3. **Don't start logs after build** - Misses critical events
4. **Don't use simulator names** - Always use UUID
5. **Don't guess coordinates** - Always use describe_ui first

## Log File Locations

```
logs/
├── runtime/           # App runtime logs
│   ├── latest.log    # Symlink to current log
│   └── app_*.log     # Timestamped logs
├── build/            # Build process logs
│   ├── latest.log    # Symlink to current build log
│   └── build_*.log   # Timestamped build logs
├── archived/         # Rotated and compressed logs
│   └── *.log.gz      # Compressed old logs
└── .pids/            # Process ID files
    ├── log_stream.pid
    ├── log_monitor.pid
    └── build.pid
```

## Troubleshooting

### Issue: App won't launch
**Solution**: Ensure background logging is active first
```bash
./simulator-automation.sh status
./simulator-automation.sh logs  # If not active
```

### Issue: Logs not appearing
**Solution**: Check log file locations
```bash
tail -f logs/runtime/latest.log
```

### Issue: Build fails
**Solution**: Check build logs
```bash
cat logs/build/latest.log
```

### Issue: Log files too large
**Solution**: Automatic rotation handles this at 50MB. To force rotation:
```bash
./background-logging-system.sh clean
./background-logging-system.sh start-logs
```

### Issue: MCP build command not working
**Solution**: Ensure script is executable
```bash
chmod +x simulator-automation.sh
chmod +x background-logging-system.sh
```

## Environment Variables

```bash
# Enable debug output
DEBUG=1 ./simulator-automation.sh workflow

# Customize log rotation (MB)
MAX_LOG_SIZE_MB=100 ./background-logging-system.sh workflow

# Keep more rotated logs
MAX_LOG_FILES=20 ./background-logging-system.sh workflow
```

## Integration with CI/CD

```bash
#!/bin/bash
# ci-test.sh

# Start background logging
./simulator-automation.sh mcp-build

# Run tests with MCP tools or xcodebuild
xcodebuild test \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination "id=A707456B-44DB-472F-9722-C88153CDFFA1" \
  -quiet

# Collect logs
cp logs/runtime/latest.log artifacts/
cp logs/build/latest.log artifacts/

# Clean up
./simulator-automation.sh stop
```

## Key Benefits

1. **No App Restarts**: Continuous logging across build/launch cycles
2. **Log Size Control**: Automatic rotation prevents oversized logs
3. **MCP Compatibility**: Works seamlessly with XcodeBuildMCP tools
4. **Process Isolation**: Build doesn't interfere with logging
5. **Debugging Support**: Separate runtime and build logs
6. **Health Monitoring**: Built-in health checks and status reporting
7. **Graceful Recovery**: Handles interruptions without data loss

## Summary

The background-first logging workflow ensures reliable, continuous logging for iOS development and testing. By starting logs before any build/launch operations and using non-intrusive build processes, we eliminate app restarts and log size issues that previously plagued the development workflow.

**Remember the golden rule**: Always start background logging FIRST, then build/launch!