# Complete cURL Examples for Backend API Testing

## Base Configuration
```bash
# Set base URL
BASE_URL="http://localhost:3004"

# For authenticated endpoints (after login)
TOKEN="your-jwt-token-here"
```

## 1. Authentication Endpoints

### Check Auth Status
```bash
curl -X GET "${BASE_URL}/api/auth/status" \
  -H "Content-Type: application/json"
```

### Register User (First Setup)
```bash
curl -X POST "${BASE_URL}/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "testpass123"
  }'
```

### Login
```bash
curl -X POST "${BASE_URL}/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "testpass123"
  }'
```

### Get Current User
```bash
curl -X GET "${BASE_URL}/api/auth/user" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Logout
```bash
curl -X POST "${BASE_URL}/api/auth/logout" \
  -H "Authorization: Bearer ${TOKEN}"
```

## 2. Projects Endpoints

### Get Server Config
```bash
curl -X GET "${BASE_URL}/api/config"
```

### List All Projects
```bash
curl -X GET "${BASE_URL}/api/projects"
```

### Create New Project
```bash
curl -X POST "${BASE_URL}/api/projects/create" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-test-project",
    "path": "/Users/nick/Documents/test-project"
  }'
```

### Rename Project
```bash
curl -X PUT "${BASE_URL}/api/projects/my-test-project/rename" \
  -H "Content-Type: application/json" \
  -d '{
    "newName": "renamed-project"
  }'
```

### Delete Project
```bash
curl -X DELETE "${BASE_URL}/api/projects/my-test-project"
```

## 3. Sessions Endpoints

### Get Project Sessions
```bash
curl -X GET "${BASE_URL}/api/projects/my-project/sessions?limit=50&offset=0"
```

### Get Session Messages
```bash
curl -X GET "${BASE_URL}/api/projects/my-project/sessions/session-uuid/messages?limit=100&offset=0"
```

### Delete Session
```bash
curl -X DELETE "${BASE_URL}/api/projects/my-project/sessions/session-uuid"
```

## 4. Files Endpoints

### Get File Tree
```bash
curl -X GET "${BASE_URL}/api/projects/my-project/files?path=src"
```

### Read File Content
```bash
curl -X GET "${BASE_URL}/api/projects/my-project/file?path=src/index.js"
```

### Save File Content
```bash
curl -X PUT "${BASE_URL}/api/projects/my-project/file" \
  -H "Content-Type: application/json" \
  -d '{
    "path": "src/index.js",
    "content": "console.log(\"Hello World\");"
  }'
```

## 5. Git Endpoints

### Get Git Status
```bash
curl -X GET "${BASE_URL}/api/git/status?project=my-project"
```

### Get File Diff
```bash
curl -X GET "${BASE_URL}/api/git/diff?project=my-project&file=src/index.js"
```

### Commit Changes
```bash
curl -X POST "${BASE_URL}/api/git/commit" \
  -H "Content-Type: application/json" \
  -d '{
    "project": "my-project",
    "message": "Test commit message",
    "files": ["src/index.js", "src/app.js"]
  }'
```

### Get Branches
```bash
curl -X GET "${BASE_URL}/api/git/branches?project=my-project"
```

### Checkout Branch
```bash
curl -X POST "${BASE_URL}/api/git/checkout" \
  -H "Content-Type: application/json" \
  -d '{
    "project": "my-project",
    "branch": "develop"
  }'
```

### Create Branch
```bash
curl -X POST "${BASE_URL}/api/git/create-branch" \
  -H "Content-Type: application/json" \
  -d '{
    "project": "my-project",
    "branch": "feature/new-feature"
  }'
```

### Get Recent Commits
```bash
curl -X GET "${BASE_URL}/api/git/commits?project=my-project&limit=10"
```

### Get Remote Status
```bash
curl -X GET "${BASE_URL}/api/git/remote-status?project=my-project"
```

### Fetch from Remote
```bash
curl -X POST "${BASE_URL}/api/git/fetch" \
  -H "Content-Type: application/json" \
  -d '{
    "project": "my-project"
  }'
```

### Pull from Remote
```bash
curl -X POST "${BASE_URL}/api/git/pull" \
  -H "Content-Type: application/json" \
  -d '{
    "project": "my-project"
  }'
```

### Push to Remote
```bash
curl -X POST "${BASE_URL}/api/git/push" \
  -H "Content-Type: application/json" \
  -d '{
    "project": "my-project"
  }'
