//
//  TerminalWebSocketTests.swift
//  ClaudeCodeUITests
//
//  Created on 2025-01-18.
//

import XCTest
@testable import ClaudeCodeUI

class TerminalWebSocketTests: XCTestCase {
    
    var terminalVC: TerminalViewController!
    var mockWebSocketManager: MockWebSocketManager!
    
    override func setUp() {
        super.setUp()
        
        // Create test project
        let project = Project(
            id: "test-project",
            name: "Test Project",
            path: "/test/path",
            lastAccessed: Date(),
            icon: "folder"
        )
        
        // Initialize terminal with project
        terminalVC = TerminalViewController(project: project)
        
        // Create mock WebSocket manager
        mockWebSocketManager = MockWebSocketManager()
        
        // Load view to trigger viewDidLoad
        _ = terminalVC.view
    }
    
    override func tearDown() {
        terminalVC = nil
        mockWebSocketManager = nil
        super.tearDown()
    }
    
    // MARK: - Connection Tests
    
    func testShellWebSocketConnection() {
        // Test that shell WebSocket connects to correct endpoint
        let expectation = self.expectation(description: "WebSocket connects")
        
        // Simulate connection
        mockWebSocketManager.simulateConnection()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.mockWebSocketManager.isConnected)
            XCTAssertEqual(self.mockWebSocketManager.lastConnectedURL, "ws://localhost:3004/shell")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testShellInitMessage() {
        // Test that init message is sent after connection
        let expectation = self.expectation(description: "Init message sent")
        
        mockWebSocketManager.onMessageSent = { message in
            if let data = message.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                XCTAssertEqual(json["type"] as? String, "init")
                XCTAssertNotNil(json["projectPath"])
                XCTAssertEqual(json["provider"] as? String, "terminal")
                XCTAssertNotNil(json["cols"])
                XCTAssertNotNil(json["rows"])
                expectation.fulfill()
            }
        }
        
        // Simulate connection
        mockWebSocketManager.simulateConnection()
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testCommandExecution() {
        // Test sending shell commands
        let expectation = self.expectation(description: "Command sent")
        
        mockWebSocketManager.simulateConnection()
        
        mockWebSocketManager.onMessageSent = { message in
            if let data = message.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if json["type"] as? String == "shell-command" {
                    XCTAssertEqual(json["command"] as? String, "ls -la")
                    XCTAssertNotNil(json["cwd"])
                    expectation.fulfill()
                }
            }
        }
        
        // Send test command
        terminalVC.textFieldShouldReturn(terminalVC.commandTextField)
        terminalVC.commandTextField.text = "ls -la"
        _ = terminalVC.textFieldShouldReturn(terminalVC.commandTextField)
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testTerminalResize() {
        // Test terminal resize message
        let expectation = self.expectation(description: "Resize message sent")
        
        mockWebSocketManager.simulateConnection()
        
        mockWebSocketManager.onMessageSent = { message in
            if let data = message.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if json["type"] as? String == "resize" {
                    let cols = json["cols"] as? Int ?? 0
                    let rows = json["rows"] as? Int ?? 0
                    XCTAssertGreaterThanOrEqual(cols, 80)
                    XCTAssertGreaterThanOrEqual(rows, 24)
                    expectation.fulfill()
                }
            }
        }
        
        // Trigger view layout to send resize
        terminalVC.viewDidLayoutSubviews()
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testANSIColorParsing() {
        // Test ANSI color code parsing
        let testText = "\u{001B}[31mRed Text\u{001B}[0m Normal Text"
        
        // This would need access to the private parseANSIOutput method
        // For now, we test the public interface
        terminalVC.webSocket(mockWebSocketManager, didReceiveText: """
            {"type": "shell-output", "output": "\(testText)"}
        """)
        
        // Verify the text view contains the output (without ANSI codes)
        XCTAssertTrue(terminalVC.terminalTextView.text.contains("Red Text"))
        XCTAssertTrue(terminalVC.terminalTextView.text.contains("Normal Text"))
    }
    
    func testReconnection() {
        // Test auto-reconnection with exponential backoff
        let expectation = self.expectation(description: "Reconnection attempted")
        
        mockWebSocketManager.simulateConnection()
        
        // Simulate disconnection
        mockWebSocketManager.simulateDisconnection(error: NSError(domain: "test", code: 1))
        
        // Should attempt reconnection
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            XCTAssertGreaterThan(self.mockWebSocketManager.connectionAttempts, 1)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testErrorHandling() {
        // Test error message display
        let errorMessage = """
            {"type": "shell-error", "error": "command not found: fakecommand"}
        """
        
        terminalVC.webSocket(mockWebSocketManager, didReceiveText: errorMessage)
        
        // Verify error is displayed
        XCTAssertTrue(terminalVC.terminalTextView.text.contains("command not found"))
    }
}

// MARK: - Mock WebSocket Manager

class MockWebSocketManager: NSObject, WebSocketProtocol {
    var isConnected = false
    var lastConnectedURL: String?
    var connectionAttempts = 0
    var delegate: WebSocketManagerDelegate?
    var onMessageSent: ((String) -> Void)?
    
    func connect(to url: String) {
        connectionAttempts += 1
        lastConnectedURL = url
        // Simulate async connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulateConnection()
        }
    }
    
    func disconnect() {
        isConnected = false
        delegate?.webSocketDidDisconnect(self, error: nil)
    }
    
    func send(_ message: WebSocketMessage) {
        // Not used in terminal
    }
    
    func sendRawText(_ text: String) {
        onMessageSent?(text)
    }
    
    func simulateConnection() {
        isConnected = true
        delegate?.webSocketDidConnect(self)
    }
    
    func simulateDisconnection(error: Error?) {
        isConnected = false
        delegate?.webSocketDidDisconnect(self, error: error)
    }
    
    func simulateMessage(_ text: String) {
        delegate?.webSocket(self, didReceiveText: text)
    }
}

// Extension to access private properties for testing
extension TerminalViewController {
    var terminalTextView: UITextView {
        return value(forKey: "terminalTextView") as! UITextView
    }
    
    var commandTextField: UITextField {
        return value(forKey: "commandTextField") as! UITextField
    }
}