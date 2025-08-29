//
//  ChatInputHandler.swift
//  ClaudeCodeUI
//
//  Created by Refactoring on 2025-01-21.
//

import UIKit
import PhotosUI

// MARK: - Chat Input Handler Delegate

protocol ChatInputHandlerDelegate: AnyObject {
    func inputHandler(_ handler: ChatInputHandler, didSendMessage message: String)
    func inputHandler(_ handler: ChatInputHandler, didSelectImage image: UIImage)
    func inputHandlerDidRequestAttachment(_ handler: ChatInputHandler)
}

// MARK: - Chat Input Handler

class ChatInputHandler: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: ChatInputHandlerDelegate?
    weak var viewController: UIViewController?
    
    private let inputContainerView: UIView
    private let inputTextView: UITextView
    private let sendButton: UIButton
    private let attachButton: UIButton
    private let placeholderLabel: UILabel
    
    private var inputContainerBottomConstraint: NSLayoutConstraint!
    private var inputTextViewHeightConstraint: NSLayoutConstraint!
    private var keyboardHeight: CGFloat = 0
    
    // MARK: - Initialization
    
    init(inputContainerView: UIView,
         inputTextView: UITextView,
         sendButton: UIButton,
         attachButton: UIButton,
         placeholderLabel: UILabel) {
        
        self.inputContainerView = inputContainerView
        self.inputTextView = inputTextView
        self.sendButton = sendButton
        self.attachButton = attachButton
        self.placeholderLabel = placeholderLabel
        
        super.init()
        
        setupInputComponents()
        setupKeyboardObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupInputComponents() {
        // Configure text view
        inputTextView.delegate = self
        inputTextView.backgroundColor = CyberpunkTheme.background
        inputTextView.textColor = CyberpunkTheme.primaryText
        inputTextView.font = CyberpunkTheme.bodyFont
        inputTextView.tintColor = CyberpunkTheme.primaryCyan
        inputTextView.layer.cornerRadius = 20
        inputTextView.layer.borderWidth = 1
        inputTextView.layer.borderColor = CyberpunkTheme.border.cgColor
        inputTextView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        inputTextView.isScrollEnabled = false
        inputTextView.accessibilityIdentifier = "chatInputTextView"
        
        // Configure placeholder
        placeholderLabel.text = "Type a message..."
        placeholderLabel.font = CyberpunkTheme.bodyFont
        placeholderLabel.textColor = CyberpunkTheme.secondaryText
        
        // Configure send button
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = CyberpunkTheme.primaryCyan
        sendButton.isEnabled = false
        sendButton.accessibilityIdentifier = "chatSendButton"
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        
        // Configure attach button
        attachButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
        attachButton.tintColor = CyberpunkTheme.primaryCyan
        attachButton.addTarget(self, action: #selector(attachButtonTapped), for: .touchUpInside)
        
        // Configure container
        inputContainerView.backgroundColor = CyberpunkTheme.surface
        inputContainerView.layer.borderWidth = 1
        inputContainerView.layer.borderColor = CyberpunkTheme.border.cgColor
        
        // Add top glow effect
        addGlowEffect()
    }
    
    private func addGlowEffect() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0, 0.5]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 2)
        inputContainerView.layer.addSublayer(gradientLayer)
    }
    
    // MARK: - Public Methods
    
    func setConstraints(bottomConstraint: NSLayoutConstraint, heightConstraint: NSLayoutConstraint) {
        self.inputContainerBottomConstraint = bottomConstraint
        self.inputTextViewHeightConstraint = heightConstraint
    }
    
    func clearInput() {
        inputTextView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
        updateInputTextViewHeight()
    }
    
    func focusInput() {
        inputTextView.becomeFirstResponder()
    }
    
    func resignInput() {
        inputTextView.resignFirstResponder()
    }
    
    // MARK: - Actions
    
    @objc private func sendButtonTapped() {
        guard let text = inputTextView.text, !text.isEmpty else { return }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Notify delegate
        delegate?.inputHandler(self, didSendMessage: text)
        
        // Clear input
        clearInput()
    }
    
    @objc private func attachButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Notify delegate
        delegate?.inputHandlerDidRequestAttachment(self)
    }
    
    // MARK: - Keyboard Handling
    
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
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        keyboardHeight = keyboardFrame.height
        inputContainerBottomConstraint.constant = -keyboardHeight
        
        UIView.animate(withDuration: duration) { [weak self] in
            self?.viewController?.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        keyboardHeight = 0
        inputContainerBottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) { [weak self] in
            self?.viewController?.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateInputTextViewHeight() {
        let maxHeight: CGFloat = 120
        let minHeight: CGFloat = 44
        
        let size = inputTextView.sizeThatFits(CGSize(width: inputTextView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = min(max(size.height, minHeight), maxHeight)
        
        if newHeight != inputTextViewHeightConstraint.constant {
            inputTextViewHeightConstraint.constant = newHeight
            inputTextView.isScrollEnabled = newHeight >= maxHeight
            
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.viewController?.view.layoutIfNeeded()
            }
        }
    }
}

// MARK: - UITextViewDelegate

extension ChatInputHandler: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let hasText = !textView.text.isEmpty
        placeholderLabel.isHidden = hasText
        sendButton.isEnabled = hasText
        
        // Update send button appearance
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.sendButton.alpha = hasText ? 1.0 : 0.5
        }
        
        // Update height
        updateInputTextViewHeight()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Add glow effect when focused
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.inputTextView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
            self?.inputTextView.layer.borderWidth = 2
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // Remove glow effect when unfocused
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.inputTextView.layer.borderColor = CyberpunkTheme.border.cgColor
            self?.inputTextView.layer.borderWidth = 1
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Handle return key for sending (with cmd key on Mac)
        if text == "\n" {
            // Check if cmd key is pressed (for Mac Catalyst)
            #if targetEnvironment(macCatalyst)
            if UIApplication.shared.keyWindow?.rootViewController?.isFirstResponder == true {
                sendButtonTapped()
                return false
            }
            #endif
        }
        return true
    }
}

// MARK: - Image Picker Support

extension ChatInputHandler {
    
    func presentImagePicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        viewController?.present(picker, animated: true)
    }
    
    func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        
        viewController?.present(picker, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ChatInputHandler: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let error = error {
                print("Error loading image: \(error)")
                return
            }
            
            guard let image = object as? UIImage,
                  let self = self else { return }
            
            DispatchQueue.main.async {
                self.delegate?.inputHandler(self, didSelectImage: image)
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ChatInputHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            return
        }
        
        delegate?.inputHandler(self, didSelectImage: image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}