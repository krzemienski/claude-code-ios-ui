# MCP Server Management - Implementation Guide

## Overview
MCP (Model Context Protocol) Server Management is **CRITICAL** for Claude Code functionality. This feature allows iOS app to manage and interact with MCP servers that provide context and capabilities to Claude.

## Current State Analysis

### ✅ Already Implemented
1. **API Client Methods** (lines 196-290 in APIClient.swift)
   - `getMCPServers()` - Fetches list of servers
   - `addMCPServer()` - Adds new server
   - `updateMCPServer()` - Updates existing server
   - `deleteMCPServer()` - Removes server
   - `testMCPServer()` - Tests connection
   - `executeMCPCommand()` - Runs CLI commands

2. **Models** (MCPModels.swift)
   - `MCPServer` struct with all properties
   - `ConnectionTestResult` for test responses
   - Server types: REST, WebSocket, GraphQL

3. **SwiftUI Views** (MCP folder)
   - `MCPServerListView` - Main list interface
   - `MCPServerDetailView` - Server details/editing
   - `MCPServerViewModel` - Business logic

4. **UIKit Bridge** (MCPServerViewModel.swift line 243)
   - `MCPServerListViewController` - UIKit wrapper

### ❌ Missing Integration
1. **Navigation**: Not added to MainTabBarController
2. **Backend Testing**: Endpoints not verified with real backend
3. **UI Polish**: No loading states or error handling
4. **CLI Integration**: Command execution UI missing

## Step-by-Step Implementation

### Step 1: Add MCP Tab to Main Navigation

**File**: `MainTabBarController.swift`
**Location**: Around line 50-60 where tabs are configured

```swift
private func setupViewControllers() {
    // ... existing tabs ...
    
    // Add MCP Servers tab
    let mcpViewController = MCPServerListViewController()
    let mcpNavController = UINavigationController(rootViewController: mcpViewController)
    mcpNavController.tabBarItem = UITabBarItem(
        title: "MCP",
        image: UIImage(systemName: "server.rack"),
        selectedImage: UIImage(systemName: "server.rack.fill")
    )
    mcpNavController.tabBarItem.tag = 4
    
    // Update viewControllers array
    viewControllers = [
        projectsNavController,
        chatNavController,
        terminalNavController,
        mcpNavController,  // Add this
        settingsNavController
    ]
}
```

### Step 2: Test Backend Endpoints

**Testing Script**: Create `test_mcp_endpoints.sh`

```bash
#!/bin/bash

TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjIsInVzZXJuYW1lIjoiZGVtbyIsImlhdCI6MTc1NTEzMjI3Mn0.D2ca9DyDwRR8rcJ3Latt86KyfsfuN4_8poJCQCjQ8TI"
BASE_URL="http://localhost:3004"

echo "Testing MCP Server Endpoints..."

# 1. List servers
echo "1. GET /api/mcp/servers"
curl -X GET "$BASE_URL/api/mcp/servers" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

# 2. Add server
echo -e "\n2. POST /api/mcp/servers"
curl -X POST "$BASE_URL/api/mcp/servers" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test MCP Server",
    "url": "http://localhost:8080/mcp",
    "type": "rest",
    "description": "Test server for iOS app"
  }'

# 3. Test connection (use server ID from add response)
echo -e "\n3. POST /api/mcp/servers/{id}/test"
# Replace {id} with actual server ID

# 4. Execute CLI command
echo -e "\n4. POST /api/mcp/cli"
curl -X POST "$BASE_URL/api/mcp/cli" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "command": "mcp",
    "args": ["list"]
  }'
```

### Step 3: Enhance MCPServerViewModel

**File**: `MCPServerViewModel.swift`
**Improvements**: Add proper error handling and loading states

```swift
// Add to MCPServerViewModel class

@Published var isTestingConnection = false
@Published var testResults: [String: ConnectionTestResult] = [:]
@Published var cliOutput: String = ""
@Published var isExecutingCommand = false

func executeCLICommand(_ command: String, args: [String]? = nil) async {
    isExecutingCommand = true
    errorMessage = nil
    
    do {
        let output = try await APIClient.shared.executeMCPCommand(
            command: command,
            args: args
        )
        cliOutput = output
        isExecutingCommand = false
    } catch {
        errorMessage = "Command failed: \(error.localizedDescription)"
        isExecutingCommand = false
    }
}

func refreshServers() async {
    isLoading = true
    await loadServersFromAPI()
    isLoading = false
}
```

