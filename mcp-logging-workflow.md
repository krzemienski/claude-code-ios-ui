# MCP-Based iOS Development Workflow with Background Logging

This workflow combines background-first logging with XcodeBuildMCP tools to prevent app restarts and oversized logs while maintaining full visibility into the build and runtime processes.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Claude (MCP Tools)                       │
├─────────────────────────────────────────────────────────────┤
│  1. Start Background Logging (via Bash tool)                 │
│  2. XcodeBuildMCP Build (non-intrusive)                     │
│  3. XcodeBuildMCP Install                                   │
│  4. XcodeBuildMCP Launch (without logs)                     │
│  5. Monitor & Rotate Logs (via Bash tool)                   │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Constants

```javascript
const SIMULATOR_UUID = "A707456B-44DB-472F-9722-C88153CDFFA1";
const BUNDLE_ID = "com.claudecode.ui";
const PROJECT_PATH = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj";
const SCHEME = "ClaudeCodeUI";
const BUILD_PATH = "/Users/nick/Documents/claude-code-ios-ui/build";
const LOG_DIR = "/Users/nick/Documents/claude-code-ios-ui/logs";
const LOG_SCRIPT = "/Users/nick/Documents/claude-code-ios-ui/background-logging-system.sh";
```

## Phase 1: Start Background Logging (BEFORE Build)

### Step 1.1: Initialize Logging System
```javascript
// Start background logging FIRST to capture all events
await mcp__desktop-commander__start_process({
  command: `${LOG_SCRIPT} start-logs`,
  timeout_ms: 5000
});
```

### Step 1.2: Verify Logging is Active
```javascript
// Check that logging process is running
const logStatus = await mcp__desktop-commander__start_process({
  command: `${LOG_SCRIPT} status`,
  timeout_ms: 2000
});
// Expected: "Logging is ACTIVE (PID: xxxxx)"
```

