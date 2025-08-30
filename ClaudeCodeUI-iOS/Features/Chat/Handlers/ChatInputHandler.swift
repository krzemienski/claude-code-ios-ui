//
//  ChatInputHandler.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-30.
//  Manages chat input bar, text composition, and attachments
//

import UIKit
import Combine

// MARK: - ChatInputHandler

/// Handles chat input bar interactions and message composition
@MainActor
final class ChatInputHandler: NSObject {
    
    // MARK: - Properties
    
    weak var inputBar: ChatInputBar?
    weak var viewModel: ChatViewModel?
    weak var presentingViewController: UIViewController?
    
    private var cancellables = Set<AnyCancellable>()
    private var isComposing = false
    private var compositionTimer: Timer?
    
    // Configuration
    private let maxMessageLength = 5000
    private let typingDebounceInterval: TimeInterval = 1.0
    
    // MARK: - Initialization
    
    init(inputBar: ChatInputBar, viewModel: ChatViewModel) {
        self.inputBar = inputBar
        self.viewModel = viewModel
        super.init()
        
        setupInputBar()
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupInputBar() {
        inputBar?.delegate = self
        inputBar?.textView.delegate = self
        
        // Configure input bar
        inputBar?.maxTextLength = maxMessageLength
        inputBar?.placeholder = "Type a message..."
        inputBar?.sendButtonEnabled = false
        
        // Add gesture recognizers
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDown.direction = .down
        inputBar?.addGestureRecognizer(swipeDown)
    }
    
    private func setupBindings() {
        // Bind to loading state
        viewModel?.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateInputState(enabled: !isLoading)
            }
            .store(in: &cancellables)
        
        // Bind to connection status
        viewModel?.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateConnectionStatus(status)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func clearInput() {
        inputBar?.textView.text = ""
        inputBar?.sendButtonEnabled = false
        updateTextCounter(0)
    }
    
    func focusInput() {
        inputBar?.textView.becomeFirstResponder()
    }
    
    func dismissKeyboard() {
        inputBar?.textView.resignFirstResponder()
    }
    
    func insertText(_ text: String) {
        guard let textView = inputBar?.textView else { return }
        
        let currentText = textView.text ?? ""
        let newText = currentText + text
        
        // Check length limit
        if newText.count <= maxMessageLength {
            textView.text = newText
            textViewDidChange(textView)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateInputState(enabled: Bool) {
        inputBar?.textView.isEditable = enabled
        inputBar?.attachmentButton.isEnabled = enabled
        
        if !enabled {
            inputBar?.textView.alpha = 0.5
        } else {
            inputBar?.textView.alpha = 1.0
        }
    }
    
    private func updateConnectionStatus(_ status: ChatViewModel.ConnectionStatus) {
        switch status {
        case .connected:
            inputBar?.connectionIndicator.tintColor = UIColor.systemGreen
            inputBar?.textView.isEditable = true
            
        case .connecting, .reconnecting:
            inputBar?.connectionIndicator.tintColor = .systemOrange
            inputBar?.textView.isEditable = false
            
        case .disconnected:
            inputBar?.connectionIndicator.tintColor = .systemRed
            inputBar?.textView.isEditable = false
        }
    }
    
    private func updateTextCounter(_ count: Int) {
        let remaining = maxMessageLength - count
        inputBar?.characterCountLabel.text = "\(remaining)"
        
        if remaining < 100 {
            inputBar?.characterCountLabel.textColor = UIColor.systemOrange
        } else if remaining < 0 {
            inputBar?.characterCountLabel.textColor = UIColor.systemRed
        } else {
            inputBar?.characterCountLabel.textColor = UIColor.secondaryLabel
        }
    }
    
    private func startTypingIndicator() {
        compositionTimer?.invalidate()
        
        if !isComposing {
            isComposing = true
            // Send typing indicator to backend if needed
            sendTypingStatus(true)
        }
        
        // Reset timer
        compositionTimer = Timer.scheduledTimer(withTimeInterval: typingDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopTypingIndicator()
            }
        }
    }
    
    private func stopTypingIndicator() {
        compositionTimer?.invalidate()
        compositionTimer = nil
        
        if isComposing {
            isComposing = false
            sendTypingStatus(false)
        }
    }
    
    private func sendTypingStatus(_ isTyping: Bool) {
        // Send typing status via WebSocket if needed
        // This could be implemented based on backend requirements
    }
    
    @objc private func handleSwipeDown() {
        dismissKeyboard()
    }
    
    // MARK: - Message Sending
    
    private func sendMessage() {
        guard let text = inputBar?.textView.text,
              !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else { return }
        
        // Stop typing indicator
        stopTypingIndicator()
        
        // Clear input immediately for responsive feel
        let messageContent = text
        clearInput()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Send via view model
        Task {
            await viewModel?.sendMessage(messageContent)
        }
    }
}

// MARK: - ChatInputBarDelegate

extension ChatInputHandler: ChatInputBarDelegate {
    
    func chatInputBarDidTapSend(_ inputBar: ChatInputBar) {
        sendMessage()
    }
    
    func chatInputBarDidTapAttachment(_ inputBar: ChatInputBar) {
        showAttachmentOptions()
    }
    
    func chatInputBar(_ inputBar: ChatInputBar, didChangeHeight height: CGFloat) {
        // Notify view controller of height change if needed
        NotificationCenter.default.post(
            name: .chatInputBarHeightDidChange,
            object: nil,
            userInfo: ["height": height]
        )
    }
}

// MARK: - UITextViewDelegate

extension ChatInputHandler: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // Update send button state
        inputBar?.sendButtonEnabled = !trimmedText.isEmpty && text.count <= maxMessageLength
        
        // Update character counter
        updateTextCounter(text.count)
        
        // Start typing indicator
        if !trimmedText.isEmpty {
            startTypingIndicator()
        }
        
        // Auto-resize input bar
        inputBar?.updateHeight()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Handle return key
        if text == "\n" {
            // Check if shift is pressed for multi-line
            if !(inputBar?.isShiftPressed ?? false) {
                sendMessage()
                return false
            }
        }
        
        // Check length limit
        let currentText = textView.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        
        return updatedText.count <= maxMessageLength
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Scroll table view to bottom when keyboard appears
        NotificationCenter.default.post(name: .chatInputDidBeginEditing, object: nil)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        stopTypingIndicator()
    }
}