```

## 6. Cursor Integration Endpoints

### Get Cursor Config
```bash
curl -X GET "${BASE_URL}/api/cursor/config"
```

### Update Cursor Config
```bash
curl -X POST "${BASE_URL}/api/cursor/config" \
  -H "Content-Type: application/json" \
  -d '{
    "permissions": {
      "allow": ["/path/to/project"],
      "deny": []
    },
    "model": {
      "modelId": "claude-3",
      "displayName": "Claude 3"
    }
  }'
```

### Get Cursor MCP Servers
```bash
curl -X GET "${BASE_URL}/api/cursor/mcp"
```

### Add MCP Server to Cursor
```bash
curl -X POST "${BASE_URL}/api/cursor/mcp/add" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-server",
    "type": "stdio",
    "command": "npx",
    "args": ["my-mcp-server"],
    "env": {
      "API_KEY": "key123"
    }
  }'
```

### Get Cursor Sessions
```bash
curl -X GET "${BASE_URL}/api/cursor/sessions?projectPath=/path/to/project"
```

## 7. MCP Server Management

### List MCP Servers (CLI)
```bash
curl -X GET "${BASE_URL}/api/mcp/cli/list"
```

### Add MCP Server (CLI)
```bash
curl -X POST "${BASE_URL}/api/mcp/cli/add" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "server-name",
    "type": "stdio",
    "command": "npx",
    "args": ["package-name"],
    "env": {
      "KEY": "value"
    },
    "scope": "user"
  }'
```

### Remove MCP Server (CLI)
```bash
curl -X DELETE "${BASE_URL}/api/mcp/cli/remove/server-name?scope=user"
```

## 8. WebSocket Connections

### Chat WebSocket Connection (JavaScript)
```javascript
// Connect to chat WebSocket
const ws = new WebSocket('ws://localhost:3004/ws');

// Send message
ws.send(JSON.stringify({
  type: 'claude-command',
  content: 'Hello Claude',
  projectPath: '/Users/nick/Documents/my-project',
  sessionId: 'optional-session-id'
}));

// Handle responses
ws.on('message', (data) => {
  const msg = JSON.parse(data);
  console.log('Received:', msg);
});
```

### Shell WebSocket Connection (JavaScript)
```javascript
// Connect to shell WebSocket
const shellWs = new WebSocket('ws://localhost:3004/shell');

// Execute command
shellWs.send(JSON.stringify({
  type: 'command',
  command: 'ls -la',
  cwd: '/Users/nick/Documents/my-project'
}));

// Handle output
shellWs.on('message', (data) => {
  const msg = JSON.parse(data);
  if (msg.type === 'output') {
    console.log('Output:', msg.data);
  }
});
```

## 9. Transcription

### Transcribe Audio (with file)
```bash
curl -X POST "${BASE_URL}/api/transcribe" \
  -F "audio=@/path/to/audio.wav"
```

## 10. Image Upload

### Upload Images
```bash
curl -X POST "${BASE_URL}/api/projects/my-project/upload-images" \
  -F "images=@/path/to/image1.png" \
  -F "images=@/path/to/image2.jpg"
```

## Testing Script

Create a test script `test-api.sh`:
```bash
#!/bin/bash

BASE_URL="http://localhost:3004"
PROJECT_NAME="test-project"

echo "Testing Claude Code Backend API..."
echo "================================="

# 1. Check server status
echo -n "1. Checking server config... "
curl -s "${BASE_URL}/api/config" > /dev/null && echo "✅" || echo "❌"

# 2. Check auth status
echo -n "2. Checking auth status... "
curl -s "${BASE_URL}/api/auth/status" > /dev/null && echo "✅" || echo "❌"

# 3. List projects
echo -n "3. Listing projects... "
curl -s "${BASE_URL}/api/projects" > /dev/null && echo "✅" || echo "❌"

# 4. Check Git status (may fail if no project)
echo -n "4. Checking Git status... "
curl -s "${BASE_URL}/api/git/status?project=${PROJECT_NAME}" > /dev/null 2>&1 && echo "✅" || echo "⚠️ (expected if no git repo)"

# 5. Check WebSocket endpoints
echo -n "5. Testing WebSocket availability... "
curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/ws" | grep -q "426" && echo "✅ (WebSocket endpoint exists)" || echo "❌"

echo ""
echo "Basic connectivity test complete!"
```

## Notes

1. **Authentication**: Most endpoints currently have auth disabled for iOS testing
2. **Project Names**: Replace `my-project` with actual project names from the system
3. **Session IDs**: Use actual UUIDs returned from session creation
4. **File Paths**: Use actual file paths relative to project root
5. **WebSocket**: Requires WebSocket client, not cURL
6. **Token Storage**: Store JWT token after login for authenticated endpoints