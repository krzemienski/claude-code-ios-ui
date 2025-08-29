# iOS Claude Code UI - API Documentation

**Version**: 1.0.0  
**Base URL**: `http://localhost:3004/api`  
**WebSocket URL**: `ws://localhost:3004/ws`  
**Shell WebSocket URL**: `ws://localhost:3004/shell`

## API Implementation Status

**Total Endpoints**: 62  
**Implemented in iOS**: 49 (79%)  
**Not Implemented**: 13 (21%)

## Authentication

All API requests (except registration and login) require a JWT token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

### 1. Register First User ✅
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "admin",
  "password": "password123"
}

Response: 200 OK
{
  "success": true,
  "message": "User registered successfully"
}
```

### 2. Login ✅
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "password123"
}

Response: 200 OK
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "username": "admin"
  }
}
```

### 3. Check Auth Status ✅
```http
GET /api/auth/status
Authorization: Bearer <token>

Response: 200 OK
{
  "authenticated": true,
  "user": {
    "id": 1,
    "username": "admin"
  }
}
```

### 4. Get Current User ✅
```http
GET /api/auth/user
Authorization: Bearer <token>

Response: 200 OK
{
  "id": 1,
  "username": "admin",
  "createdAt": "2025-01-21T10:00:00Z"
}
```

### 5. Logout ✅
```http
POST /api/auth/logout
Authorization: Bearer <token>

Response: 200 OK
{
  "success": true,
  "message": "Logged out successfully"
}
```

## Projects Management

### 6. List All Projects ✅
```http
GET /api/projects
Authorization: Bearer <token>

Response: 200 OK
{
  "projects": [
    {
      "name": "my-project",
      "path": "/Users/nick/projects/my-project",
      "lastModified": "2025-01-21T10:00:00Z",
      "sessionCount": 5
    }
  ]
}
```

### 7. Create New Project ✅
```http
POST /api/projects/create
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "new-project",
  "path": "/Users/nick/projects/new-project"
}

Response: 200 OK
{
  "success": true,
  "project": {
    "name": "new-project",
    "path": "/Users/nick/projects/new-project"
  }
}
```

### 8. Get Project Details ✅
```http
GET /api/projects/:projectName
Authorization: Bearer <token>

Response: 200 OK
{
  "name": "my-project",
  "path": "/Users/nick/projects/my-project",
  "lastModified": "2025-01-21T10:00:00Z",
  "sessionCount": 5,
  "fileCount": 123
}
```

### 9. Rename Project ✅
```http
PUT /api/projects/:projectName/rename
Authorization: Bearer <token>
Content-Type: application/json

{
  "newName": "renamed-project"
}

Response: 200 OK
{
  "success": true,
  "project": {
    "name": "renamed-project",
    "path": "/Users/nick/projects/renamed-project"
  }
}
```

### 10. Delete Project ✅
```http
DELETE /api/projects/:projectName
Authorization: Bearer <token>

Response: 200 OK
{
  "success": true,
  "message": "Project deleted successfully"
}
```

## Session Management

### 11. Get Project Sessions ✅
```http
GET /api/projects/:projectName/sessions
Authorization: Bearer <token>

Response: 200 OK
{
  "sessions": [
    {
      "id": "session-123",
      "title": "Feature Implementation",
      "createdAt": "2025-01-21T10:00:00Z",
      "messageCount": 42
    }
  ]
}
```

### 12. Create New Session ✅
```http
POST /api/projects/:projectName/sessions
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Bug Fix Session"
}

Response: 200 OK
{
  "success": true,
  "session": {
    "id": "session-456",
    "title": "Bug Fix Session",
    "createdAt": "2025-01-21T10:00:00Z"
  }
}
```

### 13. Get Session Messages ✅
```http
GET /api/projects/:projectName/sessions/:sessionId/messages
Authorization: Bearer <token>

Response: 200 OK
{
  "messages": [
    {
      "id": "msg-1",
      "role": "user",
      "content": "How do I implement authentication?",
      "timestamp": "2025-01-21T10:00:00Z"
    },
    {
      "id": "msg-2",
      "role": "assistant",
      "content": "Here's how to implement authentication...",
      "timestamp": "2025-01-21T10:01:00Z"
    }
  ]
}
```

