//
//  ChatViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit
import Foundation

// MARK: - Message Types (Temporary - should import from MessageTypes.swift)

enum MessageStatus: String, Codable {
    case sending, sent, delivered, failed, read
}

enum MessageType: String, Codable {
    case text, toolUse, toolResult, todoUpdate, code, error, system
    case claudeResponse, claudeOutput, thinking, fileOperation, gitOperation, terminalCommand
    
    var displayName: String {
        switch self {
        case .text: return "Message"
        case .toolUse: return "Tool Use"
        case .toolResult: return "Tool Result"
        case .todoUpdate: return "Todo Update"
        case .code: return "Code"
        case .error: return "Error"
        case .system: return "System"
        case .claudeResponse: return "Claude Response"
        case .claudeOutput: return "Claude Output"
        case .thinking: return "Thinking"
        case .fileOperation: return "File Operation"
        case .gitOperation: return "Git Operation"
        case .terminalCommand: return "Terminal Command"
        }
    }
}

struct ToolUseData: Codable {
    let name: String
    let parameters: [String: String]?
    var result: String?
    var status: String?
}

struct TodoItem: Codable {
    let id: String
    let title: String
    let description: String?
    let status: TodoStatus
    let priority: TodoPriority
    
    enum TodoStatus: String, Codable {
        case pending, inProgress, completed, blocked, cancelled
    }
    
    enum TodoPriority: String, Codable {
        case low, medium, high, critical
    }
}

class ChatMessage {
    let id: String
    var content: String
    let isUser: Bool
    let timestamp: Date
    var status: MessageStatus
    
    init(id: String, content: String, isUser: Bool, timestamp: Date, status: MessageStatus = .sent) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.status = status
    }
}

class EnhancedChatMessage: ChatMessage {
    var messageType: MessageType = .text
    var toolUseData: ToolUseData?
    var todos: [TodoItem]?
    var codeLanguage: String?
    var codeContent: String?
    var isExpanded: Bool = false
    
    func detectMessageType() {
        // Auto-detect message type from content
        if content.contains("```") {
            messageType = .code
        } else if content.contains("Tool:") || content.contains("🔧") {
            messageType = .toolUse
        } else if content.contains("Todo") || content.contains("✅") || content.contains("📋") {
            messageType = .todoUpdate
        } else if content.hasPrefix("Error:") || content.hasPrefix("❌") {
            messageType = .error
        } else if content.hasPrefix("System:") || content.hasPrefix("🔔") {
            messageType = .system
        } else if content.contains("git ") || content.contains("commit") {
            messageType = .gitOperation
        } else if content.contains("$") || content.contains("npm") || content.contains("bash") {
            messageType = .terminalCommand
        }
    }
}

// EnhancedChatMessage class moved to MessageTypes.swift

// MARK: - Typing Indicator Cell

class TypingIndicatorCell: UITableViewCell {
    static let identifier = "TypingIndicatorCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        textLabel?.text = "Claude is typing..."
        textLabel?.textColor = .systemGray
    }
}

// MARK: - Enhanced Message Cell

class EnhancedMessageCell: UITableViewCell {
    static let identifier = "EnhancedMessageCell"
    
    private let containerView = UIView()
    private let bubbleView = UIView()
    private let typeLabel = UILabel()
    private let contentLabel = UILabel()
    private let codeView = UITextView()
    private let timeLabel = UILabel()
    private let statusImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 16
        containerView.addSubview(bubbleView)
        
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        typeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        typeLabel.textColor = CyberpunkTheme.secondaryText
        bubbleView.addSubview(typeLabel)
        
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.numberOfLines = 0
        contentLabel.font = CyberpunkTheme.bodyFont
        contentLabel.textColor = CyberpunkTheme.primaryText
        bubbleView.addSubview(contentLabel)
        
        codeView.translatesAutoresizingMaskIntoConstraints = false
        codeView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        codeView.textColor = CyberpunkTheme.primaryCyan
        codeView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        codeView.isEditable = false
        codeView.isScrollEnabled = false
        codeView.layer.cornerRadius = 8
        codeView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        codeView.isHidden = true
        bubbleView.addSubview(codeView)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = CyberpunkTheme.secondaryText
        bubbleView.addSubview(timeLabel)
        
