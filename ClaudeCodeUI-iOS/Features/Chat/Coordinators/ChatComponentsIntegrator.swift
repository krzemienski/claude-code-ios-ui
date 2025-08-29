//
//  ChatComponentsIntegrator.swift
//  ClaudeCodeUI
//
//  Component Integration Layer - Connects all 9 refactored chat components
//

import UIKit
import Combine

// MARK: - ChatComponentsIntegrator

/// Integrates all 9 refactored chat components into a cohesive system
@MainActor
final class ChatComponentsIntegrator: NSObject {
    
    // MARK: - Components (All 9 Validated Components)
    
    private let viewModel: ChatViewModel                    // Component 1: Core view model
    private let tableViewHandler: ChatTableViewHandler      // Component 2: Table view management
    private let inputHandler: ChatInputHandler              // Component 3: Input handling
    private let webSocketCoordinator: ChatWebSocketCoordinator  // Component 4: WebSocket coordination
    private let messageProcessor: ChatMessageProcessor      // Component 5: Message processing
    private let stateManager: ChatStateManager             // Component 6: State management
    private let attachmentHandler: ChatAttachmentHandler    // Component 7: Attachment handling
    private let streamingHandler: StreamingMessageHandler   // Component 8: Streaming messages
    
    // Component 9: Cell implementations are registered by ChatTableViewHandler
    
    // MARK: - Properties
    