### 14. Update Session ✅
```http
PUT /api/projects/:projectName/sessions/:sessionId
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Updated Session Title"
}

Response: 200 OK
{
  "success": true,
  "session": {
    "id": "session-123",
    "title": "Updated Session Title"
  }
}
```

### 15. Delete Session ✅
```http
DELETE /api/projects/:projectName/sessions/:sessionId
Authorization: Bearer <token>

Response: 200 OK
{
  "success": true,
  "message": "Session deleted successfully"
}
```

### 16. Clear Session Messages ✅
```http
DELETE /api/projects/:projectName/sessions/:sessionId/messages
Authorization: Bearer <token>

Response: 200 OK
{
  "success": true,
  "message": "Messages cleared successfully"
}
```

## File Operations

### 17. Get File Tree ✅
```http
GET /api/projects/:projectName/files
Authorization: Bearer <token>

Response: 200 OK
{
  "files": [
    {
      "name": "src",
      "type": "directory",
      "children": [
        {
          "name": "index.js",
          "type": "file",
          "size": 1024
        }
      ]
    }
  ]
}
```

### 18. Read File Content ✅
```http
GET /api/projects/:projectName/file?path=src/index.js
Authorization: Bearer <token>

Response: 200 OK
{
  "content": "const express = require('express');\n...",
  "encoding": "utf8",
  "size": 1024
}
```

### 19. Save File Content ✅
```http
PUT /api/projects/:projectName/file
Authorization: Bearer <token>
Content-Type: application/json

{
  "path": "src/index.js",
  "content": "const express = require('express');\n// Updated content"
}

Response: 200 OK
{
  "success": true,
  "message": "File saved successfully"
}
```

### 20. Delete File ✅
```http
DELETE /api/projects/:projectName/file?path=src/temp.js
Authorization: Bearer <token>

Response: 200 OK
{
  "success": true,
  "message": "File deleted successfully"
}
```

## Git Integration (All 20 Endpoints ✅)

### 21. Git Status ✅
```http
GET /api/git/status?projectPath=/path/to/project
Authorization: Bearer <token>

Response: 200 OK
{
  "modified": ["src/index.js"],
  "added": ["README.md"],
  "deleted": [],
  "untracked": ["temp.txt"]
}
```

### 22. Git Commit ✅
```http
POST /api/git/commit
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project",
  "message": "Fix authentication bug"
}

Response: 200 OK
{
  "success": true,
  "commitHash": "abc123def456"
}
```

### 23. List Branches ✅
```http
GET /api/git/branches?projectPath=/path/to/project
Authorization: Bearer <token>

Response: 200 OK
{
  "branches": ["main", "develop", "feature/auth"],
  "current": "main"
}
```

### 24. Checkout Branch ✅
```http
POST /api/git/checkout
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project",
  "branch": "develop"
}

Response: 200 OK
{
  "success": true,
  "currentBranch": "develop"
}
```

### 25. Create Branch ✅
```http
POST /api/git/branch
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project",
  "branchName": "feature/new-feature"
}

Response: 200 OK
{
  "success": true,
  "branch": "feature/new-feature"
}
```

### 26. Git Push ✅
```http
POST /api/git/push
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project",
  "remote": "origin",
  "branch": "main"
}

Response: 200 OK
{
  "success": true,
  "message": "Pushed to origin/main"
}
```

### 27. Git Pull ✅
```http
POST /api/git/pull
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project",
  "remote": "origin",
  "branch": "main"
}

Response: 200 OK
{
  "success": true,
  "message": "Pulled from origin/main"
}
```

### 28. Git Fetch ✅
```http
POST /api/git/fetch
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project"
}

Response: 200 OK
{
  "success": true,
  "message": "Fetched from remote"
}
```

### 29. Git Diff ✅
```http
GET /api/git/diff?projectPath=/path/to/project&file=src/index.js
Authorization: Bearer <token>

Response: 200 OK
{
  "diff": "--- a/src/index.js\n+++ b/src/index.js\n..."
}
```

### 30. Git Log ✅
```http
GET /api/git/log?projectPath=/path/to/project&limit=10
Authorization: Bearer <token>

Response: 200 OK
{
  "commits": [
    {
      "hash": "abc123",
      "message": "Initial commit",
      "author": "John Doe",
      "date": "2025-01-21T10:00:00Z"
    }
  ]
}
```

