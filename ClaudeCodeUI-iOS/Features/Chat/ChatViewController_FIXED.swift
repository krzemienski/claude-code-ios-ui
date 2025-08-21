//
//  ChatViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//  FIXED VERSION: January 21, 2025 - 3:15 PM
//  Fixes Applied:
//  1. Removed duplicate type definitions (now imports MessageTypes)
//  2. Improved message filtering logic
//  3. Added comprehensive timestamped logging
//  4. Enhanced message status tracking
//  5. Improved typing indicator management
//

import UIKit
import Foundation
import PhotosUI

// MARK: - Import proper type definitions from MessageTypes.swift
// FIX #1: Removed duplicate type definitions (lines 13-78 in original)
// Now using canonical definitions from MessageTypes.swift

// MARK: - ChatViewController

class ChatViewController: UIViewController {
    
    // MARK: - Timestamp Logging Helper
    private func logDebug(_ message: String, category: String = "ChatVC", level: String = "DEBUG") {
        let timestamp = Date().timeIntervalSince1970
        let formattedTime = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(timestamp)] [\(formattedTime)] [\(level)] [\(category)] \(message)")
    }
    
    // MARK: - Properties
    
    private let project: Project
    private let sessionId: String?
    private var messages: [EnhancedChatMessage] = []
    private var streamingMessageHandler = StreamingMessageHandler()
    private var webSocketManager: WebSocketManager?
    private var isTypingIndicatorVisible = false
    private var scrollWorkItem: DispatchWorkItem?
    private var messageStatusTimers: [String: Timer] = [:] // FIX #4: Track timers per message ID
    private var lastSentMessageId: String? // Track last sent message for status updates
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = CyberpunkTheme.backgroundColor
        table.separatorStyle = .none
        table.keyboardDismissMode = .interactive
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        table.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        // Register all message cells
        table.register(TextMessageCell.self, forCellReuseIdentifier: "TextMessageCell")
        table.register(ToolUseMessageCell.self, forCellReuseIdentifier: "ToolUseMessageCell")
        table.register(TodoUpdateMessageCell.self, forCellReuseIdentifier: "TodoUpdateMessageCell")
        table.register(CodeMessageCell.self, forCellReuseIdentifier: "CodeMessageCell")
        table.register(ErrorMessageCell.self, forCellReuseIdentifier: "ErrorMessageCell")
        table.register(SystemMessageCell.self, forCellReuseIdentifier: "SystemMessageCell")
        table.register(ThinkingMessageCell.self, forCellReuseIdentifier: "ThinkingMessageCell")
        table.register(FileOperationMessageCell.self, forCellReuseIdentifier: "FileOperationMessageCell")
        table.register(GitOperationMessageCell.self, forCellReuseIdentifier: "GitOperationMessageCell")
        table.register(TerminalCommandMessageCell.self, forCellReuseIdentifier: "TerminalCommandMessageCell")
        
        // Register typing indicator cell
        table.register(UITableViewCell.self, forCellReuseIdentifier: "TypingIndicatorCell")
        
        return table
    }()
    
    private lazy var inputContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = CyberpunkTheme.surfaceColor
        view.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
        view.layer.borderWidth = 1
        return view
    }()
    
    private lazy var inputTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textColor = CyberpunkTheme.primaryText
        textView.font = CyberpunkTheme.bodyFont
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.returnKeyType = .default
        return textView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Type a message..."
        label.textColor = CyberpunkTheme.secondaryText
        label.font = CyberpunkTheme.bodyFont
        return label
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.isEnabled = false
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var attachmentButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        button.addTarget(self, action: #selector(attachmentButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var typingIndicatorView: TypingIndicatorView = {
        let view = TypingIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    // FIX #5: Alternative typing indicator overlay (not in table)
    private lazy var typingIndicatorOverlay: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = CyberpunkTheme.surfaceColor.withAlphaComponent(0.95)
        container.layer.cornerRadius = 12
        container.isHidden = true
        
        let indicator = TypingIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            indicator.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 16),
            indicator.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16)
        ])
        
        return container
    }()
    
    private var inputContainerBottomConstraint: NSLayoutConstraint!
    private var inputTextViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    
    init(project: Project, sessionId: String? = nil) {
        self.project = project
        self.sessionId = sessionId
        super.init(nibName: nil, bundle: nil)
        logDebug("🎬 ChatViewController initialized for project: \(project.name), sessionId: \(sessionId ?? "new")")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logDebug("♻️ ChatViewController deinit - cleaning up resources")
        NotificationCenter.default.removeObserver(self)
        webSocketManager?.delegate = nil
        webSocketManager?.disconnect()
        
        // Clean up all message status timers
        messageStatusTimers.forEach { $0.value.invalidate() }
        messageStatusTimers.removeAll()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logDebug("📱 viewDidLoad - Starting UI setup")
        
        setupUI()
        setupConstraints()
        setupKeyboardObservers()
        setupGestures()
        setupNavigationBar()
        setupWebSocket()
        
        if sessionId != nil {
            loadSessionMessages()
        } else {
            addSystemMessage("Welcome! Start a conversation to begin.")
        }
        
        logDebug("✅ viewDidLoad complete - UI ready")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logDebug("👁 viewWillAppear - Connecting WebSocket")
        webSocketManager?.connect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        logDebug("👋 viewWillDisappear - Disconnecting WebSocket")
        webSocketManager?.disconnect()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.backgroundColor
        
        view.addSubview(tableView)
        view.addSubview(inputContainerView)
        view.addSubview(typingIndicatorOverlay) // Add overlay for typing indicator
        
        inputContainerView.addSubview(attachmentButton)
        inputContainerView.addSubview(inputTextView)
        inputContainerView.addSubview(placeholderLabel)
        inputContainerView.addSubview(sendButton)
        
        tableView.delegate = self
        tableView.dataSource = self
        inputTextView.delegate = self
    }
    
    private func setupConstraints() {
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        inputTextViewHeightConstraint = inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        
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
            
            // Attachment button
            attachmentButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 8),
            attachmentButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            attachmentButton.widthAnchor.constraint(equalToConstant: 44),
            attachmentButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Input text view
            inputTextView.leadingAnchor.constraint(equalTo: attachmentButton.trailingAnchor, constant: 4),
            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 4),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -4),
            inputTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -4),
            inputTextViewHeightConstraint,
            
            // Placeholder
            placeholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor, constant: 16),
            placeholderLabel.centerYAnchor.constraint(equalTo: inputTextView.centerYAnchor),
            
            // Send button
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -8),
            sendButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Typing indicator overlay
            typingIndicatorOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            typingIndicatorOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            typingIndicatorOverlay.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -8),
            typingIndicatorOverlay.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupNavigationBar() {
        title = sessionId != nil ? "Session" : "New Chat"
        
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(menuButtonTapped)
        )
        navigationItem.rightBarButtonItem = menuButton
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }
    
    private func setupWebSocket() {
        logDebug("🔌 Setting up WebSocket connection")
        webSocketManager = WebSocketManager.shared
        webSocketManager?.delegate = self
        webSocketManager?.connect()
    }
    
    // MARK: - Message Sending
    
    private func sendMessage() {
        guard let text = inputTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            logDebug("⚠️ sendMessage called with empty text")
            return
        }
        
        let messageId = UUID().uuidString
        let timestamp = Date()
        
        logDebug("📤 Sending message - ID: \(messageId), Length: \(text.count) chars")
        
        // Create and add user message
        let userMessage = EnhancedChatMessage(
            id: messageId,
            content: text,
            isUser: true,
            timestamp: timestamp,
            status: .sending
        )
        
        messages.append(userMessage)
        lastSentMessageId = messageId // Track this message for status updates
        
        // Update UI
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .bottom)
        
        // Clear input
        inputTextView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
        updateInputTextViewHeight()
        
        // Scroll to bottom
        scrollToBottom(animated: true)
        
        // Send via WebSocket
        sendMessageViaWebSocket(text: text, messageId: messageId)
        
        // Show typing indicator after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.showTypingIndicator()
        }
        
        // FIX #4: Set timeout for this specific message
        startMessageStatusTimer(for: messageId)
    }
    
    private func sendMessageViaWebSocket(text: String, messageId: String) {
        logDebug("🌐 Preparing WebSocket message - messageId: \(messageId)")
        
        // FIX: Correct message format for backend
        let messageData: [String: Any] = [
            "type": "claude-command",
            "content": text,  // ✅ FIXED: Using 'content' instead of 'command'
            "projectPath": project.path,  // ✅ FIXED: Top-level field
            "sessionId": sessionId as Any  // ✅ FIXED: Top-level field
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                logDebug("📡 Sending WebSocket message: \(jsonString)")
                webSocketManager?.send(jsonString)
                
                // Update message status to sent
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.updateMessageStatus(messageId: messageId, to: .sent)
                }
            }
        } catch {
            logDebug("❌ Failed to serialize message: \(error)")
            updateMessageStatus(messageId: messageId, to: .failed)
        }
    }
    
    // FIX #4: Enhanced status update with specific message ID tracking
    private func updateMessageStatus(messageId: String, to status: MessageStatus) {
        logDebug("📊 Updating message \(messageId) status to: \(status)")
        
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else {
            logDebug("⚠️ Message \(messageId) not found for status update")
            return
        }
        
        messages[index].status = status
        
        // Cancel timer if message succeeded
        if status == .delivered || status == .read {
            messageStatusTimers[messageId]?.invalidate()
            messageStatusTimers.removeValue(forKey: messageId)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = self.tableView.cellForRow(at: indexPath) as? BaseMessageCell {
                cell.updateStatus(status)
            }
        }
    }
    
    private func startMessageStatusTimer(for messageId: String) {
        logDebug("⏱ Starting status timer for message: \(messageId)")
        
        // Cancel any existing timer for this message
        messageStatusTimers[messageId]?.invalidate()
        
        // Create new timer
        let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.logDebug("⏰ Message \(messageId) timeout - marking as failed")
            self?.updateMessageStatus(messageId: messageId, to: .failed)
            self?.messageStatusTimers.removeValue(forKey: messageId)
        }
        
        messageStatusTimers[messageId] = timer
    }
    
    // MARK: - WebSocket Message Handling
    
    private func handleWebSocketMessage(_ message: String) {
        logDebug("📨 Received WebSocket message: \(message.prefix(200))...")
        
        // Try to parse as JSON
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logDebug("⚠️ Failed to parse WebSocket message as JSON")
            handlePlainTextMessage(message)
            return
        }
        
        // Extract message type
        let messageType = json["type"] as? String ?? "unknown"
        logDebug("📋 Message type: \(messageType)")
        
        switch messageType {
        case "claude-response", "assistant-message", "message":
            handleClaudeResponse(json)
        case "streaming-start":
            handleStreamingStart(json)
        case "streaming-chunk":
            handleStreamingChunk(json)
        case "streaming-end":
            handleStreamingEnd(json)
        case "error":
            handleErrorMessage(json)
        case "system":
            handleSystemMessage(json)
        default:
            logDebug("📦 Unhandled message type: \(messageType)")
        }
    }
    
    private func handleClaudeResponse(_ json: [String: Any]) {
        logDebug("🤖 Processing Claude response")
        
        hideTypingIndicator()
        
        // Update last sent message status
        if let lastMessageId = lastSentMessageId {
            updateMessageStatus(messageId: lastMessageId, to: .delivered)
        }
        
        // FIX #2: Improved message filtering logic
        if let content = json["content"] as? String {
            // Only skip if it's JUST a UUID (exactly 36 chars with dashes)
            let isUUID = content.count == 36 && 
                        content.replacingOccurrences(of: "-", with: "").count == 32 &&
                        CharacterSet(charactersIn: content).isSubset(of: CharacterSet(charactersIn: "0123456789abcdefABCDEF-"))
            
            if isUUID {
                logDebug("🚫 Skipping UUID-only metadata: \(content)")
                return
            }
            
            // Skip very short metadata-like responses only if they match specific patterns
            let metadataPatterns = ["success", "ok", "done", "received"]
            let isLikelyMetadata = content.count < 10 && metadataPatterns.contains(content.lowercased())
            
            if isLikelyMetadata {
                logDebug("⚠️ Possible metadata response, but showing anyway: \(content)")
                // Don't return - show it anyway to avoid missing legitimate short responses
            }
            
            // Create assistant message
            let assistantMessage = EnhancedChatMessage(
                id: UUID().uuidString,
                content: content,
                isUser: false,
                timestamp: Date(),
                status: .delivered
            )
            
            // Check for special message types
            assistantMessage.detectMessageType()
            
            messages.append(assistantMessage)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .bottom)
                self.scrollToBottom(animated: true)
            }
            
            logDebug("✅ Added Claude response to chat: \(content.prefix(100))...")
        }
    }
    
    private func handleStreamingStart(_ json: [String: Any]) {
        logDebug("🌊 Streaming started")
        hideTypingIndicator()
        
        // Update last sent message status
        if let lastMessageId = lastSentMessageId {
            updateMessageStatus(messageId: lastMessageId, to: .delivered)
        }
        
        guard let messageId = json["messageId"] as? String else { return }
        
        // Create placeholder message for streaming
        let streamingMessage = EnhancedChatMessage(
            id: messageId,
            content: "",
            isUser: false,
            timestamp: Date(),
            status: .delivered
        )
        
        messages.append(streamingMessage)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .bottom)
        }
    }
    
    private func handleStreamingChunk(_ json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json) else { return }
        
        if let result = streamingMessageHandler.processStreamingChunk(data) {
            logDebug("🌊 Streaming chunk - messageId: \(result.messageId), complete: \(result.isComplete)")
            
            // Find and update the streaming message
            if let index = messages.firstIndex(where: { $0.id == result.messageId }) {
                messages[index].content = result.content
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let indexPath = IndexPath(row: index, section: 0)
                    if let cell = self.tableView.cellForRow(at: indexPath) as? BaseMessageCell {
                        cell.configure(with: self.messages[index])
                    }
                }
            }
        }
    }
    
    private func handleStreamingEnd(_ json: [String: Any]) {
        logDebug("🌊 Streaming ended")
        
        guard let messageId = json["messageId"] as? String else { return }
        
        // Finalize the streaming message
        if let finalContent = streamingMessageHandler.completeMessage(id: messageId) {
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                messages[index].content = finalContent
                messages[index].detectMessageType()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let indexPath = IndexPath(row: index, section: 0)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                    self.scrollToBottom(animated: true)
                }
            }
        }
    }
    
    private func handleErrorMessage(_ json: [String: Any]) {
        logDebug("❌ Error message received")
        hideTypingIndicator()
        
        let errorContent = json["error"] as? String ?? "An error occurred"
        
        let errorMessage = EnhancedChatMessage(
            id: UUID().uuidString,
            content: "❌ Error: \(errorContent)",
            isUser: false,
            timestamp: Date(),
            status: .delivered
        )
        errorMessage.messageType = .error
        
        messages.append(errorMessage)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .bottom)
            self.scrollToBottom(animated: true)
        }
        
        // Update last sent message as failed if exists
        if let lastMessageId = lastSentMessageId {
            updateMessageStatus(messageId: lastMessageId, to: .failed)
        }
    }
    
    private func handleSystemMessage(_ json: [String: Any]) {
        logDebug("🔔 System message received")
        
        let content = json["message"] as? String ?? "System notification"
        addSystemMessage(content)
    }
    
    private func handlePlainTextMessage(_ message: String) {
        logDebug("📝 Handling plain text message")
        hideTypingIndicator()
        
        // Update last sent message status
        if let lastMessageId = lastSentMessageId {
            updateMessageStatus(messageId: lastMessageId, to: .delivered)
        }
        
        let assistantMessage = EnhancedChatMessage(
            id: UUID().uuidString,
            content: message,
            isUser: false,
            timestamp: Date(),
            status: .delivered
        )
        
        messages.append(assistantMessage)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .bottom)
            self.scrollToBottom(animated: true)
        }
    }
    
    // MARK: - Helper Methods
    
    private func addSystemMessage(_ content: String) {
        logDebug("🔔 Adding system message: \(content)")
        
        let systemMessage = EnhancedChatMessage(
            id: UUID().uuidString,
            content: content,
            isUser: false,
            timestamp: Date(),
            status: .delivered
        )
        systemMessage.messageType = .system
        
        messages.append(systemMessage)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .bottom)
        }
    }
    
    private func loadSessionMessages() {
        guard let sessionId = sessionId else { return }
        
        logDebug("📥 Loading messages for session: \(sessionId)")
        
        // Show loading indicator
        showLoadingIndicator()
        
        APIClient.shared.getSessionMessages(
            projectName: project.name,
            sessionId: sessionId
        ) { [weak self] result in
            guard let self = self else { return }
            
            self.hideLoadingIndicator()
            
            switch result {
            case .success(let loadedMessages):
                self.logDebug("✅ Loaded \(loadedMessages.count) messages")
                
                // Convert to EnhancedChatMessage
                self.messages = loadedMessages.map { message in
                    let enhanced = EnhancedChatMessage(
                        id: message.id ?? UUID().uuidString,
                        content: message.content,
                        isUser: message.role == "user",
                        timestamp: message.timestamp ?? Date(),
                        status: .delivered
                    )
                    enhanced.detectMessageType()
                    return enhanced
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottom(animated: false)
                }
                
            case .failure(let error):
                self.logDebug("❌ Failed to load messages: \(error)")
                self.showError("Failed to load messages: \(error.localizedDescription)")
            }
        }
    }
    
    // FIX #5: Improved typing indicator management
    private func showTypingIndicator() {
        guard !isTypingIndicatorVisible else { return }
        
        logDebug("💭 Showing typing indicator overlay")
        isTypingIndicatorVisible = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Use overlay instead of table row
            self.typingIndicatorOverlay.isHidden = false
            self.typingIndicatorOverlay.alpha = 0
            
            UIView.animate(withDuration: 0.3) {
                self.typingIndicatorOverlay.alpha = 1
            }
        }
    }
    
    private func hideTypingIndicator() {
        guard isTypingIndicatorVisible else { return }
        
        logDebug("💭 Hiding typing indicator overlay")
        isTypingIndicatorVisible = false
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.3, animations: {
                self.typingIndicatorOverlay.alpha = 0
            }) { _ in
                self.typingIndicatorOverlay.isHidden = true
            }
        }
    }
    
    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        
        // Cancel any pending scroll operations
        scrollWorkItem?.cancel()
        
        // Create new scroll work item with debouncing
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            let lastRow = self.messages.count - 1
            let indexPath = IndexPath(row: lastRow, section: 0)
            
            // Validate table view state
            guard lastRow >= 0,
                  self.tableView.numberOfSections > 0,
                  self.tableView.numberOfRows(inSection: 0) > lastRow else {
                self.logDebug("⚠️ Invalid table state for scrolling")
                return
            }
            
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
        
        scrollWorkItem = workItem
        
        // Execute with slight delay to ensure table updates are complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
    
    private func isNearBottom() -> Bool {
        let contentHeight = tableView.contentSize.height
        let frameHeight = tableView.frame.height
        let contentOffset = tableView.contentOffset.y
        
        // Handle edge cases
        if contentHeight <= frameHeight {
            return true
        }
        
        let distanceFromBottom = contentHeight - contentOffset - frameHeight
        
        // Prevent NaN
        if distanceFromBottom.isNaN || distanceFromBottom.isInfinite {
            return true
        }
        
        return distanceFromBottom < 100
    }
    
    private func showLoadingIndicator() {
        logDebug("⏳ Showing loading indicator")
        // Implementation for loading indicator
    }
    
    private func hideLoadingIndicator() {
        logDebug("⏳ Hiding loading indicator")
        // Implementation for hiding loading indicator
    }
    
    private func showError(_ message: String) {
        logDebug("🚨 Showing error: \(message)")
        
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func sendButtonTapped() {
        logDebug("📮 Send button tapped")
        sendMessage()
    }
    
    @objc private func attachmentButtonTapped() {
        logDebug("📎 Attachment button tapped")
        showAttachmentOptions()
    }
    
    @objc private func menuButtonTapped() {
        logDebug("☰ Menu button tapped")
        showChatMenu()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        inputContainerBottomConstraint.constant = -keyboardHeight + view.safeAreaInsets.bottom
        
        UIView.animate(withDuration: duration) { [weak self] in
            self?.view.layoutIfNeeded()
            if self?.isNearBottom() == true {
                self?.scrollToBottom(animated: true)
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        inputContainerBottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    private func showAttachmentOptions() {
        let actionSheet = UIAlertController(title: "Add Attachment", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.presentCamera()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Files", style: .default) { [weak self] _ in
            self?.presentFilePicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = attachmentButton
            popover.sourceRect = attachmentButton.bounds
        }
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showError("Camera not available")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentFilePicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    private func showChatMenu() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Clear Chat", style: .destructive) { [weak self] _ in
            self?.clearChat()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Export Chat", style: .default) { [weak self] _ in
            self?.exportChat()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Session Info", style: .default) { [weak self] _ in
            self?.showSessionInfo()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = actionSheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(actionSheet, animated: true)
    }
    
    private func clearChat() {
        logDebug("🗑 Clearing chat messages")
        
        let alert = UIAlertController(
            title: "Clear Chat",
            message: "Are you sure you want to clear all messages?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.messages.removeAll()
            self?.tableView.reloadData()
            self?.logDebug("✅ Chat cleared")
        })
        
        present(alert, animated: true)
    }
    
    private func exportChat() {
        logDebug("📤 Exporting chat")
        
        var exportText = "Chat Export - \(project.name)\n"
        exportText += "Session: \(sessionId ?? "New")\n"
        exportText += "Date: \(Date())\n"
        exportText += String(repeating: "-", count: 50) + "\n\n"
        
        for message in messages {
            let role = message.isUser ? "User" : "Assistant"
            let timestamp = DateFormatter.localizedString(from: message.timestamp, dateStyle: .short, timeStyle: .short)
            exportText += "[\(timestamp)] \(role):\n\(message.content)\n\n"
        }
        
        let activityVC = UIActivityViewController(activityItems: [exportText], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityVC, animated: true)
    }
    
    private func showSessionInfo() {
        logDebug("ℹ️ Showing session info")
        
        let info = """
        Project: \(project.name)
        Path: \(project.path)
        Session ID: \(sessionId ?? "New Session")
        Messages: \(messages.count)
        WebSocket: \(webSocketManager?.isConnected == true ? "Connected" : "Disconnected")
        """
        
        let alert = UIAlertController(
            title: "Session Information",
            message: info,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func updateInputTextViewHeight() {
        let size = inputTextView.sizeThatFits(CGSize(
            width: inputTextView.frame.width,
            height: CGFloat.greatestFiniteMagnitude
        ))
        
        let newHeight = min(max(size.height, 44), 120)
        inputTextViewHeightConstraint.constant = newHeight
        
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        // Select appropriate cell type based on message
        let cellIdentifier: String
        
        switch message.messageType {
        case .toolUse:
            cellIdentifier = "ToolUseMessageCell"
        case .toolResult:
            cellIdentifier = "ToolUseMessageCell"
        case .todoUpdate:
            cellIdentifier = "TodoUpdateMessageCell"
        case .code:
            cellIdentifier = "CodeMessageCell"
        case .error:
            cellIdentifier = "ErrorMessageCell"
        case .system:
            cellIdentifier = "SystemMessageCell"
        case .thinking:
            cellIdentifier = "ThinkingMessageCell"
        case .fileOperation:
            cellIdentifier = "FileOperationMessageCell"
        case .gitOperation:
            cellIdentifier = "GitOperationMessageCell"
        case .terminalCommand:
            cellIdentifier = "TerminalCommandMessageCell"
        default:
            cellIdentifier = "TextMessageCell"
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? BaseMessageCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: message)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let message = messages[indexPath.row]
        logDebug("👆 Message tapped - type: \(message.messageType), expanded: \(message.isExpanded)")
        
        // Toggle expansion for certain message types
        if message.messageType == .code || 
           message.messageType == .toolUse || 
           message.messageType == .todoUpdate {
            message.isExpanded.toggle()
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Check if we need to load more messages (pagination)
        let contentOffset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height
        
        // Load more when scrolled to top
        if contentOffset < 100 && messages.count >= 50 {
            // Implement pagination here if needed
            logDebug("📜 Near top - pagination point reached")
        }
    }
}

// MARK: - UITextViewDelegate

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        placeholderLabel.isHidden = hasText
        sendButton.isEnabled = hasText
        
        updateInputTextViewHeight()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

// MARK: - WebSocketManagerDelegate

extension ChatViewController: WebSocketManagerDelegate {
    func webSocketDidConnect() {
        logDebug("✅ WebSocket connected")
        DispatchQueue.main.async { [weak self] in
            self?.addSystemMessage("🟢 Connected to server")
        }
    }
    
    func webSocketDidDisconnect(error: Error?) {
        logDebug("🔴 WebSocket disconnected - error: \(error?.localizedDescription ?? "none")")
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                self?.addSystemMessage("🔴 Disconnected: \(error.localizedDescription)")
            } else {
                self?.addSystemMessage("🔴 Disconnected from server")
            }
        }
    }
    
    func webSocketDidReceiveMessage(_ message: String) {
        logDebug("📬 WebSocket message received - length: \(message.count)")
        handleWebSocketMessage(message)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ChatViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        logDebug("📷 Photo picked from library")
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let image = object as? UIImage {
                self?.logDebug("✅ Image loaded successfully")
                // Handle image attachment
            } else if let error = error {
                self?.logDebug("❌ Failed to load image: \(error)")
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            logDebug("📸 Photo captured from camera")
            // Handle image attachment
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate

extension ChatViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        logDebug("📄 Document picked: \(url.lastPathComponent)")
        // Handle document attachment
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        logDebug("📄 Document picker cancelled")
    }
}