### Step 4: Create MCP CLI Interface

**New File**: `MCPCLIView.swift`

```swift
import SwiftUI

struct MCPCLIView: View {
    @StateObject private var viewModel = MCPServerViewModel()
    @State private var commandText = ""
    @State private var commandHistory: [String] = []
    @State private var historyIndex = -1
    
    var body: some View {
        VStack(spacing: 0) {
            // Output area
            ScrollViewReader { proxy in
                ScrollView {
                    Text(viewModel.cliOutput)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(CyberpunkTheme.primaryText))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("output")
                }
                .background(Color(red: 0.05, green: 0.05, blue: 0.07))
                .onChange(of: viewModel.cliOutput) { _ in
                    withAnimation {
                        proxy.scrollTo("output", anchor: .bottom)
                    }
                }
            }
            
            // Command input
            HStack {
                Text("$")
                    .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    .font(.system(.body, design: .monospaced))
                
                TextField("mcp command", text: $commandText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color(CyberpunkTheme.primaryText))
                    .onSubmit {
                        executeCommand()
                    }
                
                if viewModel.isExecutingCommand {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(CyberpunkTheme.primaryCyan)))
                        .scaleEffect(0.8)
                } else {
                    Button(action: executeCommand) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    }
                }
            }
            .padding()
            .background(Color(red: 0.08, green: 0.08, blue: 0.1))
        }
        .navigationTitle("MCP CLI")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func executeCommand() {
        guard !commandText.isEmpty else { return }
        
        // Parse command
        let components = commandText.split(separator: " ").map(String.init)
        let command = components.first ?? ""
        let args = Array(components.dropFirst())
        
        // Add to history
        commandHistory.append(commandText)
        commandText = ""
        
        // Execute
        Task {
            await viewModel.executeCLICommand(command, args: args)
        }
    }
}
```

### Step 5: Integration Testing

**New File**: `MCPIntegrationTests.swift`

```swift
import XCTest
@testable import ClaudeCodeUI

class MCPIntegrationTests: XCTestCase {
    
    var apiClient: APIClient!
    var testServer: MCPServer!
    
    override func setUp() async throws {
        apiClient = APIClient.shared
        
        // Create test server
        testServer = MCPServer(
            id: UUID().uuidString,
            name: "Integration Test Server",
            url: "http://localhost:8080/test",
            description: "Test server for integration testing",
            type: .rest,
            apiKey: nil,
            isDefault: false,
            isConnected: false
        )
    }
    
    func testMCPServerLifecycle() async throws {
        // 1. List servers
        let initialServers = try await apiClient.getMCPServers()
        let initialCount = initialServers.count
        
        // 2. Add server
        let addedServer = try await apiClient.addMCPServer(testServer)
        XCTAssertNotNil(addedServer.id)
        XCTAssertEqual(addedServer.name, testServer.name)
        
        // 3. Verify server appears in list
        let updatedServers = try await apiClient.getMCPServers()
        XCTAssertEqual(updatedServers.count, initialCount + 1)
        
        // 4. Test connection
        let testResult = try await apiClient.testMCPServer(id: addedServer.id)
        XCTAssertNotNil(testResult.message)
        
        // 5. Update server
        var modifiedServer = addedServer
        modifiedServer.description = "Updated description"
        let updated = try await apiClient.updateMCPServer(modifiedServer)
        XCTAssertEqual(updated.description, "Updated description")
        
        // 6. Delete server
        try await apiClient.deleteMCPServer(id: addedServer.id)
        
        // 7. Verify deletion
        let finalServers = try await apiClient.getMCPServers()
        XCTAssertEqual(finalServers.count, initialCount)
    }
    
    func testMCPCLIExecution() async throws {
        // Test basic MCP command
        let output = try await apiClient.executeMCPCommand(
            command: "mcp",
            args: ["version"]
        )
        XCTAssertFalse(output.isEmpty)
    }
}
```

## Backend Requirements

The backend must implement these endpoints:

### 1. GET /api/mcp/servers
```javascript
app.get('/api/mcp/servers', authenticateToken, (req, res) => {
    // Return array of MCP servers from database
    const servers = db.prepare('SELECT * FROM mcp_servers WHERE user_id = ?')
        .all(req.user.userId);
    res.json(servers);
});
```

