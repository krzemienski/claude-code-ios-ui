//
//  WebSocketMessageParserTests.swift
//  ClaudeCodeUITests
//
//  Created by Claude Code UI on 2025/01/30.
//

import XCTest
@testable import ClaudeCodeUI

final class WebSocketMessageParserTests: XCTestCase {
    
    // MARK: - Test Data
    
    private let validTextMessage = """
    {
        "id": "msg-123",
        "type": "text",
        "content": "Hello, this is a test message",
        "sessionId": "session-456",
        "timestamp": "2025-01-30T12:00:00Z"
    }
    """
    
    private let validToolUseMessage = """
    {
        "id": "tool-789",
        "type": "tool_use",
        "content": {
            "type": "tool_use",
            "name": "calculator",
            "input": "2 + 2"
        },
        "sessionId": "claude-session-abc123",
        "timestamp": 1706619600
    }
    """
    
    private let malformedMessage = """
    {
        "invalid": "json"
    """
    
    private let statusMessage = """
    {
        "type": "status",
        "content": "connected",
        "timestamp": "2025-01-30T12:00:00Z"
    }
    """
    
    // MARK: - Tests
    
    func testParseValidTextMessage() throws {
        // Given
        let data = validTextMessage.data(using: .utf8)!
        
        // When
        let parsed = try WebSocketMessageParser.parse(data)
        
        // Then
        XCTAssertEqual(parsed.id, "msg-123")
        XCTAssertEqual(parsed.type, .text)
        XCTAssertEqual(parsed.content, "Hello, this is a test message")
        XCTAssertEqual(parsed.sessionId, "session-456")
        XCTAssertNotNil(parsed.timestamp)
    }
    
    func testParseToolUseMessage() throws {
        // Given
        let data = validToolUseMessage.data(using: .utf8)!
        
        // When
        let parsed = try WebSocketMessageParser.parse(data)
        
        // Then
        XCTAssertEqual(parsed.id, "tool-789")
        XCTAssertEqual(parsed.type, .toolUse)
        XCTAssertTrue(parsed.content.contains("calculator"))
        XCTAssertEqual(parsed.sessionId, "claude-session-abc123")
    }
    
    func testParseMalformedMessage() {
        // Given
        let data = malformedMessage.data(using: .utf8)!
        
        // When/Then
        XCTAssertNoThrow({
            let parsed = try WebSocketMessageParser.parse(data)
            // Should still parse with defaults
            XCTAssertNotNil(parsed.id)
            XCTAssertEqual(parsed.type, .text)
        })
    }
    
    func testCreateMessage() {
        // Given
        let content = "Test message"
        let sessionId = "test-session-123"
        
        // When
        let data = WebSocketMessageParser.createMessage(
            content: content,
            type: .text,
            sessionId: sessionId
        )
        
        // Then
        XCTAssertNotNil(data)
        
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertEqual(json["content"] as? String, content)
            XCTAssertEqual(json["type"] as? String, "text")
            XCTAssertTrue((json["sessionId"] as? String)?.hasPrefix("claude-session-") ?? false)
        }
    }
    
    func testSessionIdFormatting() {
        // Test various session ID formats
        let testCases = [
            ("raw-uuid", "claude-session-"),
            ("session-12345", "claude-session-12345"),
            ("claude-session-xyz", "claude-session-xyz"),
            ("550e8400-e29b-41d4-a716-446655440000", "claude-session-550e8400-e29b-41d4-a716-446655440000")
        ]
        
        for (input, expectedPrefix) in testCases {
            let data = WebSocketMessageParser.createMessage(
                content: "Test",
                type: .text,
                sessionId: input
            )
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sessionId = json["sessionId"] as? String {
                XCTAssertTrue(sessionId.hasPrefix(expectedPrefix))
            }
        }
    }
    
    func testIsStatusMessage() {
        // Given
        let data = statusMessage.data(using: .utf8)!
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON")
            return
        }
        
        // When
        let isStatus = WebSocketMessageParser.isStatusMessage(json)
        
        // Then
        XCTAssertTrue(isStatus)
    }
    
    func testValidateMessage() {
        // Test valid message
        let validData = validTextMessage.data(using: .utf8)!
        if let json = try? JSONSerialization.jsonObject(with: validData) as? [String: Any] {
            XCTAssertTrue(WebSocketMessageParser.validateMessage(json))
        }
        
        // Test invalid message
        let invalidJson: [String: Any] = ["random": "data"]
        XCTAssertFalse(WebSocketMessageParser.validateMessage(invalidJson))
    }
    
    func testMessageWithArrayContent() throws {
        // Given
        let arrayMessage = """
        {
            "id": "array-msg",
            "type": "text",
            "content": [
                {"text": "First part"},
                {"text": "Second part"},
                {"type": "tool_use"}
            ]
        }
        """
        let data = arrayMessage.data(using: .utf8)!
        
        // When
        let parsed = try WebSocketMessageParser.parse(data)
        
        // Then
        XCTAssertTrue(parsed.content.contains("First part"))
        XCTAssertTrue(parsed.content.contains("Second part"))
        XCTAssertTrue(parsed.content.contains("[tool_use]"))
    }
    
    func testMessageToChatMessageConversion() throws {
        // Given
        let data = validTextMessage.data(using: .utf8)!
        let parsed = try WebSocketMessageParser.parse(data)
        
        // When
        let chatMessage = parsed.toChatMessage()
        
        // Then
        XCTAssertEqual(chatMessage["id"] as? String, "msg-123")
        XCTAssertEqual(chatMessage["content"] as? String, "Hello, this is a test message")
        XCTAssertNotNil(chatMessage["timestamp"])
    }
    
    // MARK: - Performance Tests
    
    func testParsingPerformance() {
        let data = validTextMessage.data(using: .utf8)!
        
        measure {
            for _ in 0..<1000 {
                _ = try? WebSocketMessageParser.parse(data)
            }
        }
    }
}