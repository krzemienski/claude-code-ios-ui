# Claude CLI Integration - ClaudeCodeUI

## Overview
The backend integrates with Claude CLI by spawning child processes and communicating via streaming JSON format.

## Key Integration Points

### Process Spawning
- Uses Node.js `child_process.spawn()` to run `claude` command
- Tracks active processes in a Map by session ID
- Supports process abortion/cancellation

### Command Arguments
The Claude CLI is invoked with various flags:
```bash
claude --print "<user_command>" \
       --output-format stream-json \
       --verbose \
       [--resume <session_id>] \
       [--mcp-config <path>] \
       [--tools-mode <mode>]
```

### Key Features

#### 1. Streaming JSON Output
- Claude outputs responses in streaming JSON format
- Each line is a JSON object containing response chunks
- Parsed in real-time and forwarded to WebSocket clients

#### 2. Session Management
- Sessions can be created, resumed, and aborted
- Session IDs are tracked throughout the process lifecycle
- Session files stored as JSONL in project directories

#### 3. Image Support
- Images are saved to temporary files in project directory
- File paths are included in the command sent to Claude
- Temporary files cleaned up after processing

#### 4. Tool Permissions
- Supports allowed/disallowed tools configuration
- Permission modes: allow_all, deny_all, ask
- Skip permissions flag for automated workflows

#### 5. MCP (Model Context Protocol) Support
- Checks for MCP configuration in ~/.claude.json
- Conditionally adds MCP flags if servers are configured
- Supports multiple MCP config paths

### Process Lifecycle
1. **Spawn**: Create new claude process with appropriate flags
2. **Stream**: Parse streaming JSON output and forward to client
3. **Track**: Monitor session ID and process state
4. **Cleanup**: Kill process on disconnect, clean temp files
5. **Abort**: Support graceful process termination

### Working Directory
- Uses actual project directory as CWD, not Claude's metadata directory
- Ensures Claude has proper file system context
- Supports both absolute and relative path operations

### Error Handling
- Process spawn errors caught and reported
- Streaming parse errors handled gracefully
- Process exit codes tracked and reported
- Cleanup ensures no orphaned processes

### Environment Variables
- Inherits parent process environment
- Can override PATH and other variables as needed
- Supports custom shell configurations

## iOS Implementation Considerations
For the iOS app, we'll need to:
1. Implement WebSocket client for streaming JSON
2. Parse Claude's streaming response format
3. Handle session lifecycle (create, resume, abort)
4. Manage image attachments via base64 encoding
5. Implement proper error handling and recovery
6. Support connection state management and reconnection