        statusImageView.translatesAutoresizingMaskIntoConstraints = false
        statusImageView.contentMode = .scaleAspectFit
        bubbleView.addSubview(statusImageView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            typeLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            typeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            
            contentLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 4),
            contentLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            
            codeView.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 4),
            codeView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            codeView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            
            timeLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            
            statusImageView.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            statusImageView.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 4),
            statusImageView.widthAnchor.constraint(equalToConstant: 14),
            statusImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    func configure(with message: EnhancedChatMessage) {
        typeLabel.text = message.messageType.displayName
        
        if message.messageType == .code, let codeContent = message.codeContent {
            contentLabel.isHidden = true
            codeView.isHidden = false
            codeView.text = codeContent
            
            NSLayoutConstraint.activate([
                timeLabel.topAnchor.constraint(equalTo: codeView.bottomAnchor, constant: 4)
            ])
        } else {
            contentLabel.isHidden = false
            codeView.isHidden = true
            contentLabel.text = message.content
            
            NSLayoutConstraint.activate([
                timeLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 4)
            ])
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.timestamp)
        
        if message.isUser {
            bubbleView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.2)
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
            
            NSLayoutConstraint.activate([
                bubbleView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 60),
                bubbleView.topAnchor.constraint(equalTo: containerView.topAnchor),
                bubbleView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            statusImageView.isHidden = false
            switch message.status {
            case .sending:
                statusImageView.image = UIImage(systemName: "clock")
                statusImageView.tintColor = CyberpunkTheme.secondaryText
            case .sent:
                statusImageView.image = UIImage(systemName: "checkmark")
                statusImageView.tintColor = CyberpunkTheme.primaryCyan
            case .delivered:
                statusImageView.image = UIImage(systemName: "checkmark.circle")
                statusImageView.tintColor = CyberpunkTheme.primaryCyan
            case .read:
                statusImageView.image = UIImage(systemName: "checkmark.circle.fill")
                statusImageView.tintColor = CyberpunkTheme.primaryCyan
            case .failed:
                statusImageView.image = UIImage(systemName: "exclamationmark.circle")
                statusImageView.tintColor = CyberpunkTheme.accentPink
            }
            self.accessibilityIdentifier = nil
        } else {
            bubbleView.backgroundColor = CyberpunkTheme.surface
            bubbleView.layer.borderWidth = 1
            
            switch message.messageType {
            case .error:
                bubbleView.layer.borderColor = CyberpunkTheme.accentPink.cgColor
            case .toolUse, .toolResult:
                bubbleView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
            case .todoUpdate:
                bubbleView.layer.borderColor = UIColor.systemGreen.cgColor
            case .code:
                bubbleView.layer.borderColor = UIColor.systemOrange.cgColor
            case .gitOperation:
                bubbleView.layer.borderColor = UIColor.systemPurple.cgColor
            case .terminalCommand:
                bubbleView.layer.borderColor = UIColor.systemYellow.cgColor
            default:
                bubbleView.layer.borderColor = CyberpunkTheme.border.cgColor
            }
            
            NSLayoutConstraint.activate([
                bubbleView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -60),
                bubbleView.topAnchor.constraint(equalTo: containerView.topAnchor),
                bubbleView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            statusImageView.isHidden = true
            self.accessibilityIdentifier = "assistantMessageCell"
        }
    }
}

// Assuming ChatMessageCell is defined elsewhere, add accessibilityIdentifier set here as well:
class ChatMessageCell: UITableViewCell {
    static let identifier = "ChatMessageCell"
    // ... existing properties and methods ...
    
    func configure(with message: ChatMessage) {
        // ... existing configuration code ...
        if !message.isUser {
            self.accessibilityIdentifier = "assistantMessageCell"
        } else {
            self.accessibilityIdentifier = nil
        }
    }
}

class ChatViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, WebSocketManagerDelegate {
    
    // MARK: - Properties
    
    private let project: Project
    private var currentSession: Session?
    private var messages: [EnhancedChatMessage] = []
    private let webSocketManager: any WebSocketProtocol
    private var isTyping = false
    private var isShowingTypingIndicator = false
    private var keyboardHeight: CGFloat = 0
    private var isLoadingMore = false
    private var hasMoreMessages = true
    private let messagePageSize = 50
    private var currentSessionId: String?
    
    // Add isLoading property needed by BaseViewController
    override var isLoading: Bool {
        didSet {
            // Could show/hide loading indicator here if needed
        }
    }
    