// MARK: - Attachment Options

extension ChatInputHandler {
    
    private func showAttachmentOptions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Photo Library
        let photoAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.showPhotoPicker()
        }
        photoAction.setValue(UIImage(systemName: "photo"), forKey: "image")
        alertController.addAction(photoAction)
        
        // Camera
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.showCamera()
            }
            cameraAction.setValue(UIImage(systemName: "camera"), forKey: "image")
            alertController.addAction(cameraAction)
        }
        
        // File
        let fileAction = UIAlertAction(title: "File", style: .default) { [weak self] _ in
            self?.showFilePicker()
        }
        fileAction.setValue(UIImage(systemName: "doc"), forKey: "image")
        alertController.addAction(fileAction)
        
        // Code Snippet
        let codeAction = UIAlertAction(title: "Code Snippet", style: .default) { [weak self] _ in
            self?.showCodeEditor()
        }
        codeAction.setValue(UIImage(systemName: "chevron.left.forwardslash.chevron.right"), forKey: "image")
        alertController.addAction(codeAction)
        
        // Cancel
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present
        if let presenter = presentingViewController {
            // iPad support
            if let popover = alertController.popoverPresentationController {
                popover.sourceView = inputBar?.attachmentButton
                popover.sourceRect = inputBar?.attachmentButton.bounds ?? .zero
            }
            
            presenter.present(alertController, animated: true)
        }
    }
    
    private func showPhotoPicker() {
        // Implement photo picker
        // This would use UIImagePickerController or PHPickerViewController
        print("📷 Show photo picker")
    }
    
    private func showCamera() {
        // Implement camera
        print("📸 Show camera")
    }
    
    private func showFilePicker() {
        // Implement file picker
        // This would use UIDocumentPickerViewController
        print("📁 Show file picker")
    }
    
    private func showCodeEditor() {
        // Implement code snippet editor
        print("</> Show code editor")
    }
}

// The ChatInputBar class and ChatInputBarDelegate protocol are defined in
// Features/Chat/Views/ChatInputBar.swift

// MARK: - Additional Notification Names

extension Notification.Name {
    static let chatInputDidBeginEditing = Notification.Name("chatInputDidBeginEditing")
}