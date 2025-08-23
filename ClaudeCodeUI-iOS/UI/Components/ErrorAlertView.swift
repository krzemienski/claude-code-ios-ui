//
//  ErrorAlertView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-22.
//

import UIKit

/// A reusable error alert view with cyberpunk styling and retry mechanisms
public class ErrorAlertView: UIView {
    
    // MARK: - Properties
    
    private let containerView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let detailsTextView = UITextView()
    private let retryButton = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)
    private let buttonStackView = UIStackView()
    
    private var retryHandler: (() -> Void)?
    private var dismissHandler: (() -> Void)?
    
    /// Error severity levels
    public enum Severity {
        case warning
        case error
        case critical
        
        var color: UIColor {
            switch self {
            case .warning: return UIColor.systemYellow
            case .error: return CyberpunkTheme.accentPink
            case .critical: return UIColor.systemRed
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .warning: return UIImage(systemName: "exclamationmark.triangle.fill")
            case .error: return UIImage(systemName: "xmark.octagon.fill")
            case .critical: return UIImage(systemName: "exclamationmark.shield.fill")
            }
        }
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        alpha = 0
        
        // Container setup
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = CyberpunkTheme.surface
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = CyberpunkTheme.accentPink.cgColor
        addSubview(containerView)
        
        // Add glow effect
        containerView.layer.shadowColor = CyberpunkTheme.accentPink.cgColor
        containerView.layer.shadowRadius = 20
        containerView.layer.shadowOpacity = 0.5
        containerView.layer.shadowOffset = .zero
        
        // Icon setup
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = CyberpunkTheme.accentPink
        containerView.addSubview(iconView)
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = CyberpunkTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)
        
        // Message label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = CyberpunkTheme.bodyFont
        messageLabel.textColor = CyberpunkTheme.secondaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        containerView.addSubview(messageLabel)
        
        // Details text view
        detailsTextView.translatesAutoresizingMaskIntoConstraints = false
        detailsTextView.backgroundColor = CyberpunkTheme.background
        detailsTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        detailsTextView.textColor = CyberpunkTheme.secondaryText
        detailsTextView.isEditable = false
        detailsTextView.isScrollEnabled = true
        detailsTextView.layer.cornerRadius = 8
        detailsTextView.layer.borderWidth = 1
        detailsTextView.layer.borderColor = CyberpunkTheme.border.cgColor
        detailsTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        detailsTextView.isHidden = true
        containerView.addSubview(detailsTextView)
        
        // Button stack
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        containerView.addSubview(buttonStackView)
        
        // Retry button
        retryButton.setTitle("RETRY", for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        retryButton.setTitleColor(UIColor.black, for: .normal)
        retryButton.backgroundColor = CyberpunkTheme.primaryCyan
        retryButton.layer.cornerRadius = 8
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(retryButton)
        
        // Dismiss button
        dismissButton.setTitle("DISMISS", for: .normal)
        dismissButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        dismissButton.setTitleColor(CyberpunkTheme.primaryText, for: .normal)
        dismissButton.backgroundColor = CyberpunkTheme.surface
        dismissButton.layer.cornerRadius = 8
        dismissButton.layer.borderWidth = 2
        dismissButton.layer.borderColor = CyberpunkTheme.border.cgColor
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(dismissButton)
        
        setupConstraints()
        addPulseAnimation()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            
            // Icon
            iconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            iconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            // Message
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            // Details (hidden by default)
            detailsTextView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
            detailsTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            detailsTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            detailsTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 120),
            
            // Buttons
            buttonStackView.topAnchor.constraint(equalTo: detailsTextView.bottomAnchor, constant: 24),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Adjust constraints when details are hidden
        let detailsHiddenConstraint = buttonStackView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24)
        detailsHiddenConstraint.priority = .defaultHigh
        detailsHiddenConstraint.isActive = true
    }
    
    // MARK: - Animation
    
    private func addPulseAnimation() {
        // Icon pulse animation
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.1
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        iconView.layer.add(pulseAnimation, forKey: "pulse")
        
        // Border glow animation
        let glowAnimation = CABasicAnimation(keyPath: "borderColor")
        glowAnimation.duration = 1.5
        glowAnimation.fromValue = CyberpunkTheme.accentPink.cgColor
        glowAnimation.toValue = CyberpunkTheme.accentPink.withAlphaComponent(0.3).cgColor
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = .infinity
        containerView.layer.add(glowAnimation, forKey: "glow")
    }
    
    // MARK: - Configuration
    
    /// Configures the error alert
    public func configure(
        severity: Severity = .error,
        title: String,
        message: String,
        details: String? = nil,
        showRetry: Bool = true,
        retryAction: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        // Set severity-based styling
        iconView.image = severity.icon
        iconView.tintColor = severity.color
        containerView.layer.borderColor = severity.color.cgColor
        containerView.layer.shadowColor = severity.color.cgColor
        
        // Set content
        titleLabel.text = title
        messageLabel.text = message
        
        // Configure details
        if let details = details {
            detailsTextView.text = details
            detailsTextView.isHidden = false
        } else {
            detailsTextView.isHidden = true
        }
        
        // Configure buttons
        retryButton.isHidden = !showRetry
        retryHandler = retryAction
        dismissHandler = dismissAction
        
        // Adjust button stack for single button
        if !showRetry {
            buttonStackView.distribution = .fill
        } else {
            buttonStackView.distribution = .fillEqually
        }
    }
    
    // MARK: - Show/Hide
    
    /// Shows the error alert with animation
    public func show(in view: UIView? = nil, animated: Bool = true) {
        let targetView = view ?? UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIApplication.shared.windows.first
        guard let targetView = targetView else { return }
        
        // Add to view hierarchy
        frame = targetView.bounds
        targetView.addSubview(self)
        
        // Haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.error)
        
        if animated {
            // Animate in
            containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: .curveEaseOut,
                animations: {
                    self.alpha = 1
                    self.containerView.transform = .identity
                }
            )
        } else {
            alpha = 1
        }
    }
    
    /// Hides the error alert with animation
    public func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated {
            UIView.animate(
                withDuration: 0.25,
                animations: {
                    self.alpha = 0
                    self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
            ) { _ in
                self.removeFromSuperview()
                completion?()
            }
        } else {
            removeFromSuperview()
            completion?()
        }
    }
    
    // MARK: - Actions
    
    @objc private func retryTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Button animation
        UIView.animate(withDuration: 0.1, animations: {
            self.retryButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.retryButton.transform = .identity
            }
        }
        
        // Hide alert and call handler
        hide { [weak self] in
            self?.retryHandler?()
        }
    }
    
    @objc private func dismissTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Button animation
        UIView.animate(withDuration: 0.1, animations: {
            self.dismissButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.dismissButton.transform = .identity
            }
        }
        
        // Hide alert and call handler
        hide { [weak self] in
            self?.dismissHandler?()
        }
    }
}