### 31. Git Add ✅
```http
POST /api/git/add
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project",
  "files": ["src/index.js", "README.md"]
}

Response: 200 OK
{
  "success": true,
  "message": "Files added to staging"
}
```

### 32. Git Reset ✅
```http
POST /api/git/reset
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project",
  "mode": "hard",
  "commit": "HEAD~1"
}

Response: 200 OK
{
  "success": true,
  "message": "Reset to HEAD~1"
}
```

### 33. Git Stash ✅
```http
POST /api/git/stash
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project",
  "message": "WIP: feature implementation"
}

Response: 200 OK
{
  "success": true,
  "stashId": "stash@{0}"
}
```

### 34. Generate Commit Message ✅
```http
POST /api/git/generate-message
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project"
}

Response: 200 OK
{
  "message": "feat: Add authentication middleware"
}
```

### 35. Get Commits ✅
```http
GET /api/git/commits?projectPath=/path/to/project&branch=main&limit=20
Authorization: Bearer <token>

Response: 200 OK
{
  "commits": [...]
}
```

### 36. Get Commit Diff ✅
```http
GET /api/git/commit/:hash/diff?projectPath=/path/to/project
Authorization: Bearer <token>

Response: 200 OK
{
  "diff": "...",
  "files": ["src/index.js", "README.md"]
}
```

### 37. Get Remote Status ✅
```http
GET /api/git/remote-status?projectPath=/path/to/project
Authorization: Bearer <token>

Response: 200 OK
{
  "ahead": 2,
  "behind": 1,
  "upToDate": false
}
```

### 38. Publish Branch ✅
```http
POST /api/git/publish
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project",
  "branch": "feature/new"
}

Response: 200 OK
{
  "success": true,
  "message": "Branch published to origin"
}
```

### 39. Discard Changes ✅
```http
POST /api/git/discard
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project",
  "files": ["src/index.js"]
}

Response: 200 OK
{
  "success": true,
  "message": "Changes discarded"
}
```

### 40. Delete Untracked Files ✅
```http
POST /api/git/clean
Authorization: Bearer <token>
Content-Type: application/json

{
  "projectPath": "/path/to/project",
  "directories": true
}

Response: 200 OK
{
  "success": true,
  "filesDeleted": ["temp.txt", "build/"]
}
```

## MCP Server Management (All 6 Endpoints ✅)

### 41. List MCP Servers ✅
```http
GET /api/mcp/servers
Authorization: Bearer <token>

Response: 200 OK
{
  "servers": [
    {
      "id": "mcp-1",
      "name": "Development Server",
      "url": "http://localhost:8080",
      "status": "online"
    }
  ]
}
```

### 42. Add MCP Server ✅
```http
POST /api/mcp/servers
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Production Server",
  "url": "https://mcp.example.com",
  "apiKey": "secret-key"
}

Response: 200 OK
{
  "success": true,
  "server": {
    "id": "mcp-2",
    "name": "Production Server"
  }
}
```

### 43. Update MCP Server ✅
```http
PUT /api/mcp/servers/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Updated Server Name",
  "url": "https://new-url.com"
}

Response: 200 OK
{
  "success": true,
  "server": {...}
}
```

### 44. Delete MCP Server ✅
```http
DELETE /api/mcp/servers/:id
Authorization: Bearer <token>

Response: 200 OK
{
  "success": true,
  "message": "Server removed"
}
```

### 45. Test MCP Connection ✅
```http
POST /api/mcp/servers/:id/test
Authorization: Bearer <token>

Response: 200 OK
{
  "success": true,
  "status": "online",
  "latency": 45
}
```

### 46. Execute MCP CLI Command ✅
```http
POST /api/mcp/cli
Authorization: Bearer <token>
Content-Type: application/json

{
  "serverId": "mcp-1",
  "command": "status",
  "args": ["--verbose"]
}

Response: 200 OK
{
  "success": true,
  "output": "Server status: OK\n..."
}
```

## Search

### 47. Search Projects ✅
```http
POST /api/projects/:projectName/search
Authorization: Bearer <token>
Content-Type: application/json

{
  "query": "authentication",
  "scope": "all",
  "fileTypes": [".js", ".ts"]
}

Response: 200 OK
{
  "results": [
    {
      "file": "src/auth.js",
      "line": 42,
      "content": "function authenticate(user) {",
      "match": "authenticate"
    }
  ]
}
```

