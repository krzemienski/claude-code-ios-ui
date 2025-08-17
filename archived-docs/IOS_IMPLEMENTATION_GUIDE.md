# iOS Claude Code UI - Complete Implementation Guide

## Executive Summary
The iOS app currently has only **32% API coverage** (19 of 60 endpoints implemented) with critical WebSocket bugs preventing real-time messaging. This guide provides step-by-step fixes for all issues.

## 🚨 CRITICAL FIXES (Must Fix First)

### 1. WebSocket URL Fix
**File**: `ChatViewController.swift:236`
```swift
// CURRENT (WRONG):
let url = URL(string: "ws://localhost:3004/api/chat/ws")

// FIXED:
let url = URL(string: "ws://localhost:3004/ws")
```

### 2. WebSocket Message Type Fix
**File**: `WebSocketManager.swift:172`
```swift
// CURRENT (WRONG):
let message: [String: Any] = [
    "type": "message",
    "content": content
]

// FIXED:
let message: [String: Any] = [
    "type": "claude-command",  // or "cursor-command"
    "content": content,
    "projectPath": project.path,  // Must include full path
    "sessionId": currentSessionId ?? ""
]
```

### 3. Project Path Fix
**File**: `WebSocketManager.swift:sendMessage()`
```swift
// ADD THIS PROPERTY:
private var currentProject: Project?
private var currentSessionId: String?

// UPDATE sendMessage:
func sendMessage(_ content: String, for project: Project, sessionId: String? = nil) {
    guard let ws = webSocket else { return }
    
    let message: [String: Any] = [
        "type": "claude-command",
        "content": content,
        "projectPath": project.fullPath ?? project.path,  // Use fullPath
        "sessionId": sessionId ?? currentSessionId ?? ""
    ]
    
    // Rest of implementation...
}
```

### 4. Remove Duplicate Models
**Action**: Delete duplicate definitions in `/ClaudeCodeUI-iOS/Core/Data/Models/Project.swift`
- Keep only `/ClaudeCodeUI-iOS/Models/Session.swift`
- Keep only `/ClaudeCodeUI-iOS/Models/Message.swift`
- Update Project.swift to remove embedded Session and Message classes (lines 88-254)

## 📱 MISSING API IMPLEMENTATIONS

### Git Integration (13 endpoints - 0% implemented)

**File**: Create `ClaudeCodeUI-iOS/Core/Network/GitAPI.swift`
```swift
import Foundation

extension APIClient {
    
    // Git Status
    func getGitStatus(project: String) async throws -> GitStatus {
        let endpoint = APIEndpoint.gitStatus(project: project)
        return try await request(endpoint)
    }
    
    // Git Diff
    func getGitDiff(project: String, file: String) async throws -> GitDiff {
        let endpoint = APIEndpoint.gitDiff(project: project, file: file)
        return try await request(endpoint)
    }
    
    // Git Commit
    func commitChanges(project: String, message: String, files: [String]) async throws -> CommitResponse {
        let endpoint = APIEndpoint.gitCommit(project: project, message: message, files: files)
        return try await request(endpoint)
    }
    
    // Git Branches
    func getGitBranches(project: String) async throws -> BranchesResponse {
        let endpoint = APIEndpoint.gitBranches(project: project)
        return try await request(endpoint)
    }
    
    // Git Checkout
    func checkoutBranch(project: String, branch: String) async throws -> GitResponse {
        let endpoint = APIEndpoint.gitCheckout(project: project, branch: branch)
        return try await request(endpoint)
    }
    
    // Create Branch
    func createBranch(project: String, branch: String) async throws -> GitResponse {
        let endpoint = APIEndpoint.gitCreateBranch(project: project, branch: branch)
        return try await request(endpoint)
    }
    
    // Get Commits
    func getRecentCommits(project: String, limit: Int = 10) async throws -> CommitsResponse {
        let endpoint = APIEndpoint.gitCommits(project: project, limit: limit)
        return try await request(endpoint)
    }
    
    // Remote Status
    func getRemoteStatus(project: String) async throws -> RemoteStatus {
        let endpoint = APIEndpoint.gitRemoteStatus(project: project)
        return try await request(endpoint)
    }
    
    // Fetch
    func gitFetch(project: String) async throws -> GitResponse {
        let endpoint = APIEndpoint.gitFetch(project: project)
        return try await request(endpoint)
    }
    
    // Pull
    func gitPull(project: String) async throws -> GitResponse {
        let endpoint = APIEndpoint.gitPull(project: project)
        return try await request(endpoint)
    }
    
    // Push
    func gitPush(project: String) async throws -> GitResponse {
        let endpoint = APIEndpoint.gitPush(project: project)
        return try await request(endpoint)
    }
    
    // Discard Changes
    func discardFileChanges(project: String, file: String) async throws -> GitResponse {
        let endpoint = APIEndpoint.gitDiscard(project: project, file: file)
        return try await request(endpoint)
    }
    
    // Delete Untracked
    func deleteUntrackedFile(project: String, file: String) async throws -> GitResponse {
        let endpoint = APIEndpoint.gitDeleteUntracked(project: project, file: file)
        return try await request(endpoint)
    }
}
```