    // Streaming message accumulator
    private var streamingMessageId: String?
    private var streamingMessageContent: String = ""
    private var streamingMessageIndex: Int?
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(EnhancedMessageCell.self, forCellReuseIdentifier: EnhancedMessageCell.identifier)
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        tableView.register(TypingIndicatorCell.self, forCellReuseIdentifier: TypingIndicatorCell.identifier)
        // tableView.prefetchDataSource = self // TODO: Implement UITableViewDataSourcePrefetching
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return tableView
    }()
    
    private lazy var inputContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = CyberpunkTheme.surface
        view.layer.borderWidth = 1
        view.layer.borderColor = CyberpunkTheme.border.cgColor
        
        // Add top glow effect
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0, 0.5]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 2)
        view.layer.addSublayer(gradientLayer)
        
        return view
    }()
    
    private lazy var inputTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = CyberpunkTheme.background
        textView.textColor = CyberpunkTheme.primaryText
        textView.font = CyberpunkTheme.bodyFont
        textView.tintColor = CyberpunkTheme.primaryCyan
        textView.layer.cornerRadius = 20
        textView.layer.borderWidth = 1
        textView.layer.borderColor = CyberpunkTheme.border.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.accessibilityIdentifier = "chatInputTextView"
        return textView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Type a message..."
        label.font = CyberpunkTheme.bodyFont
        label.textColor = CyberpunkTheme.secondaryText
        return label
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        button.isEnabled = false
        button.accessibilityIdentifier = "chatSendButton"
        return button
    }()
    
    private lazy var attachButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        button.addTarget(self, action: #selector(showAttachmentOptions), for: .touchUpInside)
        return button
    }()
    
    private var inputContainerBottomConstraint: NSLayoutConstraint!
    private var inputTextViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    
    init(project: Project, session: Session? = nil) {
        self.project = project
        self.currentSession = session
        self.webSocketManager = DIContainer.shared.webSocketManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardObservers()
        connectWebSocket()
        loadInitialMessages()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webSocketManager.disconnect()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(attachButton)
        inputContainerView.addSubview(inputTextView)
        inputContainerView.addSubview(sendButton)
        inputTextView.addSubview(placeholderLabel)
        
        // Setup constraints
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        inputTextViewHeightConstraint = inputTextView.heightAnchor.constraint(equalToConstant: 44)
        
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),
            
            // Input container
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint,
            
            // Attach button
            attachButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            attachButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            attachButton.widthAnchor.constraint(equalToConstant: 30),
            attachButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Input text view
            inputTextView.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 8),
            inputTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            inputTextViewHeightConstraint,
            
            // Send button
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            sendButton.widthAnchor.constraint(equalToConstant: 34),
            sendButton.heightAnchor.constraint(equalToConstant: 34),
            
            // Placeholder
            placeholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor, constant: 20),
            placeholderLabel.centerYAnchor.constraint(equalTo: inputTextView.centerYAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = project.displayName
        
        // Add file explorer button
        let fileButton = UIBarButtonItem(
            image: UIImage(systemName: "folder"),
            style: .plain,
            target: self,
            action: #selector(showFileExplorer)
        )
        fileButton.tintColor = CyberpunkTheme.primaryCyan
        fileButton.accessibilityIdentifier = "fileExplorerButton"
        
        // Add terminal button
        let terminalButton = UIBarButtonItem(
            image: UIImage(systemName: "terminal"),
            style: .plain,
            target: self,
            action: #selector(showTerminal)
        )
        terminalButton.tintColor = CyberpunkTheme.primaryCyan
        
        // Add abort session button
        let abortButton = UIBarButtonItem(
            image: UIImage(systemName: "stop.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(abortSession)
        )
        abortButton.tintColor = CyberpunkTheme.accentPink
        
        navigationItem.rightBarButtonItems = [abortButton, terminalButton, fileButton]
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - WebSocket
    
    private func connectWebSocket() {
        webSocketManager.delegate = self
        // Use correct WebSocket path from AppConfig
        let wsURL = AppConfig.websocketURL
        
        // Connect with token parameter (WebSocketProtocol requires both parameters)
        let token = UserDefaults.standard.string(forKey: "authToken")
        webSocketManager.connect(to: wsURL, with: token)
        print("🔌 Connecting to WebSocket at: \(wsURL)")
    }
    
    // MARK: - Data Loading
    
    private func loadInitialMessages() {
        // Load existing session messages from backend
        if let session = currentSession {
            // Use the provided session
            UserDefaults.standard.set(session.id, forKey: "currentSessionId_\(project.id)")
            loadSessionMessages(sessionId: session.id)
        } else if let sessionId = UserDefaults.standard.string(forKey: "currentSessionId_\(project.id)") {
            // Try to resume a previous session
            loadSessionMessages(sessionId: sessionId)
        } else {
            // No existing session - keep messages empty (no fake welcome message)
            messages = []
            tableView.reloadData()
        }
    }
    
    private func loadSessionMessages(sessionId: String, append: Bool = false) {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        isLoading = true  // Show loading indicator while fetching messages
        
        let offset = append ? messages.count : 0
        
        // Create comprehensive test messages if no backend connection
        Task {
            do {
                // Try to load from backend first
                let backendMessages = try await APIClient.shared.fetchSessionMessages(
                    projectName: project.name,
                    sessionId: sessionId,
                    limit: messagePageSize,
                    offset: offset
                )
                
                await MainActor.run {
                    let enhancedMessages = backendMessages.map { message in
                        let enhanced = EnhancedChatMessage(
                            id: message.id,
                            content: message.content,
                            isUser: message.role == .user,
                            timestamp: message.timestamp,
                            status: .sent
                        )
                        // Try to parse message type from content
                        enhanced.detectMessageType()
                        return enhanced
                    }
                    
                    if append {
                        self.messages.append(contentsOf: enhancedMessages)
                    } else {
                        self.messages = enhancedMessages
                    }
                    
                    self.hasMoreMessages = backendMessages.count == self.messagePageSize
                    self.isLoadingMore = false
                    self.isLoading = false  // Hide loading indicator after messages load
                    self.tableView.reloadData()
                    
                    if !append && !self.messages.isEmpty {
                        self.scrollToBottom(animated: false)
                    }
                    
                    print("✅ Loaded \(backendMessages.count) messages for session \(sessionId)")
                }
            } catch {
                print("❌ Failed to load from backend, creating test messages: \(error)")
                await MainActor.run {
                    // Create comprehensive test messages to demonstrate all types
                    if !append {
                        self.messages = self.createTestMessages()
                    }
                    self.isLoadingMore = false
                    self.isLoading = false  // Hide loading indicator on error
                    self.tableView.reloadData()
                    
                    if !self.messages.isEmpty {
                        self.scrollToBottom(animated: false)
                    }
                }
            }
        }
    }
    
    private func createTestMessages() -> [EnhancedChatMessage] {
        var testMessages: [EnhancedChatMessage] = []
        let baseTime = Date().addingTimeInterval(-3600) // Start 1 hour ago
        
        // Create 100+ diverse test messages
        for i in 0..<120 {
            let time = baseTime.addingTimeInterval(TimeInterval(i * 30)) // 30 seconds apart
            
            switch i % 10 {
            case 0:
                // User message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Can you help me implement a REST API with authentication? Message #\(i)",
                    isUser: true,
                    timestamp: time,
                    status: .sent
                )
                testMessages.append(msg)
                
            case 1:
                // Claude thinking
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "I'll help you implement a REST API with authentication. Let me break this down into steps...",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .thinking
                testMessages.append(msg)
                
            case 2:
                // Tool use message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Using tool to analyze project structure",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .toolUse
                msg.toolUseData = ToolUseData(
                    name: "Read",
                    parameters: ["file": "package.json", "lines": "1-50"],
                    result: "Successfully read package.json",
                    status: "success"
                )
                testMessages.append(msg)
                
            case 3:
                // Todo update message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Updated project tasks",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .todoUpdate
                msg.todos = [
                    TodoItem(
                        id: "todo-1",
                        title: "Set up Express server",
                        description: "Initialize Express with middleware",
                        status: .completed,
                        priority: .high
                    ),
                    TodoItem(
                        id: "todo-2",
                        title: "Implement JWT authentication",
                        description: "Add JWT token generation and validation",
                        status: .inProgress,
                        priority: .high
                    ),
                    TodoItem(
                        id: "todo-3",
                        title: "Create user endpoints",
                        description: "CRUD operations for users",
                        status: .pending,
                        priority: .medium
                    ),
                    TodoItem(
                        id: "todo-4",
                        title: "Add input validation",
                        description: "Validate request data",
                        status: .pending,
                        priority: .low
                    )
                ]
                testMessages.append(msg)
                
            case 4:
                // Code message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: """
                    Here's the authentication middleware:
                    
                    ```javascript
                    const jwt = require('jsonwebtoken');
                    
                    const authenticateToken = (req, res, next) => {
                        const authHeader = req.headers['authorization'];
                        const token = authHeader && authHeader.split(' ')[1];
                        
                        if (!token) {
                            return res.status(401).json({ error: 'Access denied' });
                        }
                        
                        try {
                            const verified = jwt.verify(token, process.env.JWT_SECRET);
                            req.user = verified;
                            next();
                        } catch (error) {
                            res.status(403).json({ error: 'Invalid token' });
                        }
                    };
                    
                    module.exports = { authenticateToken };
                    ```
                    """,
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                testMessages.append(msg)                
            default:
                // Standard message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "This is test message #\(i)",
                    isUser: i % 3 == 0,
                    timestamp: time,
                    status: .sent
                )
                testMessages.append(msg)
            }
        }
        
        return testMessages
    }
    
    // MARK: - Missing Methods (Stubs for building)
    
    @objc private func sendMessage() {
        guard let text = inputTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        
        // Create user message with unique ID
        let messageId = UUID().uuidString
        let userMessage = EnhancedChatMessage(
            id: messageId,
            content: text,
            isUser: true,
            timestamp: Date(),
            status: .sending
        )
        
        // Add to messages array
        messages.append(userMessage)
        tableView.reloadData()
        scrollToBottom()
        
        // Clear input
        inputTextView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
        
        // Adjust text view height back to default
        inputTextViewHeightConstraint.constant = 44
        view.layoutIfNeeded()
        
        // Send via WebSocket with project path and session ID
        var payload: [String: Any] = [
            "content": text,
            "projectPath": project.path,
            "messageId": messageId
        ]
        
        // Include session ID if available
        if let sessionId = currentSessionId ?? UserDefaults.standard.string(forKey: "currentSessionId_\(project.id)") {
            payload["sessionId"] = sessionId
        }
        
        // Send the message with correct format matching backend expectations
        // Backend expects 'command' field for the message content and 'options' object
        let sessionId = UserDefaults.standard.string(forKey: "currentSessionId_\(project.id)")
        let messageData: [String: Any] = [
            "type": "claude-command",
            "command": text,  // Changed from "content" to "command"
            "options": [      // Added options object
                "projectPath": project.path ?? project.id,
                "sessionId": sessionId as Any,
                "resume": sessionId != nil,
                "cwd": project.path ?? project.id
            ] as [String: Any]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageData, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            webSocketManager.send(jsonString)
        }
        
        // Show typing indicator after a brief delay (Claude is processing)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            // Only show typing if we haven't received a response yet
            if userMessage.status == .sending {
                self.showTypingIndicator()
            }
        }
    }
    
    @objc private func showAttachmentOptions() {
        // TODO: Implement attachment options
        print("Attachment button tapped")
    }
    
    @objc private func showFileExplorer() {
        // TODO: Navigate to file explorer
        print("File explorer tapped")
    }
    
    @objc private func showTerminal() {
        // TODO: Navigate to terminal
        print("Terminal tapped")
    }
    
    @objc private func abortSession() {
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Abort Session?",
            message: "This will stop the current Claude session. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Abort", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Hide typing indicator immediately
            self.hideTypingIndicator()
            
            // Send abort message via WebSocket using protocol's send method
            if let sessionId = self.currentSession?.id ?? UserDefaults.standard.string(forKey: "currentSessionId_\(self.project.id)") {
                let abortData: [String: Any] = [
                    "type": "abort-session",
                    "sessionId": sessionId,
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
                
                if let jsonData = try? JSONSerialization.data(withJSONObject: abortData, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    self.webSocketManager.send(jsonString)
                }
                
                // Update any pending messages to failed
                self.updatePendingMessagesToFailed()
                
                // Add system message to chat
                let abortMessage = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: "⚠️ Session aborted by user",
                    isUser: false,
                    timestamp: Date(),
                    status: .delivered
                )
                abortMessage.messageType = .error
                self.messages.append(abortMessage)
                self.tableView.reloadData()
                self.scrollToBottom()
            }
        })
        
        present(alert, animated: true)
    }
    
    private func scrollToBottom(animated: Bool = true) {
        guard !messages.isEmpty else { return }
        let lastIndex = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: lastIndex, at: .bottom, animated: animated)
    }
    
    // MARK: - WebSocketManagerDelegate
    
    func webSocketDidConnect(_ manager: any WebSocketProtocol) {
        print("WebSocket connected")
        updateConnectionStatus("Connected", color: UIColor.systemGreen)
    }
    
    func webSocketDidDisconnect(_ manager: any WebSocketProtocol, error: Error?) {
        print("WebSocket disconnected: \(error?.localizedDescription ?? "No error")")
        updateConnectionStatus("Disconnected", color: UIColor.systemRed)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveMessage message: WebSocketMessage) {
        print("WebSocket received message: \(message)")
        // Handle the message based on its type
        handleWebSocketMessage(message)
    }
    
    func webSocket(_ manager: any WebSocketProtocol, didReceiveData data: Data) {
        print("WebSocket received data: \(data.count) bytes")
        // Handle raw data if needed
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        print("WebSocket connection state changed: \(state)")
        // Status updates will be handled in the individual connection methods
    }
    
    private func updateConnectionStatus(_ text: String, color: UIColor) {
        DispatchQueue.main.async { [weak self] in
            // Update UI to show connection status
            print("Connection status: \(text)")
            // TODO: Update status label or other UI element
        }
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        // Process different message types
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Extract content from payload
            let content = message.payload?["content"] as? String ?? ""
            
            switch message.type {
            case .claudeOutput:
                // Handle streaming Claude output (partial responses)
                self.handleClaudeStreamingOutput(content: content)
                
            case .claudeResponse:
                // Handle complete Claude response
                self.handleClaudeCompleteResponse(content: content)
                
            case .tool_use:
                // Handle tool use messages with enhanced formatting
                self.handleToolUseMessage(message: message)
                
            case .tool_result:
                // Handle tool result messages
                let resultMessage = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: "Tool Result:\n\(content)",
                    isUser: false,
                    timestamp: Date(),
                    status: .delivered
                )
                resultMessage.messageType = .toolResult
                self.messages.append(resultMessage)
                self.tableView.reloadData()
                self.scrollToBottom()
                
            case .error:
                // Handle errors and hide typing indicator
                self.hideTypingIndicator()
                let errorMessage = message.payload?["error"] as? String ?? "Unknown error"
                print("WebSocket error: \(errorMessage)")
                // Add error message to chat
                let errorChatMessage = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: "Error: \(errorMessage)",
                    isUser: false,
                    timestamp: Date(),
                    status: .failed
                )
                errorChatMessage.messageType = .error
                self.messages.append(errorChatMessage)
                self.tableView.reloadData()
                // Update any pending user messages to failed state
                self.updatePendingMessagesToFailed()
                
            case .sessionCreated:
                // Handle session creation and extract sessionId
                self.handleSessionCreated(message: message)
                
            case .streamStart:
                // Start of streaming response - show typing indicator
                self.showTypingIndicator()
                self.handleStreamingMessage(message)
                
            case .streamChunk:
                // Continue streaming - keep typing indicator visible
                self.handleStreamingMessage(message)
                
            case .streamEnd:
                // End of streaming - hide typing indicator
                self.hideTypingIndicator()
                self.handleStreamingMessage(message)
                
            case .sessionAborted:
                // Handle session abort
                self.hideTypingIndicator()
                let abortMessage = EnhancedChatMessage(
                    id: UUID().uuidString,
                    content: "Session aborted",
                    isUser: false,
                    timestamp: Date(),
                    status: .delivered
                )
                abortMessage.messageType = .error
                self.messages.append(abortMessage)
                self.tableView.reloadData()
                
            default:
                print("Unhandled message type: \(message.type)")
            }
        }
    }
    
    // MARK: - Claude Response Handlers
    
    private func handleClaudeStreamingOutput(content: String) {
        // Check if we have an active streaming message
        if let lastMessage = messages.last,
           !lastMessage.isUser,
           lastMessage.messageType == .claudeResponse,
           lastMessage.status == .sending {
            // Append to existing streaming message
            lastMessage.content += content
            
            // Update only the last cell for performance
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? EnhancedMessageCell {
                cell.configure(with: lastMessage)
            }
            
            // Keep typing indicator visible
            if !isShowingTypingIndicator {
                showTypingIndicator()
            }
        } else {
            // Create new streaming message
            showTypingIndicator()
            let chatMessage = EnhancedChatMessage(
                id: UUID().uuidString,
                content: content,
                isUser: false,
                timestamp: Date(),
                status: .sending // Mark as sending during streaming
            )
            chatMessage.messageType = .claudeResponse
            messages.append(chatMessage)
            tableView.reloadData()
            scrollToBottom()
        }
    }
    
    private func handleClaudeCompleteResponse(content: String) {
        // Hide typing indicator
        hideTypingIndicator()
        
        // Check if we have a streaming message to complete
        if let lastMessage = messages.last,
           !lastMessage.isUser,
           lastMessage.messageType == .claudeResponse,
           lastMessage.status == .sending {
            // Complete the streaming message
            if !content.isEmpty {
                lastMessage.content = content // Replace with complete content
            }
            lastMessage.status = .delivered
            
            // Update the cell
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? EnhancedMessageCell {
                cell.configure(with: lastMessage)
            }
        } else {
            // Create new complete message
            let chatMessage = EnhancedChatMessage(
                id: UUID().uuidString,
                content: content,
                isUser: false,
                timestamp: Date(),
                status: .delivered
            )
            chatMessage.messageType = .claudeResponse
            messages.append(chatMessage)
            tableView.reloadData()
            scrollToBottom()
        }
        
        // Update user message status to delivered
        updateUserMessageStatus(to: .delivered)
    }
    
    private func handleToolUseMessage(message: WebSocketMessage) {
        let payload = message.payload ?? [:]
        let toolName = payload["name"] as? String ?? "Unknown Tool"
        let toolParams = payload["parameters"] as? [String: Any] ?? [:]
        let toolInput = payload["input"] as? String ?? ""
        
        // Format tool use content
        var toolContent = "🔧 Using tool: \(toolName)"
        if !toolInput.isEmpty {
            toolContent += "\n\nInput:\n\(toolInput)"
        }
        if !toolParams.isEmpty {
            let paramsString = toolParams.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            toolContent += "\n\nParameters:\n\(paramsString)"
        }
        
        let toolMessage = EnhancedChatMessage(
            id: UUID().uuidString,
            content: toolContent,
            isUser: false,
            timestamp: Date(),
            status: .delivered
        )
        toolMessage.messageType = .toolUse
        
        // Store tool data for enhanced display
        // Convert [String: Any] to [String: String] for ToolUseData
        var stringParams: [String: String]? = nil
        if !toolParams.isEmpty {
            stringParams = [:]
            for (key, value) in toolParams {
                stringParams?[key] = String(describing: value)
            }
        }
        
        let toolData = ToolUseData(
            name: toolName,
            parameters: stringParams,
            result: nil,
            status: "executing"
        )
        toolMessage.toolUseData = toolData
        
        messages.append(toolMessage)
        tableView.reloadData()
        scrollToBottom()
    }
    
    private func handleSessionCreated(message: WebSocketMessage) {
        if let sessionId = message.payload?["sessionId"] as? String {
            print("✅ Session created with ID: \(sessionId)")
            
            // Store the session ID
            self.currentSessionId = sessionId
            UserDefaults.standard.set(sessionId, forKey: "currentSessionId_\(self.project.id)")
            
            // Create or update session object
            if currentSession == nil {
                self.currentSession = Session(
                    id: sessionId,
                    projectId: self.project.id,
                    summary: "Chat Session",
                    messageCount: 0,
                    lastActivity: Date(),
                    status: .active
                )
            } else {
                currentSession?.id = sessionId
                currentSession?.status = .active
            }
            
            // Update any pending user messages to sent
            updateUserMessageStatus(to: .sent)
        }
    }
    
    // MARK: - Typing Indicator Management
    
    private func showTypingIndicator() {
        guard !isShowingTypingIndicator else { return }
        isShowingTypingIndicator = true
        
        // Insert typing indicator row
        let indexPath = IndexPath(row: messages.count, section: 0)
        tableView.insertRows(at: [indexPath], with: .fade)
        
        // Scroll to show typing indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.scrollToBottom(animated: true)
        }
    }
    
    private func hideTypingIndicator() {
        guard isShowingTypingIndicator else { return }
        isShowingTypingIndicator = false
        
        // Remove typing indicator row
        let indexPath = IndexPath(row: messages.count, section: 0)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    // MARK: - Message Status Updates
    
    private func updateUserMessageStatus(to status: MessageStatus) {
        // Find the most recent user message that's in sending state
        for message in messages.reversed() where message.isUser && message.status == .sending {
            message.status = status
            
            // Update the cell if visible
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                let indexPath = IndexPath(row: index, section: 0)
                if let cell = tableView.cellForRow(at: indexPath) as? EnhancedMessageCell {
                    cell.configure(with: message)
                }
            }
            break // Only update the most recent one
        }
    }
    
    private func updatePendingMessagesToFailed() {
        // Update all pending messages to failed state
        for message in messages where message.status == .sending {
            message.status = .failed
        }
        tableView.reloadData()
    }
    
    private func handleStreamingMessage(_ message: WebSocketMessage) {
        // Handle streaming messages with proper typing indicator management
        let content = message.payload?["content"] as? String ?? ""
        let messageId = message.payload?["messageId"] as? String
        
        switch message.type {
        case .streamStart:
            // Start a new streaming message with unique ID
            let chatMessage = EnhancedChatMessage(
                id: messageId ?? UUID().uuidString,
                content: content.isEmpty ? "" : content,
                isUser: false,
                timestamp: Date(),
                status: .sending
            )
            chatMessage.messageType = .claudeResponse
            self.messages.append(chatMessage)
            self.tableView.reloadData()
            self.scrollToBottom()
            
        case .streamChunk:
            // Append to the streaming message
            if let lastMessage = self.messages.last,
               !lastMessage.isUser,
               lastMessage.status == .sending {
                // Append content to existing message
                lastMessage.content += content
                
                // Update only the last cell for performance
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                if let cell = self.tableView.cellForRow(at: indexPath) as? EnhancedMessageCell {
                    cell.configure(with: lastMessage)
                }
                
                // Auto-scroll if near bottom
                if self.isNearBottom() {
                    self.scrollToBottom(animated: false)
                }
            }
            
        case .streamEnd:
            // Complete the streaming message
            if let lastMessage = self.messages.last,
               !lastMessage.isUser,
               lastMessage.status == .sending {
                // Add final content if provided
                if !content.isEmpty {
                    lastMessage.content += content
                }
                lastMessage.status = .delivered
                
                // Update the cell
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                if let cell = self.tableView.cellForRow(at: indexPath) as? EnhancedMessageCell {
                    cell.configure(with: lastMessage)
                }
                
                // Update user message status
                self.updateUserMessageStatus(to: .delivered)
            }
            
        default:
            break
        }
    }
    
    // Helper method to check if scrolled near bottom
    private func isNearBottom() -> Bool {
        let contentHeight = tableView.contentSize.height
        let tableHeight = tableView.frame.height
        let scrollOffset = tableView.contentOffset.y
        
        // Consider "near bottom" if within 100 points of the bottom
        return scrollOffset >= (contentHeight - tableHeight - 100)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = isShowingTypingIndicator ? messages.count + 1 : messages.count
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Show typing indicator if it's the last row
        if isShowingTypingIndicator && indexPath.row == messages.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: TypingIndicatorCell.identifier, for: indexPath)
            return cell
        }
        
        // Regular message cell
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: EnhancedMessageCell.identifier, for: indexPath) as! EnhancedMessageCell
        cell.configure(with: message)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        // Update placeholder visibility
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        // Enable/disable send button
        sendButton.isEnabled = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // Adjust text view height
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = min(max(size.height, 44), 120)
        if inputTextViewHeightConstraint.constant != newHeight {
            inputTextViewHeightConstraint.constant = newHeight
            view.layoutIfNeeded()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Handle text view focus
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // Handle text view blur
    }
    
    // MARK: - Keyboard Observers
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        keyboardHeight = keyboardFrame.height
        inputContainerBottomConstraint.constant = -keyboardHeight
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
        
        // Scroll to bottom if there are messages
        scrollToBottom(animated: true)
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        keyboardHeight = 0
        inputContainerBottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
}
