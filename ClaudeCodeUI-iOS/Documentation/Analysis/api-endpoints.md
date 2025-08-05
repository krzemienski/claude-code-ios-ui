# API Endpoints - ClaudeCodeUI

## Base Configuration
- Base URL: `http://localhost:3001`
- API Path: `/api`
- Authentication: JWT Bearer token required for all endpoints

## Endpoints

### Configuration
- `GET /api/config` - Get application configuration

### Projects

#### List Projects
- `GET /api/projects` - Get all projects
  - Response: Array of project objects

#### Project Sessions
- `GET /api/projects/:projectName/sessions` - Get sessions for a project
  - Query params: `limit` (default: 5), `offset` (default: 0)
  - Response: Sessions with pagination

#### Session Messages
- `GET /api/projects/:projectName/sessions/:sessionId/messages` - Get messages for a session
  - Response: `{ messages: Message[] }`

#### Project Management
- `PUT /api/projects/:projectName/rename` - Rename a project
  - Body: `{ displayName: string }`
  - Response: `{ success: true }`

- `DELETE /api/projects/:projectName` - Delete a project (only if empty)
  - Response: `{ success: true }`

- `POST /api/projects/create` - Create a new project
  - Body: `{ path: string }`
  - Response: `{ success: true, project: Project }`

#### Session Management
- `DELETE /api/projects/:projectName/sessions/:sessionId` - Delete a session
  - Response: `{ success: true }`

### File Operations

#### Read File
- `GET /api/projects/:projectName/file` - Read text file content
  - Query params: `filePath` (absolute path)
  - Response: `{ content: string, path: string }`

#### Binary File Content
- `GET /api/projects/:projectName/files/content` - Serve binary files (images, etc.)
  - Query params: `path` (absolute path)
  - Response: Binary stream with appropriate MIME type

#### Save File
- `PUT /api/projects/:projectName/file` - Save file content
  - Body: `{ filePath: string, content: string }`
  - Response: `{ success: true, path: string }`

#### List Files
- `GET /api/projects/:projectName/files` - List files in directory
  - Query params: `dirPath` (absolute path)
  - Response: File tree structure

### Media

#### Audio Transcription
- `POST /api/transcribe` - Transcribe audio to text
  - Body: Multipart form with audio file
  - Response: `{ transcript: string, language: string }`

#### Image Upload
- `POST /api/projects/:projectName/upload-images` - Upload images for a project
  - Body: Multipart form with image files
  - Response: `{ files: Array<{ filename: string, path: string, url: string }> }`

### Additional Routes
- Git operations routes (imported from `./routes/git.js`)
- Authentication routes (imported from `./routes/auth.js`)
- MCP routes (imported from `./routes/mcp.js`)

## Authentication
All endpoints (except auth routes) require JWT token in Authorization header:
```
Authorization: Bearer <jwt_token>
```

## Error Responses
Standard error format:
```json
{
  "error": "Error message description"
}
```

Common status codes:
- 200: Success
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 500: Internal Server Error