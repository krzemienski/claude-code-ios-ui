//
//  ChatIntegrationTests.swift
//  ClaudeCodeUI
//
//  Integration tests for refactored chat components
//

import XCTest
import Combine
@testable import ClaudeCodeUI

// MARK: - ChatIntegrationTests

final class ChatIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: ChatViewController!
    private var viewModel: ChatViewModel!
    private var mockWebSocketService: MockWebSocketService!
    private var mockAPIClient: MockAPIClient!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup/Teardown
    
    override func setUp() {
        super.setUp()
        
        cancellables = Set<AnyCancellable>()
        
        // Initialize mocks
        mockWebSocketService = MockWebSocketService()
        mockAPIClient = MockAPIClient()
        
        // Initialize view model with mocks
        viewModel = ChatViewModel()
        viewModel.webSocketService = mockWebSocketService
        viewModel.apiClient = mockAPIClient
        
        // Initialize view controller
        sut = ChatViewController()
        sut.projectPath = "/test/project"
        sut.sessionId = "test-session-123"
        
        // Load view
        sut.loadViewIfNeeded()
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        viewModel = nil
        mockWebSocketService = nil
        mockAPIClient = nil
        
        super.tearDown()
    }
    
    // MARK: - Component Integration Tests
    
    func testAllComponentsInitializeCorrectly() {
        // Given
        let expectation = XCTestExpectation(description: "Components initialized")
        
        // When
        sut.viewDidLoad()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Verify all components are initialized
            XCTAssertNotNil(self.sut.tableView)
            XCTAssertNotNil(self.sut.inputBar)
            XCTAssertEqual(self.sut.tableView.delegate != nil, true)
            XCTAssertEqual(self.sut.tableView.dataSource != nil, true)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testViewModelIntegration() {
        // Given
        let testMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: "Test message",
            timestamp: Date(),
            status: .sending
        )
        
        // When
        viewModel.messages.append(testMessage)
        
        // Then
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.content, "Test message")
    }
    
    func testTableViewHandlerDisplaysMessages() {
        // Given
        let messages = [
            ChatMessage(id: "1", role: .user, content: "Hello", timestamp: Date(), status: .delivered),
            ChatMessage(id: "2", role: .assistant, content: "Hi there!", timestamp: Date(), status: .delivered)
        ]
        
        // When
        viewModel.messages = messages
        sut.tableView.reloadData()
        
        // Then
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 2)
    }
    
    func testInputHandlerSendsMessage() {
        // Given
        let expectation = XCTestExpectation(description: "Message sent")
        let testText = "Test input message"
        
        // Setup mock response
        mockWebSocketService.onSendMessage = { message in
            XCTAssertEqual(message.content, testText)
            expectation.fulfill()
        }
        
        // When
        sut.inputBar.textView.text = testText
        sut.inputBar.sendButton.sendActions(for: .touchUpInside)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testWebSocketCoordinatorHandlesConnection() {
        // Given
        let expectation = XCTestExpectation(description: "WebSocket connected")
        
        // When
        mockWebSocketService.simulateConnection()
        
        // Then
        viewModel.$connectionStatus
            .sink { status in
                if status == .connected {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testStreamingMessageHandlerUpdatesContent() {
        // Given
        let messageId = "streaming-123"
        let chunks = ["Hello", " world", "!"]
        let streamingHandler = StreamingMessageHandler(
            viewModel: viewModel,
            tableView: sut.tableView
        )
        
        // When
        streamingHandler.startStreaming(messageId: messageId)
        chunks.forEach { chunk in
            streamingHandler.addChunk(chunk, to: messageId)
        }
        streamingHandler.completeStreaming(messageId: messageId)
        
        // Then
        let content = streamingHandler.getStreamingContent(for: messageId)
        XCTAssertEqual(content, "Hello world!")
    }
    
    func testAttachmentHandlerProcessesFiles() {
        // Given
        let expectation = XCTestExpectation(description: "Attachment processed")
        let attachmentHandler = ChatAttachmentHandler()
        attachmentHandler.delegate = MockAttachmentDelegate { attachment in
            XCTAssertNotNil(attachment)
            expectation.fulfill()
        }
        
        // When
        let testData = Data("test file content".utf8)
        attachmentHandler.processAttachment(data: testData, type: .file)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMessageCellConfiguration() {
        // Given
        let cell = ChatMessageCell(style: .default, reuseIdentifier: "test")
        let message = ChatMessage(
            id: "test",
            role: .assistant,
            content: "**Bold** text with `code`",
            timestamp: Date(),
            status: .delivered
        )
        
        // When
        cell.configure(with: message)
        
        // Then
        XCTAssertNotNil(cell.messageLabel.attributedText)
        XCTAssertTrue(cell.messageLabel.attributedText!.string.contains("Bold"))
    }
    
    func testTypingIndicatorAnimation() {
        // Given
        let cell = ChatTypingIndicatorCell(style: .default, reuseIdentifier: "typing")
        
        // When
        cell.startAnimating()
        
        // Then
        XCTAssertTrue(cell.isAnimating)
        
        // Cleanup
        cell.stopAnimating()
        XCTAssertFalse(cell.isAnimating)
    }
    
    func testDateHeaderFormatting() {
        // Given
        let headerView = ChatDateHeaderView(reuseIdentifier: "date")
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // When/Then
        headerView.configure(with: today)
        XCTAssertEqual(headerView.dateLabel.text, "Today")
        
        headerView.configure(with: yesterday)
        XCTAssertEqual(headerView.dateLabel.text, "Yesterday")
    }
    
    // MARK: - Integration Flow Tests
    
    func testCompleteMessageFlow() {
        // Given
        let expectation = XCTestExpectation(description: "Complete flow")
        var steps = [String]()
        
        // Setup observers
        viewModel.$messages
            .sink { messages in
                if !messages.isEmpty {
                    steps.append("messages_updated")
                }
            }
            .store(in: &cancellables)
        
        viewModel.$connectionStatus
            .sink { status in
                if status == .connected {
                    steps.append("connected")
                }
            }
            .store(in: &cancellables)
        
        // When
        // 1. Connect WebSocket
        mockWebSocketService.simulateConnection()
        
        // 2. Send message
        let userMessage = ChatMessage(
            id: "user-1",
            role: .user,
            content: "Hello Claude",
            timestamp: Date(),
            status: .sending
        )
        viewModel.sendMessage(userMessage)
        
        // 3. Receive response
        let assistantMessage = ChatMessage(
            id: "assistant-1",
            role: .assistant,
            content: "Hello! How can I help?",
            timestamp: Date(),
            status: .delivered
        )
        mockWebSocketService.simulateIncomingMessage(assistantMessage)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(steps.contains("connected"))
            XCTAssertTrue(steps.contains("messages_updated"))
            XCTAssertEqual(self.viewModel.messages.count, 2)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testErrorHandlingFlow() {
        // Given
        let expectation = XCTestExpectation(description: "Error handled")
        
        // When
        let error = ChatError.connectionFailed
        viewModel.handleError(error)
        
        // Then
        viewModel.$lastError
            .sink { error in
                if error != nil {
                    XCTAssertEqual(self.viewModel.connectionStatus, .disconnected)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testReconnectionFlow() {
        // Given
        let expectation = XCTestExpectation(description: "Reconnected")
        var connectionAttempts = 0
        
        mockWebSocketService.onConnect = {
            connectionAttempts += 1
            if connectionAttempts == 2 {
                expectation.fulfill()
            }
        }
        
        // When
        mockWebSocketService.simulateConnection()
        mockWebSocketService.simulateDisconnection()
        mockWebSocketService.simulateConnection() // Auto-reconnect
        
        // Then
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(connectionAttempts, 2)
    }
    
    // MARK: - Performance Tests
    
    func testLargeMessageListPerformance() {
        // Given
        let messages = (0..<1000).map { index in
            ChatMessage(
                id: "\(index)",
                role: index % 2 == 0 ? .user : .assistant,
                content: "Message \(index)",
                timestamp: Date(),
                status: .delivered
            )
        }
        
        // Measure
        measure {
            viewModel.messages = messages
            sut.tableView.reloadData()
        }
    }
    
    func testStreamingPerformance() {
        let streamingHandler = StreamingMessageHandler(
            viewModel: viewModel,
            tableView: sut.tableView
        )
        
        measure {
            let messageId = UUID().uuidString
            streamingHandler.startStreaming(messageId: messageId)
            
            for _ in 0..<100 {
                streamingHandler.addChunk("Lorem ipsum ", to: messageId)
            }
            
            streamingHandler.completeStreaming(messageId: messageId)
        }
    }
}

// MARK: - Mock Objects

class MockWebSocketService: WebSocketServiceProtocol {
    var onSendMessage: ((ChatMessage) -> Void)?
    var onConnect: (() -> Void)?
    private var messageHandler: ((ChatMessage) -> Void)?
    
    func connect() {
        onConnect?()
    }
    
    func disconnect() {
        // Mock disconnect
    }
    
    func sendMessage(_ message: ChatMessage) {
        onSendMessage?(message)
    }
    
    func simulateConnection() {
        // Simulate successful connection
    }
    
    func simulateDisconnection() {
        // Simulate disconnection
    }
    
    func simulateIncomingMessage(_ message: ChatMessage) {
        messageHandler?(message)
    }
    
    func onMessage(_ handler: @escaping (ChatMessage) -> Void) {
        messageHandler = handler
    }
}

class MockAPIClient: APIClientProtocol {
    func loadSessionMessages(_ sessionId: String) async throws -> [ChatMessage] {
        return [
            ChatMessage(
                id: "mock-1",
                role: .user,
                content: "Mock message",
                timestamp: Date(),
                status: .delivered
            )
        ]
    }
}

struct MockAttachmentDelegate: ChatAttachmentDelegate {
    let onAttachment: (ChatAttachment) -> Void
    
    func chatAttachmentHandler(_ handler: ChatAttachmentHandler, didSelectAttachment attachment: ChatAttachment) {
        onAttachment(attachment)
    }
}

// MARK: - Test Helpers

extension ChatViewController {
    var isAnimating: Bool {
        return false // Simplified for testing
    }
}

extension ChatTypingIndicatorCell {
    var isAnimating: Bool {
        // Check if animations are running
        return layer.animationKeys()?.isEmpty == false
    }
}

extension ChatDateHeaderView {
    var dateLabel: UILabel {
        // Access private label for testing
        return value(forKey: "dateLabel") as! UILabel
    }
}

// MARK: - Protocol Definitions

protocol WebSocketServiceProtocol {
    func connect()
    func disconnect()
    func sendMessage(_ message: ChatMessage)
}

protocol APIClientProtocol {
    func loadSessionMessages(_ sessionId: String) async throws -> [ChatMessage]
}

enum ChatError: Error {
    case connectionFailed
    case messageSendFailed
    case invalidData
}

struct ChatAttachment {
    let id: String
    let type: AttachmentType
    let data: Data
    
    enum AttachmentType {
        case image
        case file
        case code
    }
}

protocol ChatAttachmentDelegate: AnyObject {
    func chatAttachmentHandler(_ handler: ChatAttachmentHandler, didSelectAttachment attachment: ChatAttachment)
}

class ChatAttachmentHandler {
    weak var delegate: ChatAttachmentDelegate?
    
    func processAttachment(data: Data, type: ChatAttachment.AttachmentType) {
        let attachment = ChatAttachment(
            id: UUID().uuidString,
            type: type,
            data: data
        )
        delegate?.chatAttachmentHandler(self, didSelectAttachment: attachment)
    }
}