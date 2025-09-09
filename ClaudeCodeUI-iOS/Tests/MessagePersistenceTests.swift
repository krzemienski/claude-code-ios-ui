import XCTest
@testable import ClaudeCodeUI

/// Test suite for validating message persistence across app restarts
/// Tests the CRITICAL issue: Messages not persisting after app restart
class MessagePersistenceTests: XCTestCase {
    
    var chatViewModel: ChatViewModel!
    var messageStore: MessageStore!
    var testSession: ChatSession!
    
    override func setUp() {
        super.setUp()
        
        // Initialize test components
        chatViewModel = ChatViewModel()
        messageStore = MessageStore()
        testSession = ChatSession(
            id: "test-session-123",
            name: "Test Session",
            timestamp: Date(),
            projectContext: "Test Project"
        )
    }
    
    override func tearDown() {
        // Clean up test data
        messageStore.clearAllMessages()
        chatViewModel = nil
        messageStore = nil
        testSession = nil
        super.tearDown()
    }
    
    // MARK: - Critical Test: Message Persistence
    
    /// Test Step 1-2: Send initial message and verify storage
    func testMessagePersistenceOnSend() {
        // Arrange
        let testMessage = ChatMessage(
            id: UUID().uuidString,
            content: "Hello, test message",
            isUser: true,
            timestamp: Date(),
            sessionId: testSession.id
        )
        
        let expectation = self.expectation(description: "Message should be persisted")
        
        // Act
        chatViewModel.sendMessage(testMessage) { success in
            XCTAssertTrue(success, "Message should be sent successfully")
            
            // Assert - Verify message is stored
            let storedMessages = self.messageStore.loadMessages(for: self.testSession.id)
            XCTAssertEqual(storedMessages.count, 1, "Should have exactly 1 message stored")
            XCTAssertEqual(storedMessages.first?.content, testMessage.content)
            XCTAssertEqual(storedMessages.first?.id, testMessage.id)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    /// Test Step 11-12: Verify message persistence after app restart
    func testMessagePersistenceAfterRestart() {
        // Arrange - Store messages before "restart"
        let message1 = ChatMessage(
            id: "msg-1",
            content: "First message",
            isUser: true,
            timestamp: Date(),
            sessionId: testSession.id
        )
        
        let message2 = ChatMessage(
            id: "msg-2",
            content: "AI response",
            isUser: false,
            timestamp: Date(),
            sessionId: testSession.id
        )
        
        messageStore.saveMessage(message1)
        messageStore.saveMessage(message2)
        
        // Act - Simulate app restart by recreating components
        chatViewModel = nil
        chatViewModel = ChatViewModel()
        chatViewModel.loadSession(testSession)
        
        // Assert - Messages should be restored
        let loadedMessages = chatViewModel.messages
        
        XCTAssertEqual(loadedMessages.count, 2, "❌ CRITICAL: Messages not persisting after restart")
        XCTAssertEqual(loadedMessages[0].id, message1.id)
        XCTAssertEqual(loadedMessages[1].id, message2.id)
        XCTAssertEqual(loadedMessages[0].content, message1.content)
        XCTAssertEqual(loadedMessages[1].content, message2.content)
    }
    
    /// Test message persistence with large conversation
    func testLargeConversationPersistence() {
        // Arrange - Create 50 messages
        var messages: [ChatMessage] = []
        for i in 0..<50 {
            let message = ChatMessage(
                id: "msg-\(i)",
                content: "Message \(i)",
                isUser: i % 2 == 0,
                timestamp: Date().addingTimeInterval(Double(i)),
                sessionId: testSession.id
            )
            messages.append(message)
            messageStore.saveMessage(message)
        }
        
        // Act - Reload
        chatViewModel.loadSession(testSession)
        
        // Assert
        XCTAssertEqual(chatViewModel.messages.count, 50, "All 50 messages should be loaded")
        
        // Verify order is preserved
        for (index, message) in chatViewModel.messages.enumerated() {
            XCTAssertEqual(message.id, "msg-\(index)")
        }
    }
    
    /// Test persistence with special characters and emojis
    func testSpecialCharacterPersistence() {
        // Arrange
        let specialMessage = ChatMessage(
            id: "special-msg",
            content: "Test 😀 emoji & special <chars> \"quotes\" 'apostrophe' \n newlines",
            isUser: true,
            timestamp: Date(),
            sessionId: testSession.id
        )
        
        messageStore.saveMessage(specialMessage)
        
        // Act
        chatViewModel = ChatViewModel()
        chatViewModel.loadSession(testSession)
        
        // Assert
        let loaded = chatViewModel.messages.first
        XCTAssertEqual(loaded?.content, specialMessage.content, "Special characters should be preserved")
    }
    
    /// Test concurrent message persistence
    func testConcurrentMessagePersistence() {
        let expectation = self.expectation(description: "Concurrent messages should be persisted")
        let dispatchGroup = DispatchGroup()
        
        // Act - Send 10 messages concurrently
        for i in 0..<10 {
            dispatchGroup.enter()
            
            DispatchQueue.global().async {
                let message = ChatMessage(
                    id: "concurrent-\(i)",
                    content: "Concurrent message \(i)",
                    isUser: true,
                    timestamp: Date(),
                    sessionId: self.testSession.id
                )
                
                self.messageStore.saveMessage(message)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Assert
            let savedMessages = self.messageStore.loadMessages(for: self.testSession.id)
            XCTAssertEqual(savedMessages.count, 10, "All concurrent messages should be saved")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0)
    }
    
    /// Performance test for message loading
    func testMessageLoadingPerformance() {
        // Arrange - Store 1000 messages
        for i in 0..<1000 {
            let message = ChatMessage(
                id: "perf-\(i)",
                content: String(repeating: "Test content ", count: 10),
                isUser: i % 2 == 0,
                timestamp: Date(),
                sessionId: testSession.id
            )
            messageStore.saveMessage(message)
        }
        
        // Measure loading performance
        measure {
            chatViewModel.loadSession(testSession)
            XCTAssertEqual(chatViewModel.messages.count, 1000)
        }
        
        // Assert loading completes under 2 seconds
        let startTime = Date()
        chatViewModel.loadSession(testSession)
        let loadTime = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(loadTime, 2.0, "Messages should load in under 2 seconds")
    }
}

// MARK: - Mock Message Store for Testing

class MessageStore {
    private var messages: [String: [ChatMessage]] = [:]
    private let queue = DispatchQueue(label: "com.test.messagestore", attributes: .concurrent)
    
    func saveMessage(_ message: ChatMessage) {
        queue.async(flags: .barrier) {
            if self.messages[message.sessionId] == nil {
                self.messages[message.sessionId] = []
            }
            self.messages[message.sessionId]?.append(message)
        }
    }
    
    func loadMessages(for sessionId: String) -> [ChatMessage] {
        return queue.sync {
            return messages[sessionId] ?? []
        }
    }
    
    func clearAllMessages() {
        queue.async(flags: .barrier) {
            self.messages.removeAll()
        }
    }
}

// MARK: - Chat Message Model for Testing

struct ChatMessage: Codable, Equatable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
    let sessionId: String
}

// MARK: - Chat Session Model

struct ChatSession {
    let id: String
    let name: String
    let timestamp: Date
    let projectContext: String
}