### 48. Global Search ✅
```http
POST /api/search
Authorization: Bearer <token>
Content-Type: application/json

{
  "query": "TODO",
  "projects": ["project1", "project2"]
}

Response: 200 OK
{
  "results": {...}
}
```

## Feedback

### 49. Submit Feedback ✅
```http
POST /api/feedback
Authorization: Bearer <token>
Content-Type: application/json

{
  "type": "bug",
  "message": "WebSocket disconnects frequently",
  "metadata": {
    "version": "1.0.0",
    "platform": "iOS"
  }
}

Response: 200 OK
{
  "success": true,
  "ticketId": "FEEDBACK-123"
}
```

## WebSocket Communication

### Chat WebSocket ✅
```javascript
// Connect to WebSocket
const ws = new WebSocket('ws://localhost:3004/ws');

// Send message
ws.send(JSON.stringify({
  type: 'claude-command',
  content: 'Explain this code',
  projectPath: '/Users/nick/projects/my-project',
  sessionId: 'session-123'
}));

// Receive message
ws.on('message', (data) => {
  const message = JSON.parse(data);
  // Handle assistant response
});
```

### Shell WebSocket ✅
```javascript
// Connect to Shell WebSocket
const shellWs = new WebSocket('ws://localhost:3004/shell');

// Execute command
shellWs.send(JSON.stringify({
  type: 'shell-command',
  command: 'ls -la',
  cwd: '/Users/nick/projects'
}));

// Receive output
shellWs.on('message', (data) => {
  const response = JSON.parse(data);
  if (response.type === 'shell-output') {
    console.log(response.output);
  }
});

// Terminal resize
shellWs.send(JSON.stringify({
  type: 'resize',
  cols: 80,
  rows: 24
}));
```

## Not Implemented Endpoints (13/62 = 21%)

### Cursor Integration (8 endpoints) ❌
1. GET `/api/cursor/config` - Get Cursor configuration
2. POST `/api/cursor/config` - Update Cursor configuration
3. GET `/api/cursor/sessions` - List Cursor sessions
4. GET `/api/cursor/session/:id` - Get Cursor session details
5. POST `/api/cursor/session/import` - Import Cursor session
6. GET `/api/cursor/database` - Access Cursor database
7. POST `/api/cursor/sync` - Sync with Cursor
8. GET `/api/cursor/settings` - Get Cursor settings

### Other Missing Endpoints ❌
9. POST `/api/transcribe` - Audio transcription
10. POST `/api/settings/save` - Save settings to backend
11. GET `/api/settings/load` - Load settings from backend
12. POST `/api/notifications/register` - Register for push notifications
13. POST `/api/share` - Share content via extension

## Error Responses

All endpoints return consistent error responses:

### 400 Bad Request
```json
{
  "error": "Invalid request parameters",
  "details": "Project name is required"
}
```

### 401 Unauthorized
```json
{
  "error": "Authentication required",
  "message": "Please provide a valid token"
}
```

### 404 Not Found
```json
{
  "error": "Resource not found",
  "message": "Project 'my-project' does not exist"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "message": "An unexpected error occurred"
}
```

## Rate Limiting

- Default: 100 requests per minute per IP
- WebSocket: No rate limiting
- File operations: 50 requests per minute

## Best Practices

1. **Always include JWT token** in Authorization header
2. **Use appropriate HTTP methods** (GET for read, POST for create, PUT for update, DELETE for remove)
3. **Handle errors gracefully** with proper error messages
4. **Implement retry logic** with exponential backoff
5. **Cache responses** where appropriate (projects list, file tree)
6. **Use WebSocket** for real-time features (chat, terminal)
7. **Validate input** before sending to API
8. **Implement proper timeout** handling (120s for long operations)

## iOS Implementation Notes

### APIClient Usage
```swift
// Example API call in iOS
APIClient.shared.getProjects { result in
    switch result {
    case .success(let projects):
        // Handle projects
    case .failure(let error):
        // Handle error
    }
}
```

### WebSocketManager Usage
```swift
// WebSocket connection
WebSocketManager.shared.connect()
WebSocketManager.shared.sendMessage(content: "Hello", projectPath: "/path")
```

---

*For implementation details, see `APIClient.swift` and `WebSocketManager.swift` in the iOS project*