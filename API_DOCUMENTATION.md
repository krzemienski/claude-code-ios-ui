# Claude Code iOS UI - Complete Backend API Documentation

## Table of Contents
1. [Server Configuration](#server-configuration)
2. [Authentication API](#authentication-api)
3. [Projects API](#projects-api)
4. [Sessions API](#sessions-api)
5. [Files API](#files-api)
6. [Git API](#git-api)
7. [Cursor Integration API](#cursor-integration-api)
8. [MCP Server API](#mcp-server-api)
9. [WebSocket APIs](#websocket-apis)
10. [Transcription API](#transcription-api)

---

## Server Configuration

**Base URL**: `http://localhost:3004`

**Headers**:
- `Content-Type: application/json` (for JSON requests)
- `Authorization: Bearer <token>` (for protected endpoints - currently disabled for iOS testing)

---

## Authentication API

### 1. Check Auth Status
**GET** `/api/auth/status`

Check if authentication is configured and if setup is needed.

**Response**:
```json
{
  "needsSetup": boolean,    // true if no users exist
  "isAuthenticated": boolean // Current auth status
}
```

### 2. Register User (Setup)
**POST** `/api/auth/register`

Register the first and only user (single-user system).

**Request Body**:
```json
{
  "username": "string",  // Min 3 characters
  "password": "string"   // Min 6 characters
}
```

**Response**:
```json
{
  "success": true,
  "user": {
    "id": "string",
    "username": "string"
  },
  "token": "JWT_TOKEN"
}
```

**Error Responses**:
- 400: Invalid input
- 403: User already exists (single-user system)

### 3. User Login
**POST** `/api/auth/login`

Authenticate user and receive JWT token.

**Request Body**:
```json
{
  "username": "string",
  "password": "string"
}
```

**Response**:
```json
{
  "success": true,
  "user": {
    "id": "string",
    "username": "string"
  },
  "token": "JWT_TOKEN"
}
```

**Error Response**:
- 401: Invalid credentials

### 4. Get Current User
**GET** `/api/auth/user`

🔒 **Protected** - Requires Bearer token

**Response**:
```json
{
  "user": {
    "id": "string",
    "username": "string"
  }
}
```

### 5. Logout
**POST** `/api/auth/logout`

🔒 **Protected** - Requires Bearer token

**Response**:
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## Projects API

### 1. Get Server Configuration
**GET** `/api/config`

Get server configuration including version and shell settings.

**Response**:
```json
{
  "version": "1.0.0",
  "shell": "bash",
  "projectsDirectory": "/path/to/projects"
}
```

### 2. List All Projects
**GET** `/api/projects`

List all available projects.

**Response**:
```json
[
  {
    "name": "project-name",
    "path": "/full/path/to/project",
    "fullPath": "/full/path/to/project",
    "sessionCount": 5,
    "lastModified": "2024-01-15T10:30:00Z"
  }
]
```

### 3. Create New Project
**POST** `/api/projects/create`

Create a new project directory.

**Request Body**:
```json
{
  "name": "project-name",
  "path": "/path/to/create/project"
}
```

**Response**:
```json
{
  "success": true,
  "project": {
    "name": "project-name",
    "path": "/full/path/to/project"
  }
}
```

### 4. Rename Project
**PUT** `/api/projects/:projectName/rename`

Rename an existing project.

**Request Body**:
```json
{
  "newName": "new-project-name"
}
```

**Response**:
```json
{
  "success": true,
  "oldName": "old-name",
  "newName": "new-name"
}
```

### 5. Delete Project
**DELETE** `/api/projects/:projectName`

Delete a project and all its sessions.

**Response**:
```json
{
  "success": true,
  "message": "Project deleted successfully"
}
```

---

## Sessions API

### 1. Get Project Sessions
**GET** `/api/projects/:projectName/sessions`

Get all sessions for a specific project.

**Query Parameters**:
- `limit` (optional): Number of sessions to return (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Response**:
```json
{
  "sessions": [
    {
      "id": "session-uuid",
      "summary": "Session summary text",
      "messageCount": 42,
      "lastActivity": "2024-01-15T10:30:00Z",
      "cwd": "/project/directory",
      "createdAt": "2024-01-15T09:00:00Z"
    }
  ],
  "total": 100,
  "limit": 50,
  "offset": 0
}
```

### 2. Get Session Messages
**GET** `/api/projects/:projectName/sessions/:sessionId/messages`

Get all messages for a specific session.

**Query Parameters**:
- `limit` (optional): Number of messages (default: 100)
- `offset` (optional): Pagination offset (default: 0)

**Response**:
```json
{
  "messages": [
    {
      "id": "message-id",
      "sessionId": "session-uuid",
      "content": "Message content",
      "role": "user|assistant|system",
      "timestamp": "2024-01-15T10:30:00Z",
      "metadata": {
        "tokens": 150,
        "model": "claude-3"
      }
    }
  ],
  "total": 200,
  "limit": 100,
  "offset": 0
}
```

### 3. Delete Session
**DELETE** `/api/projects/:projectName/sessions/:sessionId`

Delete a specific session and all its messages.

**Response**:
```json
{
  "success": true,
  "message": "Session deleted successfully"
}
```

---

## Files API

### 1. Get File Tree
**GET** `/api/projects/:projectName/files`

Get the file tree structure for a project.

**Query Parameters**:
- `path` (optional): Subdirectory path (default: project root)

**Response**:
```json
{
  "files": [
    {
      "name": "src",
      "type": "directory",
      "path": "/project/src",
      "children": [
        {
          "name": "index.js",
          "type": "file",
          "path": "/project/src/index.js",
          "size": 1024,
          "modified": "2024-01-15T10:30:00Z"
        }
      ]
    }
  ]
}
```

### 2. Read File Content
**GET** `/api/projects/:projectName/file`

Read the content of a specific file.

**Query Parameters**:
- `path`: Relative file path within project

**Response**:
```json
{
  "content": "file content here",
  "path": "src/index.js",
  "encoding": "utf8",
  "size": 1024
}
```

### 3. Save File Content
**PUT** `/api/projects/:projectName/file`

Save/update file content.

**Request Body**:
```json
{
  "path": "src/index.js",
  "content": "new file content"
}
```

**Response**:
```json
{
  "success": true,
  "path": "src/index.js",
  "size": 1234
}
```

---

## Git API

### 1. Get Git Status
**GET** `/api/git/status`

Get git status for a project.

**Query Parameters**:
- `project`: Project name (required)

**Response**:
```json
{
  "branch": "main",
  "modified": ["file1.js", "file2.js"],
  "added": ["newfile.js"],
  "deleted": ["oldfile.js"],
  "untracked": ["tempfile.txt"]
}
```

**Error Response** (if not a git repository):
```json
{
  "error": "Not a git repository. This directory does not contain a .git folder."
}
```

### 2. Get File Diff
**GET** `/api/git/diff`

Get diff for a specific file.

**Query Parameters**:
- `project`: Project name (required)
- `file`: File path (required)

**Response**:
```json
{
  "diff": "--- a/file.js\n+++ b/file.js\n@@ -1,3 +1,4 @@\n..."
}
```

### 3. Commit Changes
**POST** `/api/git/commit`

Commit selected files with a message.

**Request Body**:
```json
{
  "project": "project-name",
  "message": "Commit message",
  "files": ["file1.js", "file2.js"]
}
```

**Response**:
```json
{
  "success": true,
  "output": "Commit output from git"
}
```

### 4. Get Branches
**GET** `/api/git/branches`

Get list of all branches.

**Query Parameters**:
- `project`: Project name (required)

**Response**:
```json
{
  "branches": ["main", "develop", "feature/new-feature"]
}
```

### 5. Checkout Branch
**POST** `/api/git/checkout`

Switch to a different branch.

**Request Body**:
```json
{
  "project": "project-name",
  "branch": "branch-name"
}
```

**Response**:
```json
{
  "success": true,
  "output": "Switched to branch 'branch-name'"
}
```

### 6. Create Branch
**POST** `/api/git/create-branch`

Create and checkout a new branch.

**Request Body**:
```json
{
  "project": "project-name",
  "branch": "new-branch-name"
}
```

**Response**:
```json
{
  "success": true,
  "output": "Switched to a new branch 'new-branch-name'"
}
```

### 7. Get Recent Commits
**GET** `/api/git/commits`

Get recent commit history.

**Query Parameters**:
- `project`: Project name (required)
- `limit`: Number of commits (default: 10)

**Response**:
```json
{
  "commits": [
    {
      "hash": "abc123...",
      "author": "John Doe",
      "email": "john@example.com",
      "date": "2 hours ago",
      "message": "Fixed bug in authentication",
      "stats": "2 files changed, 10 insertions(+), 5 deletions(-)"
    }
  ]
}
```

### 8. Get Commit Diff
**GET** `/api/git/commit-diff`

Get diff for a specific commit.

**Query Parameters**:
- `project`: Project name (required)
- `commit`: Commit hash (required)

**Response**:
```json
{
  "diff": "commit abc123...\nAuthor: John Doe\nDate: ...\n\n..."
}
```

### 9. Generate Commit Message
**POST** `/api/git/generate-commit-message`

Generate AI-powered commit message based on changes.

**Request Body**:
```json
{
  "project": "project-name",
  "files": ["file1.js", "file2.js"]
}
```

**Response**:
```json
{
  "message": "Update authentication component"
}
```

### 10. Get Remote Status
**GET** `/api/git/remote-status`

Check ahead/behind status with remote.

**Query Parameters**:
- `project`: Project name (required)

**Response**:
```json
{
  "hasRemote": true,
  "hasUpstream": true,
  "branch": "main",
  "remoteBranch": "origin/main",
  "remoteName": "origin",
  "ahead": 2,
  "behind": 1,
  "isUpToDate": false
}
```

### 11. Fetch from Remote
**POST** `/api/git/fetch`

Fetch latest changes from remote.

**Request Body**:
```json
{
  "project": "project-name"
}
```

**Response**:
```json
{
  "success": true,
  "output": "Fetch completed successfully",
  "remoteName": "origin"
}
```

### 12. Pull from Remote
**POST** `/api/git/pull`

Pull and merge changes from remote.

**Request Body**:
```json
{
  "project": "project-name"
}
```

**Response**:
```json
{
  "success": true,
  "output": "Already up to date.",
  "remoteName": "origin",
  "remoteBranch": "main"
}
```

### 13. Push to Remote
**POST** `/api/git/push`

Push commits to remote repository.

**Request Body**:
```json
{
  "project": "project-name"
}
```

**Response**:
```json
{
  "success": true,
  "output": "Push completed successfully",
  "remoteName": "origin",
  "remoteBranch": "main"
}
```

### 14. Publish Branch
**POST** `/api/git/publish`

Set upstream and push new branch.

**Request Body**:
```json
{
  "project": "project-name",
  "branch": "feature-branch"
}
```

**Response**:
```json
{
  "success": true,
  "output": "Branch published successfully",
  "remoteName": "origin",
  "branch": "feature-branch"
}
```

### 15. Discard File Changes
**POST** `/api/git/discard`

Discard changes for a specific file.

**Request Body**:
```json
{
  "project": "project-name",
  "file": "path/to/file.js"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Changes discarded for path/to/file.js"
}
```

### 16. Delete Untracked File
**POST** `/api/git/delete-untracked`

Delete an untracked file.

**Request Body**:
```json
{
  "project": "project-name",
  "file": "path/to/untracked.txt"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Untracked file deleted successfully"
}
```

---

## Cursor Integration API

### 1. Get Cursor Configuration
**GET** `/api/cursor/config`

Read Cursor CLI configuration.

**Response**:
```json
{
  "success": true,
  "config": {
    "version": 1,
    "model": {
      "modelId": "gpt-5",
      "displayName": "GPT-5"
    },
    "permissions": {
      "allow": [],
      "deny": []
    }
  },
  "path": "/Users/username/.cursor/cli-config.json"
}
```

### 2. Update Cursor Configuration
**POST** `/api/cursor/config`

Update Cursor CLI configuration.

**Request Body**:
```json
{
  "permissions": {
    "allow": ["path1", "path2"],
    "deny": ["path3"]
  },
  "model": {
    "modelId": "claude-3",
    "displayName": "Claude 3"
  }
}
```

**Response**:
```json
{
  "success": true,
  "config": {...},
  "message": "Cursor configuration updated successfully"
}
```

### 3. Get Cursor MCP Servers
**GET** `/api/cursor/mcp`

Get MCP servers configured in Cursor.

**Response**:
```json
{
  "success": true,
  "servers": [
    {
      "id": "server-name",
      "name": "server-name",
      "type": "stdio",
      "scope": "cursor",
      "config": {
        "command": "npx",
        "args": ["server-package"],
        "env": {}
      }
    }
  ],
  "path": "/Users/username/.cursor/mcp.json"
}
```

### 4. Add MCP Server to Cursor
**POST** `/api/cursor/mcp/add`

Add MCP server to Cursor configuration.

**Request Body**:
```json
{
  "name": "my-server",
  "type": "stdio",
  "command": "npx",
  "args": ["my-mcp-server"],
  "env": {
    "API_KEY": "key123"
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "MCP server added to Cursor configuration"
}
```

### 5. Remove MCP Server from Cursor
**DELETE** `/api/cursor/mcp/:name`

Remove MCP server from Cursor.

**Response**:
```json
{
  "success": true,
  "message": "MCP server removed from Cursor configuration"
}
```

### 6. Add MCP Server via JSON
**POST** `/api/cursor/mcp/add-json`

Add MCP server using JSON configuration.

**Request Body**:
```json
{
  "name": "my-server",
  "jsonConfig": {
    "command": "npx",
    "args": ["server-package"],
    "env": {}
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "MCP server added via JSON"
}
```

### 7. Get Cursor Sessions
**GET** `/api/cursor/sessions`

Get Cursor chat sessions from SQLite database.

**Query Parameters**:
- `projectPath`: Project directory path

**Response**:
```json
{
  "success": true,
  "sessions": [
    {
      "id": "session-id",
      "name": "Session Name",
      "createdAt": "2024-01-15T10:30:00Z",
      "mode": "chat",
      "projectPath": "/path/to/project",
      "lastMessage": "Last message preview...",
      "messageCount": 25
    }
  ],
  "cwdId": "md5-hash",
  "path": "/Users/username/.cursor/chats/hash"
}
```

### 8. Get Specific Cursor Session
**GET** `/api/cursor/sessions/:sessionId`

Get detailed session with all messages.

**Query Parameters**:
- `projectPath`: Project directory path

**Response**:
```json
{
  "success": true,
  "session": {
    "id": "session-id",
    "projectPath": "/path/to/project",
    "messages": [
      {
        "id": "message-id",
        "sequence": 1,
        "rowid": 123,
        "content": {
          "role": "user",
          "content": "Message content",
          "timestamp": "2024-01-15T10:30:00Z"
        }
      }
    ],
    "metadata": {
      "agent": {...},
      "settings": {...}
    },
    "cwdId": "md5-hash"
  }
}
```

---

## MCP Server API

### 1. List MCP Servers (CLI)
**GET** `/api/mcp/cli/list`

List MCP servers using Claude CLI.

**Response**:
```json
{
  "success": true,
  "output": "CLI output text",
  "servers": [
    {
      "name": "server-name",
      "type": "stdio",
      "status": "connected",
      "description": "Server description"
    }
  ]
}
```

### 2. Add MCP Server (CLI)
**POST** `/api/mcp/cli/add`

Add MCP server using Claude CLI.

**Request Body**:
```json
{
  "name": "server-name",
  "type": "stdio",
  "command": "npx",
  "args": ["package-name"],
  "env": {
    "KEY": "value"
  },
  "scope": "user",  // or "local"
  "projectPath": "/path/for/local/scope"
}
```

**Response**:
```json
{
  "success": true,
  "output": "CLI output",
  "message": "MCP server added successfully"
}
```

### 3. Add MCP Server via JSON (CLI)
**POST** `/api/mcp/cli/add-json`

Add MCP server using JSON format via CLI.

**Request Body**:
```json
{
  "name": "server-name",
  "jsonConfig": {
    "type": "stdio",
    "command": "npx",
    "args": ["package"]
  },
  "scope": "user",
  "projectPath": "/path/for/local"
}
```

**Response**:
```json
{
  "success": true,
  "output": "CLI output",
  "message": "MCP server added via JSON"
}
```

### 4. Remove MCP Server (CLI)
**DELETE** `/api/mcp/cli/remove/:name`

Remove MCP server using Claude CLI.

**Query Parameters**:
- `scope`: "user" or "local" (optional)

**Response**:
```json
{
  "success": true,
  "output": "CLI output",
  "message": "MCP server removed successfully"
}
```

### 5. Get MCP Server Details (CLI)
**GET** `/api/mcp/cli/get/:name`

Get details of a specific MCP server.

**Response**:
```json
{
  "success": true,
  "output": "CLI output",
  "server": {
    "name": "server-name",
    "type": "stdio",
    "command": "npx",
    "url": "http://...",
    "raw_output": "..."
  }
}
```

### 6. Read MCP Config Files
**GET** `/api/mcp/config/read`

Read MCP servers from Claude config files.

**Response**:
```json
{
  "success": true,
  "configPath": "/Users/username/.claude/settings.json",
  "servers": [
    {
      "id": "server-name",
      "name": "server-name",
      "type": "stdio",
      "scope": "user",
      "config": {
        "command": "npx",
        "args": [],
        "env": {}
      },
      "raw": {...}
    }
  ]
}
```

---

## WebSocket APIs

### 1. Chat WebSocket
**WebSocket** `ws://localhost:3004/ws`

Real-time chat communication.

**Connection**:
```javascript
const ws = new WebSocket('ws://localhost:3004/ws');
```

**Message Types**:

#### Send Message (Client → Server)
```json
{
  "type": "claude-command",
  "content": "User message text",
  "projectPath": "/path/to/project",
  "sessionId": "session-uuid"  // Optional, created if not provided
}
```

#### Receive Message (Server → Client)
```json
{
  "type": "claude-output",  // or "claude-response", "claude-error"
  "content": "Assistant response",
  "sessionId": "session-uuid",
  "timestamp": "2024-01-15T10:30:00Z",
  "metadata": {
    "tokens": 150,
    "model": "claude-3"
  }
}
```

#### Cursor Command (Alternative)
```json
{
  "type": "cursor-command",
  "content": "Command for Cursor integration",
  "projectPath": "/path/to/project"
}
```

#### Abort Session
```json
{
  "type": "abort-session",
  "sessionId": "session-uuid"
}
```

### 2. Shell WebSocket
**WebSocket** `ws://localhost:3004/shell`

Terminal command execution.

**Connection**:
```javascript
const ws = new WebSocket('ws://localhost:3004/shell');
```

**Command Execution**:
```json
{
  "type": "command",
  "command": "ls -la",
  "cwd": "/path/to/directory"
}
```

**Output Response**:
```json
{
  "type": "output",
  "data": "Command output text"
}
```

**Error Response**:
```json
{
  "type": "error",
  "message": "Error message"
}
```

**Exit Response**:
```json
{
  "type": "exit",
  "code": 0
}
```

---

## Transcription API

### Audio Transcription
**POST** `/api/transcribe`

Transcribe audio file to text.

**Request**: `multipart/form-data`
- `audio`: Audio file (WAV, MP3, M4A, etc.)

**Response**:
```json
{
  "text": "Transcribed text content",
  "duration": 5.2,
  "format": "wav"
}
```

---

## Image Upload API

### Upload Images
**POST** `/api/projects/:projectName/upload-images`

Upload images for a project.

**Request**: `multipart/form-data`
- `images`: One or more image files

**Response**:
```json
{
  "success": true,
  "uploaded": [
    {
      "filename": "image1.png",
      "path": "/uploads/project/image1.png",
      "size": 102400
    }
  ]
}
```

---

## Error Response Format

All endpoints return consistent error responses:

```json
{
  "error": "Error message",
  "details": "Detailed error information",  // Optional
  "code": "ERROR_CODE"                      // Optional
}
```

Common HTTP status codes:
- **200**: Success
- **400**: Bad Request
- **401**: Unauthorized
- **403**: Forbidden
- **404**: Not Found
- **409**: Conflict
- **500**: Internal Server Error

---

## Authentication Notes

Currently, authentication is **temporarily disabled** for the `/api/projects` endpoints to facilitate iOS testing. In production:
- All endpoints except `/api/auth/*` should require Bearer token authentication
- Token should be included in `Authorization: Bearer <token>` header
- Tokens are JWT with user information payload
- Single-user system - only one user account allowed

---

## Rate Limiting

No rate limiting is currently implemented. In production, consider:
- API rate limiting per endpoint
- WebSocket message throttling
- File upload size limits
- Request body size limits

---

## CORS Configuration

Server is configured to accept requests from:
- `http://localhost:*` (all localhost ports)
- iOS simulator connections
- Local network IPs for device testing

---

## Next Steps for iOS Implementation

1. **Implement APIClient methods** for all documented endpoints
2. **Create data models** matching response schemas
3. **Add WebSocket handlers** for real-time features
4. **Implement authentication flow** with JWT storage
5. **Add error handling** for all error response types
6. **Create unit tests** for API integration
7. **Add request/response logging** for debugging
8. **Implement offline caching** for session/message data