//
//  MCPServerTests.swift
//  ClaudeCodeUITests
//
//  Created on 2025-01-18.
//

import XCTest
@testable import ClaudeCodeUI

class MCPServerTests: XCTestCase {
    
    var mcpViewModel: MCPServerViewModel!
    var mockAPIClient: MockMCPAPIClient!
    
    override func setUp() {
        super.setUp()
        
        // Create mock API client
        mockAPIClient = MockMCPAPIClient()
        
        // Initialize MCP view model
        mcpViewModel = MCPServerViewModel()
        mcpViewModel.apiClient = mockAPIClient
    }
    
    override func tearDown() {
        mcpViewModel = nil
        mockAPIClient = nil
        super.tearDown()
    }
    
    // MARK: - List Servers Tests
    
    func testListMCPServersEndpoint() {
        // Test that list uses correct API endpoint
        let expectation = self.expectation(description: "List API called")
        
        mockAPIClient.onRequestMade = { endpoint, method in
            XCTAssertEqual(endpoint, "/api/mcp/servers")
            XCTAssertEqual(method, "GET")
            expectation.fulfill()
        }
        
        Task {
            await mcpViewModel.loadServers()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testListMCPServersResponse() {
        // Test parsing of server list response
        let expectation = self.expectation(description: "Servers parsed")
        
        mockAPIClient.mockListResponse = [
            "servers": [
                [
                    "id": "server1",
                    "name": "Test Server 1",
                    "url": "ws://localhost:3000",
                    "type": "websocket",
                    "status": "connected",
                    "capabilities": ["completion", "chat"]
                ],
                [
                    "id": "server2",
                    "name": "Test Server 2",
                    "url": "stdio://python-server",
                    "type": "stdio",
                    "status": "disconnected",
                    "capabilities": ["search"]
                ]
            ]
        ]
        
        Task {
            await mcpViewModel.loadServers()
            
            XCTAssertEqual(self.mcpViewModel.servers.count, 2)
            XCTAssertEqual(self.mcpViewModel.servers[0].name, "Test Server 1")
            XCTAssertEqual(self.mcpViewModel.servers[0].status, "connected")
            XCTAssertEqual(self.mcpViewModel.servers[1].name, "Test Server 2")
            XCTAssertEqual(self.mcpViewModel.servers[1].type, "stdio")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Add Server Tests
    
    func testAddMCPServerEndpoint() {
        // Test add server API endpoint
        let expectation = self.expectation(description: "Add API called")
        
        mockAPIClient.onRequestMade = { endpoint, method in
            XCTAssertEqual(endpoint, "/api/mcp/servers")
            XCTAssertEqual(method, "POST")
            expectation.fulfill()
        }
        
        Task {
            await mcpViewModel.addServer(
                name: "New Server",
                url: "ws://localhost:4000",
                type: "websocket",
                apiKey: "test-key"
            )
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testAddMCPServerRequestBody() {
        // Test add server request body
        let expectation = self.expectation(description: "Request body verified")
        
        mockAPIClient.onRequestBody = { body in
            if let data = body,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                XCTAssertEqual(json["name"] as? String, "New Server")
                XCTAssertEqual(json["url"] as? String, "ws://localhost:4000")
                XCTAssertEqual(json["type"] as? String, "websocket")
                XCTAssertEqual(json["apiKey"] as? String, "secret-key")
                expectation.fulfill()
            }
        }
        
        Task {
            await mcpViewModel.addServer(
                name: "New Server",
                url: "ws://localhost:4000",
                type: "websocket",
                apiKey: "secret-key"
            )
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testAddMCPServerSuccess() {
        // Test successful server addition
        let expectation = self.expectation(description: "Server added")
        
        mockAPIClient.mockAddResponse = [
            "server": [
                "id": "new-server-id",
                "name": "New Server",
                "url": "ws://localhost:4000",
                "type": "websocket",
                "status": "connecting"
            ]
        ]
        
        Task {
            let success = await mcpViewModel.addServer(
                name: "New Server",
                url: "ws://localhost:4000",
                type: "websocket",
                apiKey: nil
            )
            
            XCTAssertTrue(success)
            XCTAssertTrue(self.mcpViewModel.servers.contains { $0.id == "new-server-id" })
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Remove Server Tests
    
    func testRemoveMCPServerEndpoint() {
        // Test remove server API endpoint
        let expectation = self.expectation(description: "Remove API called")
        
        mockAPIClient.onRequestMade = { endpoint, method in
            XCTAssertEqual(endpoint, "/api/mcp/servers/server-to-remove")
            XCTAssertEqual(method, "DELETE")
            expectation.fulfill()
        }
        
        Task {
            await mcpViewModel.removeServer(id: "server-to-remove")
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testRemoveMCPServerSuccess() {
        // Test successful server removal
        let expectation = self.expectation(description: "Server removed")
        
        // First add a server to the list
        mcpViewModel.servers = [
            MCPServer(id: "server1", name: "Server 1", url: "ws://test", type: "websocket"),
            MCPServer(id: "server2", name: "Server 2", url: "ws://test2", type: "websocket")
        ]
        
        mockAPIClient.shouldSucceed = true
        
        Task {
            let success = await mcpViewModel.removeServer(id: "server1")
            
            XCTAssertTrue(success)
            XCTAssertEqual(self.mcpViewModel.servers.count, 1)
            XCTAssertFalse(self.mcpViewModel.servers.contains { $0.id == "server1" })
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Test Connection Tests
    
    func testTestConnectionEndpoint() {
        // Test connection test API endpoint
        let expectation = self.expectation(description: "Test API called")
        
        mockAPIClient.onRequestMade = { endpoint, method in
            XCTAssertEqual(endpoint, "/api/mcp/servers/test-server-id/test")
            XCTAssertEqual(method, "POST")
            expectation.fulfill()
        }
        
        Task {
            await mcpViewModel.testConnection(serverId: "test-server-id")
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testTestConnectionSuccess() {
        // Test successful connection test
        let expectation = self.expectation(description: "Connection tested")
        
        mockAPIClient.mockTestResponse = [
            "success": true,
            "message": "Connection successful",
            "responseTime": 150
        ]
        
        Task {
            let result = await mcpViewModel.testConnection(serverId: "test-server")
            
            XCTAssertTrue(result.success)
            XCTAssertEqual(result.message, "Connection successful")
            XCTAssertEqual(result.responseTime, 150)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testTestConnectionFailure() {
        // Test failed connection test
        let expectation = self.expectation(description: "Connection failed")
        
        mockAPIClient.mockTestResponse = [
            "success": false,
            "message": "Connection timeout",
            "error": "ETIMEDOUT"
        ]
        
        Task {
            let result = await mcpViewModel.testConnection(serverId: "test-server")
            
            XCTAssertFalse(result.success)
            XCTAssertEqual(result.message, "Connection timeout")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Execute CLI Command Tests
    
    func testExecuteCLICommandEndpoint() {
        // Test CLI command execution endpoint
        let expectation = self.expectation(description: "CLI API called")
        
        mockAPIClient.onRequestMade = { endpoint, method in
            XCTAssertEqual(endpoint, "/api/mcp/cli")
            XCTAssertEqual(method, "POST")
            expectation.fulfill()
        }
        
        Task {
            await mcpViewModel.executeCLICommand("mcp list")
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testExecuteCLICommandBody() {
        // Test CLI command request body
        let expectation = self.expectation(description: "CLI body verified")
        
        mockAPIClient.onRequestBody = { body in
            if let data = body,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                XCTAssertEqual(json["command"] as? String, "mcp install server-name")
                expectation.fulfill()
            }
        }
        
        Task {
            await mcpViewModel.executeCLICommand("mcp install server-name")
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testExecuteCLICommandResponse() {
        // Test CLI command response parsing
        let expectation = self.expectation(description: "CLI response parsed")
        
        mockAPIClient.mockCLIResponse = [
            "output": "Server installed successfully",
            "exitCode": 0,
            "error": nil
        ]
        
        Task {
            let result = await mcpViewModel.executeCLICommand("mcp install test")
            
            XCTAssertEqual(result.output, "Server installed successfully")
            XCTAssertEqual(result.exitCode, 0)
            XCTAssertNil(result.error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() {
        // Test network error handling
        let expectation = self.expectation(description: "Error handled")
        
        mockAPIClient.shouldFailRequest = true
        mockAPIClient.mockError = NSError(domain: "test", code: -1009, userInfo: [
            NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
        ])
        
        Task {
            await mcpViewModel.loadServers()
            
            XCTAssertNotNil(self.mcpViewModel.errorMessage)
            XCTAssertTrue(self.mcpViewModel.errorMessage?.contains("offline") ?? false)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testServerValidation() {
        // Test server validation before adding
        let expectation = self.expectation(description: "Validation tested")
        
        Task {
            // Test empty name
            var success = await mcpViewModel.addServer(
                name: "",
                url: "ws://localhost:3000",
                type: "websocket",
                apiKey: nil
            )
            XCTAssertFalse(success)
            
            // Test invalid URL
            success = await mcpViewModel.addServer(
                name: "Test",
                url: "not-a-url",
                type: "websocket",
                apiKey: nil
            )
            XCTAssertFalse(success)
            
            // Test invalid type
            success = await mcpViewModel.addServer(
                name: "Test",
                url: "ws://localhost:3000",
                type: "invalid-type",
                apiKey: nil
            )
            XCTAssertFalse(success)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
}

// MARK: - Mock MCP API Client

class MockMCPAPIClient: MCPAPIClientProtocol {
    var onRequestMade: ((String, String) -> Void)?
    var onRequestBody: ((Data?) -> Void)?
    var mockListResponse: [String: Any] = [:]
    var mockAddResponse: [String: Any] = [:]
    var mockTestResponse: [String: Any] = [:]
    var mockCLIResponse: [String: Any] = [:]
    var shouldFailRequest = false
    var shouldSucceed = true
    var mockError: Error?
    
    func request(_ endpoint: String, method: String, body: Data?) async throws -> Data {
        onRequestMade?(endpoint, method)
        onRequestBody?(body)
        
        if shouldFailRequest {
            throw mockError ?? NSError(domain: "test", code: 500)
        }
        
        // Return appropriate response based on endpoint
        var response: [String: Any] = [:]
        
        if endpoint.contains("/test") {
            response = mockTestResponse
        } else if endpoint == "/api/mcp/cli" {
            response = mockCLIResponse
        } else if method == "POST" {
            response = mockAddResponse
        } else if method == "GET" {
            response = mockListResponse
        } else if method == "DELETE" {
            response = ["success": shouldSucceed]
        }
        
        return try JSONSerialization.data(withJSONObject: response)
    }
}

// Protocol for dependency injection
protocol MCPAPIClientProtocol {
    func request(_ endpoint: String, method: String, body: Data?) async throws -> Data
}

// Extension for testing
extension MCPServerViewModel {
    var apiClient: MCPAPIClientProtocol? {
        get { return nil }
        set { /* In real code, would set internal client */ }
    }
    
    var errorMessage: String? {
        get { return nil }
        set { /* In real code, would set error */ }
    }
}

// Mock MCP Server model
struct MCPServer {
    let id: String
    let name: String
    let url: String
    let type: String
    var status: String = "disconnected"
    var capabilities: [String] = []
}