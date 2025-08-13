//
//  ChatViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

class ChatViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let project: Project
    private var messages: [ChatMessage] = []
    private let webSocketManager: WebSocketManager
    private var isTyping = false
    private var keyboardHeight: CGFloat = 0
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        tableView.register(TypingIndicatorCell.self, forCellReuseIdentifier: TypingIndicatorCell.identifier)
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
    
    init(project: Project) {
        self.project = project
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
        
        // Add terminal button
        let terminalButton = UIBarButtonItem(
            image: UIImage(systemName: "terminal"),
            style: .plain,
            target: self,
            action: #selector(showTerminal)
        )
        terminalButton.tintColor = CyberpunkTheme.primaryCyan
        
        navigationItem.rightBarButtonItems = [terminalButton, fileButton]
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
    
    // MARK: - WebSocket
    
    private func connectWebSocket() {
        webSocketManager.delegate = self
        // Use correct WebSocket path that backend expects
        var wsURL = "ws://\(AppConfig.backendHost):\(AppConfig.backendPort)/api/chat/ws"
        
        // Add authentication token as query parameter
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            wsURL += "?token=\(authToken)"
        }
        
        webSocketManager.connect(to: wsURL)
        print("🔌 Connecting to WebSocket at: \(wsURL)")
    }
    
    // MARK: - Data Loading
    
    private func loadInitialMessages() {
        // Load existing session messages from backend
        if let sessionId = UserDefaults.standard.string(forKey: "currentSessionId_\(project.id)") {
            loadSessionMessages(sessionId: sessionId)
        } else {
            // No existing session - keep messages empty (no fake welcome message)
            messages = []
            tableView.reloadData()
        }
    }
    
    private func loadSessionMessages(sessionId: String) {
        // Load messages from backend
        APIClient.shared.getSessionMessages(sessionId: sessionId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let messages):
                    self?.messages = messages.map { message in
                        ChatMessage(
                            id: message.id,
                            content: message.content,
                            isUser: message.role == "user",
                            timestamp: message.timestamp,
                            status: .sent
                        )
                    }
                    self?.tableView.reloadData()
                    
                    // Scroll to bottom if there are messages
                    if !messages.isEmpty {
                        let indexPath = IndexPath(row: messages.count - 1, section: 0)
                        self?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                    }
                    
                case .failure(let error):
                    Logger.shared.error("Failed to load session messages: \(error)")
                    // Keep messages empty on error - no fake data
                    self?.messages = []
                    self?.tableView.reloadData()
                    // Show error to user
                    self?.showError("Failed to load session messages: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func sendMessage() {
        guard let text = inputTextView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Create user message
        let message = ChatMessage(
            id: UUID().uuidString,
            content: text,
            isUser: true,
            timestamp: Date(),
            status: .sending
        )
        
        // Add to messages and update UI
        messages.append(message)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        
        // Clear input
        inputTextView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
        updateInputTextViewHeight()
        
        // Send via WebSocket
        webSocketManager.sendMessage(text, projectId: project.id)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func showAttachmentOptions() {
        let alert = UIAlertController(title: "Attach", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Choose File", style: .default) { _ in
            // Will be implemented in Phase 4
        })
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
            // Camera functionality
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = attachButton
            popover.sourceRect = attachButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func showFileExplorer() {
        let fileExplorerVC = FileExplorerViewController(project: project)
        let navController = UINavigationController(rootViewController: fileExplorerVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    @objc private func showTerminal() {
        let terminalVC = TerminalViewController(project: project)
        let navController = UINavigationController(rootViewController: terminalVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    // MARK: - Keyboard Handling
    
    @objc override func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        keyboardHeight = keyboardFrame.height
        
        UIView.animate(withDuration: duration) {
            self.inputContainerBottomConstraint.constant = -self.keyboardHeight + self.view.safeAreaInsets.bottom
            self.view.layoutIfNeeded()
        }
        
        // Scroll to bottom
        if !messages.isEmpty {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    @objc override func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        keyboardHeight = 0
        
        UIView.animate(withDuration: duration) {
            self.inputContainerBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateInputTextViewHeight() {
        let size = inputTextView.sizeThatFits(CGSize(width: inputTextView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = min(max(44, size.height), 120) // Min 44, max 120
        
        if inputTextViewHeightConstraint.constant != newHeight {
            inputTextViewHeightConstraint.constant = newHeight
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count + (isTyping ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isTyping && indexPath.row == messages.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: TypingIndicatorCell.identifier, for: indexPath) as! TypingIndicatorCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.identifier, for: indexPath) as! ChatMessageCell
            let message = messages[indexPath.row]
            cell.configure(with: message)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
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
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Handle return key
        if text == "\n" && !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Check if shift is pressed for multi-line
            // For now, always allow new lines
            return true
        }
        return true
    }
}

// MARK: - WebSocketManagerDelegate

extension ChatViewController: WebSocketManagerDelegate {
    func webSocketDidConnect(_ manager: WebSocketManager) {
        Logger.shared.info("WebSocket connected for project: \(project.id)")
    }
    
    func webSocketDidDisconnect(_ manager: WebSocketManager, error: Error?) {
        if let error = error {
            Logger.shared.error("WebSocket disconnected with error: \(error)")
        }
        // Attempt reconnection after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.connectWebSocket()
        }
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveMessage message: WebSocketMessage) {
        // Handle different message types from backend
        switch message.type {
        case .sessionCreated:
            if let sessionId = message.payload?["sessionId"] as? String {
                print("📝 Session created: \(sessionId)")
                // Store session ID for future use
                UserDefaults.standard.set(sessionId, forKey: "currentSessionId_\(project.id)")
            }
            
        case .claudeResponse:
            // Handle streaming Claude response
            if let data = message.payload?["data"] as? [String: Any] {
                handleClaudeResponse(data)
            }
            
        case .claudeOutput:
            // Handle raw Claude output
            if let content = message.payload?["data"] as? String {
                appendToLastMessage(content)
            }
            
        case .error:
            if let error = message.payload?["error"] as? String {
                showError(error)
            }
            
        default:
            // Handle generic message for backward compatibility
            if let content = message.payload?["content"] as? String {
                let assistantMessage = ChatMessage(
                    id: UUID().uuidString,
                    content: content,
                    isUser: false,
                    timestamp: Date(),
                    status: .sent
                )
                
                DispatchQueue.main.async {
                    self.messages.append(assistantMessage)
                    let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                    self.tableView.insertRows(at: [indexPath], with: .automatic)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        }
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveData data: Data) {
        // Handle binary data if needed
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ WebSocket connected")
            case .disconnected:
                print("❌ WebSocket disconnected")
            case .connecting:
                print("⏳ WebSocket connecting...")
            case .reconnecting:
                print("🔄 WebSocket reconnecting...")
            case .failed:
                print("❌ WebSocket connection failed")
            }
        }
    }
    
    // MARK: - Claude Response Handling
    
    private func handleClaudeResponse(_ data: [String: Any]) {
        // Handle different Claude response types
        if let type = data["type"] as? String {
            switch type {
            case "text":
                if let content = data["content"] as? String {
                    let message = ChatMessage(
                        id: UUID().uuidString,
                        content: content,
                        isUser: false,
                        timestamp: Date(),
                        status: .sent
                    )
                    
                    DispatchQueue.main.async {
                        self.messages.append(message)
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.insertRows(at: [indexPath], with: .automatic)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                }
                
            case "tool_use":
                // Handle tool usage events
                if let toolName = data["name"] as? String {
                    print("🔧 Claude is using tool: \(toolName)")
                }
                
            default:
                print("📦 Unhandled Claude response type: \(type)")
            }
        }
    }
    
    private func appendToLastMessage(_ content: String) {
        DispatchQueue.main.async {
            if let lastMessage = self.messages.last, !lastMessage.isUser {
                // Append to existing message
                lastMessage.content += content
                if let lastIndex = self.messages.indices.last {
                    let indexPath = IndexPath(row: lastIndex, section: 0)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            } else {
                // Create new message
                let message = ChatMessage(
                    id: UUID().uuidString,
                    content: content,
                    isUser: false,
                    timestamp: Date(),
                    status: .sent
                )
                self.messages.append(message)
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .automatic)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    private func showError(_ error: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: error,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - Chat Message Model

class ChatMessage {
    let id: String
    var content: String
    let isUser: Bool
    let timestamp: Date
    var status: MessageStatus
    
    enum MessageStatus {
        case sending
        case sent
        case failed
    }
    
    init(id: String, content: String, isUser: Bool, timestamp: Date, status: MessageStatus) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.status = status
    }
}

// MARK: - Chat Message Cell

class ChatMessageCell: UITableViewCell {
    static let identifier = "ChatMessageCell"
    
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
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
        
        // Bubble view
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 16
        
        // Message label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.font = CyberpunkTheme.bodyFont
        
        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = CyberpunkTheme.secondaryText
        
        // Status image
        statusImageView.translatesAutoresizingMaskIntoConstraints = false
        statusImageView.contentMode = .scaleAspectFit
        
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(statusImageView)
    }
    
    func configure(with message: ChatMessage) {
        messageLabel.text = message.content
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.timestamp)
        
        if message.isUser {
            // User message styling
            bubbleView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.2)
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
            messageLabel.textColor = CyberpunkTheme.primaryText
            
            // Right-aligned constraints
            NSLayoutConstraint.activate([
                bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
                bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
                
                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
                
                timeLabel.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -4),
                timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
                
                statusImageView.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -4),
                statusImageView.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
                statusImageView.widthAnchor.constraint(equalToConstant: 14),
                statusImageView.heightAnchor.constraint(equalToConstant: 14)
            ])
            
            // Status icon
            switch message.status {
            case .sending:
                statusImageView.image = UIImage(systemName: "clock")
                statusImageView.tintColor = CyberpunkTheme.secondaryText
            case .sent:
                statusImageView.image = UIImage(systemName: "checkmark")
                statusImageView.tintColor = CyberpunkTheme.primaryCyan
            case .failed:
                statusImageView.image = UIImage(systemName: "exclamationmark.circle")
                statusImageView.tintColor = CyberpunkTheme.accentPink
            }
        } else {
            // Assistant message styling
            bubbleView.backgroundColor = CyberpunkTheme.surface
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = CyberpunkTheme.border.cgColor
            messageLabel.textColor = CyberpunkTheme.primaryText
            
            // Left-aligned constraints
            NSLayoutConstraint.activate([
                bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
                bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
                
                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
                
                timeLabel.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 4),
                timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor)
            ])
            
            statusImageView.isHidden = true
        }
    }
}

// MARK: - Typing Indicator Cell

class TypingIndicatorCell: UITableViewCell {
    static let identifier = "TypingIndicatorCell"
    
    private let bubbleView = UIView()
    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        startAnimating()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.backgroundColor = CyberpunkTheme.surface
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.borderColor = CyberpunkTheme.border.cgColor
        
        [dot1, dot2, dot3].forEach { dot in
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = CyberpunkTheme.primaryCyan
            dot.layer.cornerRadius = 3
            bubbleView.addSubview(dot)
        }
        
        contentView.addSubview(bubbleView)
        
        NSLayoutConstraint.activate([
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(equalToConstant: 60),
            bubbleView.heightAnchor.constraint(equalToConstant: 32),
            
            dot1.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot1.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            dot1.widthAnchor.constraint(equalToConstant: 6),
            dot1.heightAnchor.constraint(equalToConstant: 6),
            
            dot2.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot2.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            dot2.widthAnchor.constraint(equalToConstant: 6),
            dot2.heightAnchor.constraint(equalToConstant: 6),
            
            dot3.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot3.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            dot3.widthAnchor.constraint(equalToConstant: 6),
            dot3.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    private func startAnimating() {
        let duration: TimeInterval = 0.4
        let delay: TimeInterval = 0.1
        
        [dot1, dot2, dot3].enumerated().forEach { index, dot in
            UIView.animate(withDuration: duration,
                          delay: delay * Double(index),
                          options: [.repeat, .autoreverse],
                          animations: {
                dot.alpha = 0.3
            })
        }
    }
}