    weak var viewController: UIViewController?
    weak var tableView: UITableView?
    weak var inputBar: ChatInputBar?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewController: UIViewController,
         tableView: UITableView,
         inputBar: ChatInputBar,
         webSocketManager: WebSocketProtocol,
         project: Project) {
        
        // Initialize Component 1: ChatViewModel
        self.viewModel = ChatViewModel(project: project)
        
        // Initialize Component 2: ChatTableViewHandler
        self.tableViewHandler = ChatTableViewHandler(
            tableView: tableView,
            viewModel: viewModel
        )
        
        // Initialize Component 3: ChatInputHandler
        self.inputHandler = ChatInputHandler(
            inputBar: inputBar,
            viewModel: viewModel
        )
        
        // Initialize Component 4: ChatWebSocketCoordinator
        self.webSocketCoordinator = ChatWebSocketCoordinator(
            webSocketManager: webSocketManager,
            viewModel: viewModel
        )
        
        // Initialize Component 5: ChatMessageProcessor
        self.messageProcessor = ChatMessageProcessor(viewModel: viewModel)
        
        // Initialize Component 6: ChatStateManager
        self.stateManager = ChatStateManager(viewModel: viewModel)
        
        // Initialize Component 7: ChatAttachmentHandler
        self.attachmentHandler = ChatAttachmentHandler(
            presentingViewController: viewController
        )
        
        // Initialize Component 8: StreamingMessageHandler
        self.streamingHandler = StreamingMessageHandler()
        
        // Store references
        self.viewController = viewController
        self.tableView = tableView
        self.inputBar = inputBar
        
        super.init()
        
        // Wire up components
        setupConnections()
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupConnections() {
        // Connect input handler to view controller
        inputHandler.presentingViewController = viewController
        
        // Connect attachment handler delegate
        attachmentHandler.delegate = self
        
        // Connect streaming handler to view model
        streamingHandler.viewModel = viewModel
        
        // Connect WebSocket coordinator project path
        webSocketCoordinator.projectPath = viewModel.projectPath
        
        // Connect table view handler navigation delegate
        if let navDelegate = viewController as? ChatNavigationDelegate {
            tableViewHandler.navigationDelegate = navDelegate
        }
    }
    
    private func setupBindings() {
        // Bind view model state changes
        viewModel.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleMessagesUpdate()
            }
            .store(in: &cancellables)
        
        viewModel.$isTyping
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isTyping in
                self?.handleTypingStateChange(isTyping)
            }
            .store(in: &cancellables)
        
        viewModel.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleConnectionStatusChange(status)
            }
            .store(in: &cancellables)
        
        viewModel.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Start the chat system
    func start() {
        // Initialize view model
        Task {
            await viewModel.initialize()
        }
        
        // Setup table view
        tableViewHandler.setupTableView()
        
        // Connect WebSocket
        if let url = URL(string: "ws://192.168.0.43:3004/ws") {
            let token = UserDefaults.standard.string(forKey: "authToken")
            webSocketCoordinator.connect(to: url, with: token)
        }
        
        // Update state
        stateManager.transition(to: .idle)
    }
    
    /// Stop the chat system
    func stop() {
        webSocketCoordinator.disconnect()
        streamingHandler.cleanup()
        cancellables.removeAll()
    }
    
    /// Send a message
    func sendMessage(_ content: String) {
        Task {
            await viewModel.sendMessage(content)
        }
    }
    
    /// Load messages for a session
    func loadMessages(for sessionId: String) {
        Task {
            await viewModel.loadMessages(sessionId: sessionId)
        }
    }
    
    /// Handle attachment selection
    func selectAttachment() {
        attachmentHandler.showAttachmentOptions()
    }
    
    /// Retry a failed message
    func retryMessage(_ messageId: String) {
        webSocketCoordinator.resendMessage(messageId)
    }
    
    /// Process incoming WebSocket message
    func processIncomingMessage(_ message: String) {
        // Use message processor for parsing
        if let processedMessage = messageProcessor.processMessage(message) {
            
            // Handle streaming messages
            if processedMessage.isStreaming {
                streamingHandler.handleIncomingMessage(processedMessage)
            } else {
                // Regular message
                viewModel.addMessage(processedMessage)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleMessagesUpdate() {
        // Refresh table view when messages change
        tableViewHandler.reloadData()
        
        // Scroll to bottom if near bottom
        if tableViewHandler.isNearBottom() {
            tableViewHandler.scrollToBottom()
        }
    }
    
    private func handleTypingStateChange(_ isTyping: Bool) {
        // Update UI to show/hide typing indicator
        if isTyping {
            streamingHandler.showTypingIndicator()
        } else {
            streamingHandler.hideTypingIndicator()
        }
    }
    
    private func handleConnectionStatusChange(_ status: ChatViewModel.ConnectionStatus) {
        // Update connection UI
        updateConnectionStatusUI(status)
        
        // Update input state based on connection
        let isConnected = status == .connected
        inputHandler.updateInputState(enabled: isConnected)
    }
    
    private func handleStateChange(_ state: ChatViewModel.State) {
        // Update UI based on state
        switch state {
        case .idle:
            inputHandler.clearInput()
            
        case .loading:
            inputHandler.updateInputState(enabled: false)
            
        case .sending:
            // Message is being sent
            break
            
        case .receiving:
            // Show typing indicator
            streamingHandler.showTypingIndicator()
            
        case .error(let error):
            showError(error)
        }
    }
    
    private func updateConnectionStatusUI(_ status: ChatViewModel.ConnectionStatus) {
        // This would update a connection status view in the actual UI
        print("📡 Connection status: \(status)")
    }
    
    private func showError(_ error: Error) {
        // Show error alert
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController?.present(alert, animated: true)
    }
}

// MARK: - ChatAttachmentHandlerDelegate

extension ChatComponentsIntegrator: ChatAttachmentHandlerDelegate {
    
    func chatAttachmentHandler(_ handler: ChatAttachmentHandler, didSelectAttachment attachment: ChatAttachmentHandler.Attachment) {
        // Process attachment through message processor
        let attachmentMessage = messageProcessor.createAttachmentMessage(from: attachment)
        
        // Send attachment message
        Task {
            await viewModel.sendMessage(attachmentMessage)
        }
    }
    
    func chatAttachmentHandler(_ handler: ChatAttachmentHandler, didFailWithError error: Error) {
        showError(error)
    }
}

// MARK: - ChatNavigationDelegate Extension

extension UIViewController: ChatNavigationDelegate {
    
    func navigateToURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    func navigateToUser(_ username: String) {
        // Navigate to user profile
        print("Navigate to user: \(username)")
    }
    
    func showCodePreview(_ code: String) {
        // Show code preview
        let codeVC = CodePreviewViewController(code: code)
        present(codeVC, animated: true)
    }
}

// MARK: - Helper Extensions

extension ChatMessageProcessor {
    
    /// Create attachment message from attachment
    func createAttachmentMessage(from attachment: ChatAttachmentHandler.Attachment) -> String {
        // Format attachment as message
        switch attachment.type {
        case .image:
            return "[Image: \(attachment.filename ?? "image.jpg")]"
        case .file:
            return "[File: \(attachment.filename ?? "file")]"
        case .code:
            return "```\n\(String(data: attachment.data, encoding: .utf8) ?? "")\n```"
        case .screenshot:
            return "[Screenshot: \(attachment.filename ?? "screenshot.jpg")]"
        }
    }
}

// MARK: - CodePreviewViewController (Stub)

class CodePreviewViewController: UIViewController {
    private let code: String
    
    init(code: String) {
        self.code = code
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let textView = UITextView()
        textView.text = code
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add close button
        let closeButton = UIButton(type: .close)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
}