### Git Data Models
**File**: Create `ClaudeCodeUI-iOS/Models/Git.swift`
```swift
import Foundation

struct GitStatus: Codable {
    let branch: String
    let modified: [String]
    let added: [String]
    let deleted: [String]
    let untracked: [String]
}

struct GitDiff: Codable {
    let diff: String
}

struct CommitResponse: Codable {
    let success: Bool
    let output: String
}

struct BranchesResponse: Codable {
    let branches: [String]
}

struct GitResponse: Codable {
    let success: Bool
    let output: String?
    let message: String?
}

struct CommitsResponse: Codable {
    let commits: [GitCommit]
}

struct GitCommit: Codable {
    let hash: String
    let author: String
    let email: String
    let date: String
    let message: String
    let stats: String?
}

struct RemoteStatus: Codable {
    let hasRemote: Bool
    let hasUpstream: Bool
    let branch: String
    let remoteBranch: String?
    let remoteName: String?
    let ahead: Int
    let behind: Int
    let isUpToDate: Bool
}
```

### Cursor Integration (7 endpoints - 0% implemented)

**File**: Create `ClaudeCodeUI-iOS/Core/Network/CursorAPI.swift`
```swift
import Foundation

extension APIClient {
    
    // Get Cursor Config
    func getCursorConfig() async throws -> CursorConfig {
        let endpoint = APIEndpoint.cursorConfig
        return try await request(endpoint)
    }
    
    // Update Cursor Config
    func updateCursorConfig(_ config: CursorConfigUpdate) async throws -> CursorConfig {
        let endpoint = APIEndpoint.updateCursorConfig(config)
        return try await request(endpoint)
    }
    
    // Get MCP Servers
    func getCursorMCPServers() async throws -> MCPServersResponse {
        let endpoint = APIEndpoint.cursorMCPServers
        return try await request(endpoint)
    }
    
    // Add MCP Server
    func addMCPServer(_ server: MCPServerConfig) async throws -> APIResponse {
        let endpoint = APIEndpoint.addCursorMCPServer(server)
        return try await request(endpoint)
    }
    
    // Remove MCP Server
    func removeMCPServer(name: String) async throws -> APIResponse {
        let endpoint = APIEndpoint.removeCursorMCPServer(name: name)
        return try await request(endpoint)
    }
    
    // Get Cursor Sessions
    func getCursorSessions(projectPath: String) async throws -> CursorSessionsResponse {
        let endpoint = APIEndpoint.cursorSessions(projectPath: projectPath)
        return try await request(endpoint)
    }
    
    // Get Specific Session
    func getCursorSession(sessionId: String, projectPath: String) async throws -> CursorSession {
        let endpoint = APIEndpoint.cursorSession(sessionId: sessionId, projectPath: projectPath)
        return try await request(endpoint)
    }
}
```

### Terminal/Shell Integration

**File**: Create `ClaudeCodeUI-iOS/Core/Network/ShellWebSocket.swift`
```swift
import Foundation

class ShellWebSocketManager: NSObject {
    static let shared = ShellWebSocketManager()
    
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    
    var onOutput: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onExit: ((Int) -> Void)?
    
    func connect(to projectPath: String) {
        let url = URL(string: "ws://localhost:3004/shell")!
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocket = urlSession?.webSocketTask(with: url)
        webSocket?.resume()
        
        // Send initial CWD
        executeCommand("cd \(projectPath)")
        receiveMessage()
    }
    
    func executeCommand(_ command: String, in directory: String? = nil) {
        let message: [String: Any] = [
            "type": "command",
            "command": command,
            "cwd": directory ?? FileManager.default.currentDirectoryPath
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            let message = URLSessionWebSocketTask.Message.string(string)
            webSocket?.send(message) { error in
                if let error = error {
                    print("Shell WebSocket send error: \(error)")
                }
            }
        }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage()
                
            case .failure(let error):
                print("Shell WebSocket receive error: \(error)")
                self?.onError?(error.localizedDescription)
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        switch type {
        case "output":
            if let output = json["data"] as? String {
                onOutput?(output)
            }
        case "error":
            if let error = json["message"] as? String {
                onError?(error)
            }
        case "exit":
            if let code = json["code"] as? Int {
                onExit?(code)
            }
        default:
            break
        }
    }
    
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
    }
}

extension ShellWebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Shell WebSocket connected")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Shell WebSocket disconnected")
    }
}
```

