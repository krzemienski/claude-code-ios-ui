//
//  ChatViewController_Extension.swift
//  ClaudeCodeUI
//
//  WebSocket and Action implementations for ChatViewController
//

import UIKit

// MARK: - ChatViewController Actions and WebSocket Extensions

extension ChatViewController {
    
    // MARK: - Actions
    
    @objc func sendMessage() {
        guard let text = inputTextView.text, !text.isEmpty else { return }
        
        // Clear input
        inputTextView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
        updateInputTextViewHeight()
        
        // Create user message
        let userMessage = EnhancedChatMessage(
            id: UUID().uuidString,
            content: text,
            isUser: true,
            timestamp: Date(),
            status: .sending
        )
        
        // Add to messages array
        messages.append(userMessage)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        scrollToBottom(animated: true)
        
        // Send through WebSocket with proper project path
        // CRITICAL FIX: Use fullPath if available, otherwise use path
        let projectPath = project.fullPath ?? project.path
        print("📤 Sending message with project path: \(projectPath)")
        webSocketManager.sendMessage(text, projectId: project.id, projectPath: projectPath)
        
        // Update message status to sent after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            userMessage.status = .sent
            if let index = self?.messages.firstIndex(where: { $0.id == userMessage.id }) {
                let indexPath = IndexPath(row: index, section: 0)
                self?.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    
    @objc func showFileExplorer() {
        let fileExplorerVC = FileExplorerViewController(project: project)
        navigationController?.pushViewController(fileExplorerVC, animated: true)
    }
    
    @objc func showTerminal() {
        let terminalVC = TerminalViewController()
        navigationController?.pushViewController(terminalVC, animated: true)
    }
    
    @objc func abortSession() {
        let alert = UIAlertController(
            title: "Abort Session?",
            message: "This will stop Claude from responding to the current request.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Abort", style: .destructive) { [weak self] _ in
            self?.webSocketManager.sendRawMessage(["type": "abort-session"])
            self?.stopTypingIndicator()
        })
        
        present(alert, animated: true)
    }
    
    @objc func showAttachmentOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "File", style: .default) { [weak self] _ in
            self?.showNotImplementedAlert()
        })
        
        alert.addAction(UIAlertAction(title: "Code Snippet", style: .default) { [weak self] _ in
            self?.showNotImplementedAlert()
        })
        
        alert.addAction(UIAlertAction(title: "Screenshot", style: .default) { [weak self] _ in
            self?.showNotImplementedAlert()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = attachButton
            popover.sourceRect = attachButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    func showNotImplementedAlert() {
        let alert = UIAlertController(
            title: "Coming Soon",
            message: "This feature is not yet implemented.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Handling
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        keyboardHeight = keyboardFrame.height
        
        UIView.animate(withDuration: duration) {
            self.inputContainerBottomConstraint.constant = -self.keyboardHeight + self.view.safeAreaInsets.bottom
            self.view.layoutIfNeeded()
        }
        
        scrollToBottom(animated: true)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        keyboardHeight = 0
        
        UIView.animate(withDuration: duration) {
            self.inputContainerBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Helper Methods
    
    func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    func updateInputTextViewHeight() {
        let maxHeight: CGFloat = 120
        let size = inputTextView.sizeThatFits(CGSize(width: inputTextView.frame.width, height: CGFloat.infinity))
        let newHeight = min(size.height, maxHeight)
        
        if inputTextViewHeightConstraint.constant != newHeight {
            inputTextViewHeightConstraint.constant = newHeight
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
        
        inputTextView.isScrollEnabled = size.height > maxHeight
    }
    
    func showTypingIndicator() {
        guard !isShowingTypingIndicator else { return }
        isShowingTypingIndicator = true
        isTyping = true
        
        // Add typing indicator row
        let indexPath = IndexPath(row: messages.count, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        scrollToBottom(animated: true)
    }
    
    func stopTypingIndicator() {
        guard isShowingTypingIndicator else { return }
        isShowingTypingIndicator = false
        isTyping = false
        
        // Remove typing indicator row
        let indexPath = IndexPath(row: messages.count, section: 0)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count + (isTyping ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Show typing indicator if it's the last row and typing
        if isTyping && indexPath.row == messages.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: TypingIndicatorCell.identifier, for: indexPath) as! TypingIndicatorCell
            cell.startAnimating()
            return cell
        }
        
        // Regular message cell
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: EnhancedMessageCell.identifier, for: indexPath) as! EnhancedMessageCell
        cell.configure(with: message)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Load more messages when scrolling to top
        if scrollView.contentOffset.y < 100 && !isLoadingMore && hasMoreMessages {
            if let sessionId = currentSessionId {
                loadSessionMessages(sessionId: sessionId, append: true)
            }
        }
    }
}

// MARK: - UITextViewDelegate

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Update placeholder visibility
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        // Update send button state
        sendButton.isEnabled = !textView.text.isEmpty
        
        // Update height
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
    // Connection state changed - required by protocol
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch state {
            case .connecting:
                self.connectionStatusLabel.text = "Connecting..."
                self.connectionStatusLabel.textColor = .systemYellow
                logInfo("WebSocket state: Connecting", category: "Chat")
                
            case .connected:
                self.connectionStatusLabel.text = "Connected"
                self.connectionStatusLabel.textColor = CyberpunkTheme.primaryCyan
                self.hideTypingIndicator()
                logInfo("WebSocket state: Connected", category: "Chat")
                
            case .disconnected:
                self.connectionStatusLabel.text = "Disconnected"
                self.connectionStatusLabel.textColor = .systemGray
                self.hideTypingIndicator()
                logInfo("WebSocket state: Disconnected", category: "Chat")
                
            case .reconnecting:
                self.connectionStatusLabel.text = "Reconnecting..."
                self.connectionStatusLabel.textColor = .systemOrange
                logInfo("WebSocket state: Reconnecting", category: "Chat")
                
            case .failed:
                self.connectionStatusLabel.text = "Connection Failed"
                self.connectionStatusLabel.textColor = CyberpunkTheme.accentPink
                self.hideTypingIndicator()
                logError("WebSocket state: Failed", category: "Chat")
            }
            
            // Update UI based on connection state
            self.inputTextView.isEditable = (state == .connected)
            self.sendButton.isEnabled = (state == .connected && !self.inputTextView.text.isEmpty)
        }
    }
    
    func webSocketDidConnect(_ manager: WebSocketManager) {
        print("✅ WebSocket connected")
        isLoading = false
        
        // Send session resume if we have a session ID
        if let sessionId = currentSessionId {
            manager.sendRawMessage([
                "type": "session-resume",
                "sessionId": sessionId,
                "projectPath": project.fullPath ?? project.path
            ])
        }
    }
    
    func webSocketDidDisconnect(_ manager: WebSocketManager, error: Error?) {
        print("❌ WebSocket disconnected: \(error?.localizedDescription ?? "Unknown error")")
        isLoading = false
        
        if let error = error {
            showErrorAlert(message: "Connection lost: \(error.localizedDescription)")
        }
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveMessage message: WebSocketMessage) {
        DispatchQueue.main.async { [weak self] in
            self?.handleWebSocketMessage(message)
        }
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveData data: Data) {
        // Handle binary data if needed
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        print("📨 Received WebSocket message type: \(message.type)")
        
        switch message.type {
        case .sessionCreated:
            if let sessionId = message.payload["sessionId"] as? String {
                currentSessionId = sessionId
                UserDefaults.standard.set(sessionId, forKey: "currentSessionId_\(project.id)")
                print("✅ Session created: \(sessionId)")
            }
            
        case .claudeResponse, .claudeOutput:
            handleClaudeResponse(message)
            
        case .toolUse:
            handleToolUse(message)
            
        case .error:
            handleError(message)
            
        case .streamStart:
            showTypingIndicator()
            if let messageId = message.payload["messageId"] as? String {
                streamingMessageId = messageId
                streamingMessageContent = ""
            }
            
        case .streamChunk:
            handleStreamChunk(message)
            
        case .streamEnd:
            stopTypingIndicator()
            finalizeStreamingMessage()
            
        default:
            print("⚠️ Unhandled message type: \(message.type)")
        }
    }
    
    private func handleClaudeResponse(_ message: WebSocketMessage) {
        guard let content = message.payload["content"] as? String else { return }
        
        let claudeMessage = EnhancedChatMessage(
            id: message.payload["id"] as? String ?? UUID().uuidString,
            content: content,
            isUser: false,
            timestamp: Date(),
            status: .sent
        )
        claudeMessage.messageType = .claudeResponse
        
        messages.append(claudeMessage)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        scrollToBottom(animated: true)
    }
    
    private func handleToolUse(_ message: WebSocketMessage) {
        guard let toolName = message.payload["name"] as? String else { return }
        
        let toolMessage = EnhancedChatMessage(
            id: UUID().uuidString,
            content: "Using tool: \(toolName)",
            isUser: false,
            timestamp: Date(),
            status: .sent
        )
        toolMessage.messageType = .toolUse
        toolMessage.toolUseData = ToolUseData(
            name: toolName,
            parameters: message.payload["parameters"] as? [String: String],
            result: message.payload["result"] as? String,
            status: message.payload["status"] as? String
        )
        
        messages.append(toolMessage)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        scrollToBottom(animated: true)
    }
    
    private func handleError(_ message: WebSocketMessage) {
        let errorMessage = message.payload["error"] as? String ?? "Unknown error occurred"
        
        let errorMsg = EnhancedChatMessage(
            id: UUID().uuidString,
            content: errorMessage,
            isUser: false,
            timestamp: Date(),
            status: .sent
        )
        errorMsg.messageType = .error
        errorMsg.errorDetails = message.payload["details"] as? String
        
        messages.append(errorMsg)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        scrollToBottom(animated: true)
        
        stopTypingIndicator()
    }
    
    private func handleStreamChunk(_ message: WebSocketMessage) {
        guard let chunk = message.payload["chunk"] as? String else { return }
        
        streamingMessageContent += chunk
        
        // Update or create streaming message
        if let index = streamingMessageIndex {
            messages[index].content = streamingMessageContent
            let indexPath = IndexPath(row: index, section: 0)
            tableView.reloadRows(at: [indexPath], with: .none)
        } else {
            let streamMessage = EnhancedChatMessage(
                id: streamingMessageId ?? UUID().uuidString,
                content: streamingMessageContent,
                isUser: false,
                timestamp: Date(),
                status: .sent
            )
            streamMessage.messageType = .claudeResponse
            
            messages.append(streamMessage)
            streamingMessageIndex = messages.count - 1
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.insertRows(at: [indexPath], with: .automatic)
            scrollToBottom(animated: true)
        }
    }
    
    private func finalizeStreamingMessage() {
        streamingMessageId = nil
        streamingMessageContent = ""
        streamingMessageIndex = nil
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TypingIndicatorCell

class TypingIndicatorCell: UITableViewCell {
    static let identifier = "TypingIndicatorCell"
    
    private let containerView = UIView()
    private let bubbleView = UIView()
    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()
    
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
        bubbleView.backgroundColor = CyberpunkTheme.surface
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.borderColor = CyberpunkTheme.border.cgColor
        containerView.addSubview(bubbleView)
        
        [dot1, dot2, dot3].forEach { dot in
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = CyberpunkTheme.primaryCyan
            dot.layer.cornerRadius = 4
            bubbleView.addSubview(dot)
        }
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.heightAnchor.constraint(equalToConstant: 50),
            
            bubbleView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            bubbleView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            bubbleView.widthAnchor.constraint(equalToConstant: 60),
            bubbleView.heightAnchor.constraint(equalToConstant: 36),
            
            dot1.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot1.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            dot1.widthAnchor.constraint(equalToConstant: 8),
            dot1.heightAnchor.constraint(equalToConstant: 8),
            
            dot2.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot2.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            dot2.widthAnchor.constraint(equalToConstant: 8),
            dot2.heightAnchor.constraint(equalToConstant: 8),
            
            dot3.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot3.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            dot3.widthAnchor.constraint(equalToConstant: 8),
            dot3.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    func startAnimating() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.3
        animation.toValue = 1.0
        animation.duration = 0.5
        animation.autoreverses = true
        animation.repeatCount = .infinity
        
        dot1.layer.add(animation, forKey: "pulse")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.17) {
            self.dot2.layer.add(animation, forKey: "pulse")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            self.dot3.layer.add(animation, forKey: "pulse")
        }
    }
    
    func stopAnimating() {
        [dot1, dot2, dot3].forEach { $0.layer.removeAllAnimations() }
    }
}