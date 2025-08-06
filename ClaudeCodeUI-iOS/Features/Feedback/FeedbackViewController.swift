//
//  FeedbackViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025/01/05.
//

import UIKit
import MessageUI

/// Feedback collection and submission controller
class FeedbackViewController: UIViewController {
    
    // MARK: - Feedback Type
    enum FeedbackType: String, CaseIterable {
        case bug = "Bug Report"
        case feature = "Feature Request"
        case improvement = "Improvement"
        case praise = "Praise"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .bug: return "ladybug.fill"
            case .feature: return "sparkles"
            case .improvement: return "arrow.up.circle.fill"
            case .praise: return "star.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
        
        var color: UIColor {
            switch self {
            case .bug: return .systemRed
            case .feature: return CyberpunkTheme.primaryCyan
            case .improvement: return .systemBlue
            case .praise: return .systemYellow
            case .other: return .systemGray
            }
        }
    }
    
    // MARK: - Properties
    private var selectedType: FeedbackType = .feature
    private let maxCharacterCount = 1000
    
    // MARK: - UI Elements
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Send Feedback"
        label.font = .claudeCodeFont(style: .largeTitle, weight: .bold)
        label.textColor = CyberpunkTheme.text
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Help us improve Claude Code"
        label.font = .claudeCodeFont(style: .body)
        label.textColor = CyberpunkTheme.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var typeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: FeedbackType.allCases.map { $0.rawValue })
        control.selectedSegmentIndex = 1 // Feature Request
        control.selectedSegmentTintColor = CyberpunkTheme.primaryCyan
        control.backgroundColor = CyberpunkTheme.surface
        control.setTitleTextAttributes([
            .foregroundColor: CyberpunkTheme.text,
            .font: UIFont.claudeCodeFont(style: .footnote, weight: .medium)
        ], for: .normal)
        control.setTitleTextAttributes([
            .foregroundColor: CyberpunkTheme.background,
            .font: UIFont.claudeCodeFont(style: .footnote, weight: .semibold)
        ], for: .selected)
        control.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var feedbackTextView: UITextView = {
        let textView = UITextView()
        textView.font = .claudeCodeFont(style: .body)
        textView.textColor = CyberpunkTheme.text
        textView.backgroundColor = CyberpunkTheme.surface
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = CyberpunkTheme.border.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Describe your feedback in detail..."
        label.font = .claudeCodeFont(style: .body)
        label.textColor = CyberpunkTheme.secondaryText.withAlphaComponent(0.6)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var characterCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 / \(maxCharacterCount)"
        label.font = .claudeCodeFont(style: .caption1)
        label.textColor = CyberpunkTheme.secondaryText
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email (optional)"
        textField.font = .claudeCodeFont(style: .body)
        textField.textColor = CyberpunkTheme.text
        textField.backgroundColor = CyberpunkTheme.surface
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = CyberpunkTheme.border.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightViewMode = .always
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var attachScreenshotButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("📷 Attach Screenshot", for: .normal)
        button.setTitleColor(CyberpunkTheme.primaryCyan, for: .normal)
        button.titleLabel?.font = .claudeCodeFont(style: .body, weight: .medium)
        button.backgroundColor = CyberpunkTheme.surface
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
        button.addTarget(self, action: #selector(attachScreenshotTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var screenshotImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.backgroundColor = CyberpunkTheme.surface
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Submit Feedback", for: .normal)
        button.setTitleColor(CyberpunkTheme.background, for: .normal)
        button.titleLabel?.font = .claudeCodeFont(style: .headline, weight: .semibold)
        button.backgroundColor = CyberpunkTheme.primaryCyan
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addCyberpunkGlow()
        return button
    }()
    
    private var attachedImage: UIImage?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardHandling()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Navigation bar
        navigationItem.title = "Feedback"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Add views
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(typeSegmentedControl)
        contentView.addSubview(feedbackTextView)
        contentView.addSubview(placeholderLabel)
        contentView.addSubview(characterCountLabel)
        contentView.addSubview(emailTextField)
        contentView.addSubview(attachScreenshotButton)
        contentView.addSubview(screenshotImageView)
        contentView.addSubview(submitButton)
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Type selector
            typeSegmentedControl.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            typeSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            typeSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            typeSegmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            // Feedback text
            feedbackTextView.topAnchor.constraint(equalTo: typeSegmentedControl.bottomAnchor, constant: 20),
            feedbackTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            feedbackTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            feedbackTextView.heightAnchor.constraint(equalToConstant: 200),
            
            // Placeholder
            placeholderLabel.topAnchor.constraint(equalTo: feedbackTextView.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: feedbackTextView.leadingAnchor, constant: 16),
            
            // Character count
            characterCountLabel.topAnchor.constraint(equalTo: feedbackTextView.bottomAnchor, constant: 8),
            characterCountLabel.trailingAnchor.constraint(equalTo: feedbackTextView.trailingAnchor),
            
            // Email
            emailTextField.topAnchor.constraint(equalTo: characterCountLabel.bottomAnchor, constant: 20),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Screenshot button
            attachScreenshotButton.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            attachScreenshotButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            attachScreenshotButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            attachScreenshotButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Screenshot preview
            screenshotImageView.topAnchor.constraint(equalTo: attachScreenshotButton.bottomAnchor, constant: 20),
            screenshotImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            screenshotImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            screenshotImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Submit button
            submitButton.topAnchor.constraint(equalTo: screenshotImageView.bottomAnchor, constant: 30),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 56),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
        
        // Accessibility
        feedbackTextView.accessibilityLabel = "Feedback text"
        emailTextField.accessibilityLabel = "Email address (optional)"
        attachScreenshotButton.accessibilityLabel = "Attach screenshot"
        submitButton.accessibilityLabel = "Submit feedback"
    }
    
    private func setupKeyboardHandling() {
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
        
        // Dismiss keyboard on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func typeChanged() {
        selectedType = FeedbackType.allCases[typeSegmentedControl.selectedSegmentIndex]
        
        // Update placeholder based on type
        switch selectedType {
        case .bug:
            placeholderLabel.text = "Describe the bug and steps to reproduce..."
        case .feature:
            placeholderLabel.text = "Describe the feature you'd like to see..."
        case .improvement:
            placeholderLabel.text = "What could be improved?"
        case .praise:
            placeholderLabel.text = "What do you love about Claude Code?"
        case .other:
            placeholderLabel.text = "Share your thoughts..."
        }
    }
    
    @objc private func attachScreenshotTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    @objc private func submitTapped() {
        guard let feedbackText = feedbackTextView.text, !feedbackText.isEmpty else {
            showAlert(title: "Missing Feedback", message: "Please enter your feedback before submitting.")
            return
        }
        
        // Prepare feedback data
        let feedback = FeedbackData(
            type: selectedType,
            message: feedbackText,
            email: emailTextField.text,
            screenshot: attachedImage,
            deviceInfo: getDeviceInfo(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        )
        
        // Submit feedback
        submitFeedback(feedback)
    }
    
    private func submitFeedback(_ feedback: FeedbackData) {
        // Show loading
        let loadingAlert = UIAlertController(title: "Submitting", message: "Sending your feedback...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        // Submit to backend
        APIClient.shared.submitFeedback(feedback) { [weak self] result in
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    switch result {
                    case .success:
                        self?.showSuccessAndDismiss()
                    case .failure(let error):
                        self?.showError(error)
                    }
                }
            }
        }
    }
    
    private func showSuccessAndDismiss() {
        let successAlert = UIAlertController(
            title: "Thank You!",
            message: "Your feedback has been submitted successfully.",
            preferredStyle: .alert
        )
        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(successAlert, animated: true)
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func showError(_ error: Error) {
        showAlert(
            title: "Submission Failed",
            message: "Failed to submit feedback: \(error.localizedDescription)"
        )
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) - iOS \(device.systemVersion)"
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.scrollIndicatorInsets.bottom = keyboardFrame.height
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITextViewDelegate
extension FeedbackViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Update placeholder
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        // Update character count
        let count = textView.text.count
        characterCountLabel.text = "\(count) / \(maxCharacterCount)"
        characterCountLabel.textColor = count > maxCharacterCount ? .systemRed : CyberpunkTheme.secondaryText
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        return updatedText.count <= maxCharacterCount
    }
}

// MARK: - UIImagePickerControllerDelegate
extension FeedbackViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            attachedImage = editedImage
            screenshotImageView.image = editedImage
            screenshotImageView.isHidden = false
            attachScreenshotButton.setTitle("✓ Screenshot Attached", for: .normal)
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - Feedback Data Model
struct FeedbackData {
    let type: FeedbackViewController.FeedbackType
    let message: String
    let email: String?
    let screenshot: UIImage?
    let deviceInfo: String
    let appVersion: String
}