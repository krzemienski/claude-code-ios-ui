# WebSocket Message Types - ClaudeCodeUI

## Overview
The ClaudeCodeUI uses WebSocket for real-time bidirectional communication between the web client and server. The server runs on port 3001 by default.

## WebSocket Endpoints
- Chat: `/ws/chat` - Main chat interface with Claude
- Shell: `/ws/shell` - Terminal interface for project interaction

## Message Types

### Client → Server Messages

#### Chat WebSocket
```javascript
// Start Claude command
{
  type: 'claude-command',
  command: string,          // User's message to Claude
  sessionId: string,        // Session identifier
  projectPath: string,      // Project directory path
  resume: boolean,          // Whether resuming existing session
  toolsSettings: {
    allowedTools: string[],
    disallowedTools: string[],
    skipPermissions: boolean
  },
  permissionMode: string,
  images: Array<{           // Optional image attachments
    data: string            // Base64 encoded image data
  }>
}

// Abort session
{
  type: 'abort-session',
  sessionId: string
}
```

#### Shell WebSocket
```javascript
// Initialize shell
{
  type: 'init',
  projectPath: string,
  sessionId: string
}

// Send input to shell
{
  type: 'input',
  data: string
}

// Resize terminal
{
  type: 'resize',
  cols: number,
  rows: number
}
```

### Server → Client Messages

#### Chat WebSocket
```javascript
// Session created
{
  type: 'session-created',
  sessionId: string
}

// Claude output (streaming)
{
  type: 'claude-output',
  data: string,            // JSON string of Claude's response
  sessionId: string
}

// Session aborted
{
  type: 'session-aborted',
  sessionId: string,
  success: boolean
}

// Error
{
  type: 'error',
  error: string
}

// Projects updated (from file watcher)
{
  type: 'projects_updated',
  projects: Project[],
  timestamp: string,
  changeType: string,
  filePath: string
}
```

#### Shell WebSocket
```javascript
// Terminal output
{
  type: 'output',
  data: string            // Terminal output with ANSI codes
}

// URL opening event
{
  type: 'url_open',
  url: string
}
```

## Streaming JSON Format
Claude responses use streaming JSON format. Each chunk is a JSON object that may contain:
- Content text
- Tool use information
- Session metadata
- Completion status

## Authentication
WebSocket connections require authentication via:
- Token in query parameters: `?token=<jwt_token>`
- Or custom headers (implementation specific)

## Connection Flow
1. Client connects to WebSocket endpoint
2. Server validates authentication
3. Client sends initialization message
4. Server acknowledges and starts streaming responses
5. Bidirectional communication continues until disconnection

## Error Handling
- Invalid authentication: Connection rejected
- Invalid message format: Error response sent
- Process crashes: Error message with cleanup
- Connection loss: Client should implement reconnection logic