## 🛠️ API ENDPOINT FIXES

### Fix HTTP Methods
**File**: `APIClient.swift`

```swift
// CURRENT (WRONG):
static func readFile(projectId: String, path: String) -> APIEndpoint {
    return APIEndpoint(
        path: "/api/projects/\(projectId)/files/read",
        method: .post,  // WRONG
        // ...
    )
}

// FIXED:
static func readFile(projectName: String, path: String) -> APIEndpoint {
    return APIEndpoint(
        path: "/api/projects/\(projectName)/file",
        method: .get,  // CORRECT
        queryItems: [URLQueryItem(name: "path", value: path)]
    )
}
```

### Fix Endpoint Paths
```swift
// CURRENT (WRONG):
path: "/api/projects/create"

// FIXED:
path: "/api/projects/create"  // This one is actually correct

// CURRENT (WRONG):
path: "/api/projects/\(projectId)/files/write"

// FIXED:
path: "/api/projects/\(projectName)/file"  // Use PUT method
```

## 📊 IMPLEMENTATION PRIORITY

### Phase 1: Critical Fixes (Day 1)
1. ✅ Fix WebSocket URL path
2. ✅ Fix message types
3. ✅ Add project path to messages
4. ✅ Remove duplicate models
5. ✅ Fix HTTP methods

### Phase 2: Core Features (Days 2-3)
1. ⬜ Implement Git API (13 endpoints)
2. ⬜ Add Shell WebSocket
3. ⬜ Fix file operations
4. ⬜ Add search functionality
5. ⬜ Implement session management

### Phase 3: Advanced Features (Days 4-5)
1. ⬜ Cursor integration (7 endpoints)
2. ⬜ MCP server management (6 endpoints)
3. ⬜ Transcription API
4. ⬜ Image upload
5. ⬜ Authentication flow

## 🧪 TESTING CHECKLIST

### WebSocket Testing
```swift
// Test in ChatViewController
func testWebSocketConnection() {
    // 1. Connect to ws://localhost:3004/ws
    // 2. Send test message with correct type
    // 3. Verify response received
    // 4. Check session creation
}
```

### API Testing
```swift
// Test each endpoint group
func testGitIntegration() {
    Task {
        do {
            // Test Git status
            let status = try await APIClient.shared.getGitStatus(project: "test-project")
            print("Git branch: \(status.branch)")
            
            // Test branches
            let branches = try await APIClient.shared.getGitBranches(project: "test-project")
            print("Branches: \(branches.branches)")
            
        } catch {
            print("Git API error: \(error)")
        }
    }
}
```

## 🎯 SUCCESS CRITERIA

1. **WebSocket**: Real-time chat working with Claude
2. **Sessions**: Can create, list, and resume sessions
3. **Git**: Full version control in app
4. **Terminal**: Execute commands from iOS
5. **Files**: Browse and edit project files
6. **Cursor**: Integrate with Cursor AI
7. **MCP**: Manage MCP servers

## 📝 NOTES FOR iOS DEVELOPERS

1. **Use Async/Await**: All new API methods should use Swift concurrency
2. **Error Handling**: Implement proper error types for each API domain
3. **Caching**: Use SwiftData for offline support
4. **Testing**: Write unit tests for each API method
5. **UI Updates**: Update views to use new API methods
6. **Documentation**: Add DocC comments to all new code

## 🔄 MIGRATION STEPS

1. **Backup Current Code**: Create a git branch
2. **Fix Critical Issues**: WebSocket and models
3. **Add Git API**: Implement all 13 endpoints
4. **Add Shell Support**: Terminal functionality
5. **Test Everything**: Use simulator with backend running
6. **Update UI**: Connect new APIs to views
7. **Polish**: Error handling and edge cases

## 📱 SIMULATOR TESTING

```bash
# Build and run on simulator
xcodebuild build \
  -project ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Boot simulator
xcrun simctl boot "iPhone 15"

# Install app
xcrun simctl install booted Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app

# Launch app
xcrun simctl launch booted com.claudecode.ui
```

## 🚀 FINAL VALIDATION

After implementing all fixes:
1. Start backend: `cd backend && npm start`
2. Build iOS app in Xcode
3. Run on simulator
4. Test complete flow:
   - List projects ✓
   - Select project ✓
   - View sessions ✓
   - Send message ✓
   - Receive response ✓
   - Execute git commands ✓
   - Run terminal commands ✓

---

**Estimated Total Effort**: 5-7 days for complete implementation
**Current Completion**: 32% → Target: 100%