// MARK: - Error Alert Helper Extension

public extension UIViewController {
    
    /// Shows an error alert with cyberpunk styling
    func showErrorAlert(
        severity: ErrorAlertView.Severity = .error,
        title: String = "Error",
        message: String,
        details: String? = nil,
        showRetry: Bool = false,
        retryAction: (() -> Void)? = nil
    ) {
        let errorAlert = ErrorAlertView()
        errorAlert.configure(
            severity: severity,
            title: title,
            message: message,
            details: details,
            showRetry: showRetry,
            retryAction: retryAction
        )
        errorAlert.show(in: view)
    }
    
    /// Shows a network error alert
    func showNetworkError(
        message: String = "Unable to connect to the server. Please check your internet connection.",
        retryAction: (() -> Void)? = nil
    ) {
        showErrorAlert(
            title: "Network Error",
            message: message,
            showRetry: true,
            retryAction: retryAction
        )
    }
    
    /// Shows a validation error alert
    func showValidationError(message: String) {
        showErrorAlert(
            severity: .warning,
            title: "Validation Error",
            message: message,
            showRetry: false
        )
    }
    
    /// Shows a critical error alert
    func showCriticalError(
        message: String,
        details: String? = nil
    ) {
        showErrorAlert(
            severity: .critical,
            title: "Critical Error",
            message: message,
            details: details,
            showRetry: false
        )
    }
}