### Step 1.3: Get Log File Path
```javascript
// Get the current log file for monitoring
const logFile = await mcp__desktop-commander__start_process({
  command: `ls -t ${LOG_DIR}/*.log | head -1`,
  timeout_ms: 1000
});
```

## Phase 2: Build Application (Non-Intrusive)

### Step 2.1: Boot Simulator
```javascript
// Boot the simulator if needed
await mcp__XcodeBuildMCP__boot_sim({
  simulatorUuid: SIMULATOR_UUID
});
```

### Step 2.2: Open Simulator Window
```javascript
// Make simulator visible
await mcp__XcodeBuildMCP__open_sim();
```

### Step 2.3: Build with Minimal Interference
```javascript
// Build WITHOUT clean to avoid disrupting running processes
await mcp__XcodeBuildMCP__build_sim({
  projectPath: PROJECT_PATH,
  scheme: SCHEME,
  simulatorId: SIMULATOR_UUID,
  configuration: "Debug",
  derivedDataPath: BUILD_PATH,
  extraArgs: [
    "-quiet",                    // Minimal output
    "-hideShellScriptEnvironment", // Reduce log noise
    "-parallelizeTargets",       // Faster build
    "-skipPackagePluginValidation", // Skip unnecessary validation
    "CODE_SIGN_IDENTITY=\"\"",   // No signing delays
    "CODE_SIGNING_REQUIRED=NO",  // No signing delays
    "COMPILER_INDEX_STORE_ENABLE=NO", // Faster compilation
    "SWIFT_COMPILATION_MODE=singlefile" // Faster Swift compilation
  ]
});
```

## Phase 3: Install and Launch (WITHOUT Built-in Logging)

### Step 3.1: Get App Path
```javascript
const appPath = await mcp__XcodeBuildMCP__get_sim_app_path({
  projectPath: PROJECT_PATH,
  scheme: SCHEME,
  platform: "iOS Simulator",
  simulatorId: SIMULATOR_UUID,
  configuration: "Debug"
});
```

### Step 3.2: Install Application
```javascript
// Install without launching
await mcp__XcodeBuildMCP__install_app_sim({
  simulatorUuid: SIMULATOR_UUID,
  appPath: appPath
});
```

### Step 3.3: Launch WITHOUT Log Capture
```javascript
// Use launch_app_sim NOT launch_app_logs_sim to avoid restart
await mcp__XcodeBuildMCP__launch_app_sim({
  simulatorUuid: SIMULATOR_UUID,
  bundleId: BUNDLE_ID
});
// Critical: Do NOT use launch_app_logs_sim as it restarts the app
```

## Phase 4: Monitor and Manage Logs

### Step 4.1: Monitor Log Size
```javascript
// Check log size periodically
const checkLogSize = async () => {
  const size = await mcp__desktop-commander__start_process({
    command: `${LOG_SCRIPT} check-size`,
    timeout_ms: 1000
  });
  // Returns: "Log size: XX MB (Y% of limit)"
  return size;
};
```

### Step 4.2: Rotate Logs if Needed
```javascript
// Rotate logs when approaching size limit
const rotateLogs = async () => {
  await mcp__desktop-commander__start_process({
    command: `${LOG_SCRIPT} rotate-if-needed`,
    timeout_ms: 3000
  });
};
```

### Step 4.3: View Recent Logs
```javascript
// Get last N lines of logs without loading entire file
const getRecentLogs = async (lines = 100) => {
  const logs = await mcp__desktop-commander__start_process({
    command: `tail -n ${lines} $(ls -t ${LOG_DIR}/*.log | head -1)`,
    timeout_ms: 2000
  });
  return logs;
};
```

### Step 4.4: Search Logs
```javascript
// Search for specific patterns efficiently
const searchLogs = async (pattern) => {
  const results = await mcp__desktop-commander__start_process({
    command: `grep -n "${pattern}" $(ls -t ${LOG_DIR}/*.log | head -1) | tail -50`,
    timeout_ms: 3000
  });
  return results;
};
```

## Phase 5: Testing and Interaction

### Step 5.1: UI Automation (While Logging Continues)
```javascript
// Describe UI for interaction
const ui = await mcp__XcodeBuildMCP__describe_ui({
  simulatorUuid: SIMULATOR_UUID
});

// Interact with UI elements
await mcp__XcodeBuildMCP__touch({
  simulatorUuid: SIMULATOR_UUID,
  x: 100,
  y: 200,
  down: true
});
await mcp__XcodeBuildMCP__touch({
  simulatorUuid: SIMULATOR_UUID,
  x: 100,
  y: 200,
  up: true
});
```

### Step 5.2: Take Screenshots
```javascript
// Capture visual state
await mcp__XcodeBuildMCP__screenshot({
  simulatorUuid: SIMULATOR_UUID,
  output_path: "~/Downloads/test-screenshot.png",
  type: "png"
});
```

## Phase 6: Cleanup

### Step 6.1: Stop Application
```javascript
// Stop the app when done
await mcp__XcodeBuildMCP__stop_app_sim({
  simulatorUuid: SIMULATOR_UUID,
  bundleId: BUNDLE_ID
});
```

### Step 6.2: Stop Logging
```javascript
// Stop background logging
await mcp__desktop-commander__start_process({
  command: `${LOG_SCRIPT} stop-logs`,
  timeout_ms: 3000
});
```

### Step 6.3: Archive Logs
```javascript
// Archive logs for later analysis
await mcp__desktop-commander__start_process({
  command: `${LOG_SCRIPT} archive`,
  timeout_ms: 5000
});
```

## Complete Workflow Example

```javascript
// Complete automated workflow with error handling
async function runCompleteWorkflow() {
  try {
    console.log("🚀 Starting iOS development workflow...");
    
    // Phase 1: Start logging FIRST
    console.log("📝 Starting background logging...");
    await mcp__desktop-commander__start_process({
      command: `${LOG_SCRIPT} start-logs`,
      timeout_ms: 5000
    });
    
    // Verify logging is active
    const logStatus = await mcp__desktop-commander__start_process({
      command: `${LOG_SCRIPT} status`,
      timeout_ms: 2000
    });
    console.log(`✅ ${logStatus}`);
    
    // Phase 2: Build
    console.log("🔨 Building application...");
    await mcp__XcodeBuildMCP__boot_sim({ simulatorUuid: SIMULATOR_UUID });
    await mcp__XcodeBuildMCP__open_sim();
    
    await mcp__XcodeBuildMCP__build_sim({
      projectPath: PROJECT_PATH,
      scheme: SCHEME,
      simulatorId: SIMULATOR_UUID,
      configuration: "Debug",
      derivedDataPath: BUILD_PATH,
      extraArgs: ["-quiet", "-parallelizeTargets"]
    });
    
    // Phase 3: Install and Launch
    console.log("📱 Installing and launching app...");
    const appPath = await mcp__XcodeBuildMCP__get_sim_app_path({
      projectPath: PROJECT_PATH,
      scheme: SCHEME,
      platform: "iOS Simulator",
      simulatorId: SIMULATOR_UUID
    });
    
    await mcp__XcodeBuildMCP__install_app_sim({
      simulatorUuid: SIMULATOR_UUID,
      appPath: appPath
    });
    
    // Critical: Use launch_app_sim NOT launch_app_logs_sim
    await mcp__XcodeBuildMCP__launch_app_sim({
      simulatorUuid: SIMULATOR_UUID,
      bundleId: BUNDLE_ID
    });
    
    console.log("✅ App launched successfully!");
    
    // Phase 4: Monitor logs
    console.log("📊 Monitoring logs...");
    const logSize = await mcp__desktop-commander__start_process({
      command: `${LOG_SCRIPT} check-size`,
      timeout_ms: 1000
    });
    console.log(`📈 ${logSize}`);
    
    // Get recent logs for verification
    const recentLogs = await mcp__desktop-commander__start_process({
      command: `tail -20 $(ls -t ${LOG_DIR}/*.log | head -1)`,
      timeout_ms: 2000
    });
    console.log("📜 Recent logs:", recentLogs);
    
    return { success: true, logFile: `${LOG_DIR}/$(ls -t ${LOG_DIR}/*.log | head -1)` };
    
  } catch (error) {
    console.error("❌ Workflow failed:", error);
    
    // Cleanup on error
    await mcp__desktop-commander__start_process({
      command: `${LOG_SCRIPT} stop-logs`,
      timeout_ms: 3000
    });
    
    throw error;
  }
}

// Run the workflow
await runCompleteWorkflow();
```

## Key Benefits

### 1. No App Restarts
- Background logging starts BEFORE build
- App launch doesn't restart for log capture
- Continuous log stream without interruption

### 2. Controlled Log Size
- Automatic rotation at 50MB
- Old logs archived automatically
- Prevents disk space issues

### 3. Non-Intrusive Build
- Quiet build mode reduces log noise
- Parallel compilation for speed
- No clean build to avoid app termination

### 4. Efficient Log Access
- Tail for recent logs without loading entire file
- Grep for searching without memory overload
- Structured JSON format for parsing

### 5. Complete Visibility
- All build events captured
- Runtime logs preserved
- Error tracking maintained

## Troubleshooting

### Issue: Logs Not Appearing
```javascript
// Check if logging process is running
const status = await mcp__desktop-commander__start_process({
  command: `${LOG_SCRIPT} status`,
  timeout_ms: 2000
});
```

### Issue: Build Fails
```javascript
// Use verbose mode for debugging
await mcp__XcodeBuildMCP__build_sim({
  projectPath: PROJECT_PATH,
  scheme: SCHEME,
  simulatorId: SIMULATOR_UUID,
  extraArgs: ["-verbose"] // Remove -quiet for debugging
});
```

### Issue: App Won't Launch
```javascript
// Check if app is installed
const installed = await mcp__desktop-commander__start_process({
  command: `xcrun simctl get_app_container ${SIMULATOR_UUID} ${BUNDLE_ID}`,
  timeout_ms: 2000
});
```

### Issue: Log File Too Large
```javascript
// Force rotation
await mcp__desktop-commander__start_process({
  command: `${LOG_SCRIPT} rotate`,
  timeout_ms: 3000
});
```

## Best Practices

1. **Always Start Logging First**: Before any build or launch operations
2. **Use Non-Intrusive Build Flags**: Minimize disruption to running processes
3. **Monitor Log Sizes**: Check periodically and rotate as needed
4. **Use Tail/Grep for Log Access**: Don't load entire log files into memory
5. **Clean Shutdown**: Always stop logging properly to avoid zombie processes
6. **Archive Important Logs**: Before starting new test sessions

## Integration with Testing

This workflow integrates seamlessly with testing frameworks:

```javascript
// Example: Run UI tests with continuous logging
async function runUITests() {
  // Start logging
  await mcp__desktop-commander__start_process({
    command: `${LOG_SCRIPT} start-logs`,
    timeout_ms: 5000
  });
  
  // Run tests (logs continue in background)
  await mcp__XcodeBuildMCP__test_sim({
    projectPath: PROJECT_PATH,
    scheme: SCHEME,
    simulatorId: SIMULATOR_UUID
  });
  
  // Logs captured throughout test execution
  const testLogs = await mcp__desktop-commander__start_process({
    command: `grep -i "test" $(ls -t ${LOG_DIR}/*.log | head -1)`,
    timeout_ms: 3000
  });
  
  return testLogs;
}
```

## Summary

This MCP workflow provides:
- ✅ Background-first logging that doesn't restart apps
- ✅ Size-controlled logs with automatic rotation
- ✅ Non-intrusive build process
- ✅ Full integration with XcodeBuildMCP tools
- ✅ Efficient log access without memory issues
- ✅ Complete visibility into build and runtime

The key insight is separating log capture from app launch, using `launch_app_sim` instead of `launch_app_logs_sim`, and managing logs through an independent background process.