### 2. POST /api/mcp/servers
```javascript
app.post('/api/mcp/servers', authenticateToken, (req, res) => {
    const { name, url, type, description, apiKey } = req.body;
    const id = uuidv4();
    
    const result = db.prepare(`
        INSERT INTO mcp_servers (id, user_id, name, url, type, description, api_key)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(id, req.user.userId, name, url, type, description, apiKey);
    
    res.json({ id, name, url, type, description });
});
```

### 3. POST /api/mcp/servers/:id/test
```javascript
app.post('/api/mcp/servers/:id/test', authenticateToken, async (req, res) => {
    const { id } = req.params;
    
    // Fetch server details
    const server = db.prepare('SELECT * FROM mcp_servers WHERE id = ?').get(id);
    
    if (!server) {
        return res.status(404).json({ error: 'Server not found' });
    }
    
    // Test connection
    const startTime = Date.now();
    try {
        const response = await fetch(server.url + '/health');
        const latency = Date.now() - startTime;
        
        if (response.ok) {
            res.json({
                success: true,
                message: 'Connection successful',
                latency
            });
        } else {
            res.json({
                success: false,
                message: `Server returned ${response.status}`,
                latency
            });
        }
    } catch (error) {
        res.json({
            success: false,
            message: error.message,
            latency: null
        });
    }
});
```

### 4. POST /api/mcp/cli
```javascript
const { exec } = require('child_process');

app.post('/api/mcp/cli', authenticateToken, (req, res) => {
    const { command, args } = req.body;
    
    // Validate command (whitelist allowed commands)
    const allowedCommands = ['mcp', 'npx'];
    if (!allowedCommands.includes(command)) {
        return res.status(403).json({ error: 'Command not allowed' });
    }
    
    // Execute command
    const fullCommand = args ? `${command} ${args.join(' ')}` : command;
    
    exec(fullCommand, { timeout: 30000 }, (error, stdout, stderr) => {
        if (error) {
            res.json({
                output: stderr || error.message,
                success: false
            });
        } else {
            res.json({
                output: stdout,
                success: true
            });
        }
    });
});
```

## Testing Checklist

### Unit Tests
- [ ] MCPServer model encoding/decoding
- [ ] MCPServerViewModel state management
- [ ] API endpoint parameter formatting
- [ ] Connection test result parsing

### Integration Tests
- [ ] Full CRUD cycle for MCP servers
- [ ] Connection testing with timeout
- [ ] CLI command execution
- [ ] Error handling for network failures

### UI Tests
- [ ] Navigate to MCP tab
- [ ] Add new server flow
- [ ] Edit existing server
- [ ] Delete server with confirmation
- [ ] Test connection button feedback
- [ ] CLI command execution

### Manual Testing
1. Start backend: `cd backend && npm start`
2. Run iOS app in simulator
3. Navigate to MCP tab
4. Verify server list loads
5. Add test server
6. Test connection
7. Execute "mcp list" command
8. Delete test server

## Common Issues & Solutions

### Issue 1: Backend endpoints return 404
**Solution**: Ensure backend has MCP routes implemented. Check `backend/server/index.js`

### Issue 2: Connection test always fails
**Solution**: 
- Check CORS settings in backend
- Verify server URL format
- Ensure authentication token is valid

### Issue 3: CLI commands not executing
**Solution**:
- Backend must have `child_process` enabled
- Commands must be whitelisted for security
- Check process permissions

### Issue 4: UI not updating after API calls
**Solution**:
- Ensure @Published properties are updated on main thread
- Use @MainActor for ViewModel methods
- Check Combine publishers are connected

## Performance Considerations

1. **Server List Caching**: Cache for 5 minutes to reduce API calls
2. **Connection Test Timeout**: Set 10-second timeout
3. **CLI Output Streaming**: For long-running commands, use WebSocket
4. **Pagination**: If >50 servers, implement pagination

## Security Considerations

1. **API Key Storage**: Use Keychain, not UserDefaults
2. **Command Validation**: Whitelist allowed MCP commands
3. **URL Validation**: Verify server URLs before connection
4. **Token Refresh**: Implement JWT refresh for long sessions

## Next Steps

After MCP implementation:
1. Add server status monitoring (polling every 30s)
2. Implement server groups/categories
3. Add import/export configuration
4. Create quick actions for common commands
5. Add server connection history/logs

---

Estimated Time: 2-3 days for full implementation and testing
Dependencies: Backend MCP endpoints must be implemented
Priority: P0 - CRITICAL for Claude Code functionality