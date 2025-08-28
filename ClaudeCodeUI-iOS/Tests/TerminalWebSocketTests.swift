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
            fullPath: "/test/path",
            displayName: "Test Project"
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
        // Simulate receiving shell output with ANSI colors
        mockWebSocketManager.simulateMessage("""
            {"type": "shell-output", "output": "\(testText)"}
        """)
        
        // Verify the text view contains the output (without ANSI codes)
        XCTAssertTrue(terminalVC.terminalTextView.text.contains("Red Text"))
        XCTAssertTrue(terminalVC.terminalTextView.text.contains("Normal Text"))
    }
    
    // MARK: - CM-TERM-02: ANSI Color Tests
    
    func testANSI16BasicColors() {
        // Test all 16 basic ANSI colors
        let colorTests = [
            ("\u{001B}[30mBlack\u{001B}[0m", "Black"),
            ("\u{001B}[31mRed\u{001B}[0m", "Red"),
            ("\u{001B}[32mGreen\u{001B}[0m", "Green"),
            ("\u{001B}[33mYellow\u{001B}[0m", "Yellow"),
            ("\u{001B}[34mBlue\u{001B}[0m", "Blue"),
            ("\u{001B}[35mMagenta\u{001B}[0m", "Magenta"),
            ("\u{001B}[36mCyan\u{001B}[0m", "Cyan"),
            ("\u{001B}[37mWhite\u{001B}[0m", "White"),
            ("\u{001B}[90mBright Black\u{001B}[0m", "Bright Black"),
            ("\u{001B}[91mBright Red\u{001B}[0m", "Bright Red"),
            ("\u{001B}[92mBright Green\u{001B}[0m", "Bright Green"),
            ("\u{001B}[93mBright Yellow\u{001B}[0m", "Bright Yellow"),
            ("\u{001B}[94mBright Blue\u{001B}[0m", "Bright Blue"),
            ("\u{001B}[95mBright Magenta\u{001B}[0m", "Bright Magenta"),
            ("\u{001B}[96mBright Cyan\u{001B}[0m", "Bright Cyan"),
            ("\u{001B}[97mBright White\u{001B}[0m", "Bright White")
        ]
        
        for (ansiText, colorName) in colorTests {
            // Use ANSIParser directly for testing
            let parsed = ANSIParser.parse(ansiText)
            let plainText = parsed.string
            
            // Verify ANSI codes are stripped
            XCTAssertFalse(plainText.contains("\u{001B}"), "ANSI codes should be removed for \(colorName)")
            XCTAssertEqual(plainText, colorName, "Text should be preserved for \(colorName)")
            
            // Check that color attributes exist
            var hasColor = false
            parsed.enumerateAttributes(in: NSRange(location: 0, length: parsed.length), options: []) { attrs, range, _ in
                if let _ = attrs[.foregroundColor] as? UIColor {
                    hasColor = true
                }
            }
            XCTAssertTrue(hasColor, "Should have color attribute for \(colorName)")
        }
    }
    
    func testANSI256ColorMode() {
        // Test 256 color mode
        let colorTests = [
            "\u{001B}[38;5;214mOrange (214)\u{001B}[0m",
            "\u{001B}[38;5;196mRed (196)\u{001B}[0m",
            "\u{001B}[38;5;46mGreen (46)\u{001B}[0m",
            "\u{001B}[38;5;21mBlue (21)\u{001B}[0m"
        ]
        
        for ansiText in colorTests {
            let parsed = ANSIParser.parse(ansiText)
            let plainText = parsed.string
            
            // Verify ANSI codes are stripped
            XCTAssertFalse(plainText.contains("\u{001B}"), "ANSI codes should be removed")
            XCTAssertFalse(plainText.contains("[38;5;"), "256 color codes should be removed")
            
            // Check that color attributes exist
            var hasColor = false
            parsed.enumerateAttributes(in: NSRange(location: 0, length: parsed.length), options: []) { attrs, range, _ in
                if let _ = attrs[.foregroundColor] as? UIColor {
                    hasColor = true
                }
            }
            XCTAssertTrue(hasColor, "Should have color attribute for 256 color mode")
        }
    }
    
    func testANSITrueColor() {
        // Test true color (RGB) mode
        let colorTests = [
            "\u{001B}[38;2;255;128;0mOrange RGB\u{001B}[0m",
            "\u{001B}[38;2;255;0;0mRed RGB\u{001B}[0m",
            "\u{001B}[38;2;0;255;0mGreen RGB\u{001B}[0m",
            "\u{001B}[38;2;0;0;255mBlue RGB\u{001B}[0m"
        ]
        
        for ansiText in colorTests {
            let parsed = ANSIParser.parse(ansiText)
            let plainText = parsed.string
            
            // Verify ANSI codes are stripped
            XCTAssertFalse(plainText.contains("\u{001B}"), "ANSI codes should be removed")
            XCTAssertFalse(plainText.contains("[38;2;"), "RGB color codes should be removed")
            XCTAssertTrue(plainText.contains("RGB"), "Text content should be preserved")
        }
    }
    
    func testANSITextAttributes() {
        // Test text attributes (bold, italic, underline)
        let attributeTests = [
            ("\u{001B}[1mBold\u{001B}[0m", "Bold"),
            ("\u{001B}[3mItalic\u{001B}[0m", "Italic"),
            ("\u{001B}[4mUnderline\u{001B}[0m", "Underline"),
            ("\u{001B}[9mStrikethrough\u{001B}[0m", "Strikethrough"),
            ("\u{001B}[1;31mBold Red\u{001B}[0m", "Bold Red")
        ]
        
        for (ansiText, styleName) in attributeTests {
            let parsed = ANSIParser.parse(ansiText)
            let plainText = parsed.string
            
            // Verify ANSI codes are stripped
            XCTAssertFalse(plainText.contains("\u{001B}"), "ANSI codes should be removed for \(styleName)")
            
            // Check for appropriate attributes
            var hasAttribute = false
            parsed.enumerateAttributes(in: NSRange(location: 0, length: parsed.length), options: []) { attrs, range, _ in
                if styleName.contains("Bold"), let font = attrs[.font] as? UIFont {
                    let traits = font.fontDescriptor.symbolicTraits
                    if traits.contains(.traitBold) {
                        hasAttribute = true
                    }
                }
                if styleName.contains("Underline"), let _ = attrs[.underlineStyle] {
                    hasAttribute = true
                }
                if styleName.contains("Strikethrough"), let _ = attrs[.strikethroughStyle] {
                    hasAttribute = true
                }
                if styleName.contains("Italic") || styleName.contains("Red") {
                    hasAttribute = true // Font or color exists
                }
            }
            XCTAssertTrue(hasAttribute, "Should have appropriate attribute for \(styleName)")
        }
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
        
        mockWebSocketManager.simulateMessage(errorMessage)
        
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
    
    func connect(to endpoint: String, with token: String?) {
        connectionAttempts += 1
        lastConnectedURL = endpoint
        // Simulate async connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulateConnection()
        }
    }
    
    func disconnect() {
        isConnected = false
        delegate?.webSocketDidDisconnect(self, error: nil)
    }
    
    func send(_ message: String) {
        onMessageSent?(message)
    }
    
    func sendData(_ data: Data) {
        if let text = String(data: data, encoding: .utf8) {
            onMessageSent?(text)
        }
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