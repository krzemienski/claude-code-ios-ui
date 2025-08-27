//
//  NotificationManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-26.
//

import UIKit

// MARK: - Notification Manager

/// Central manager for in-app notifications and toasts
final class NotificationManager {
    
    // MARK: - Singleton
    
    static let shared = NotificationManager()
    
    // MARK: - Properties
    
    private var currentNotification: NotificationView?
    private let notificationQueue = DispatchQueue(label: "com.claudecode.ui.notifications", qos: .userInteractive)
    private var pendingNotifications: [NotificationData] = []
    private var isShowingNotification = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    func showOfflineNotification() {
        let notification = NotificationData(
            title: "Offline Mode",
            message: "You're offline. Changes will sync when connection is restored.",
            type: .warning,
            icon: "wifi.slash",
            duration: 4.0,
            hapticFeedback: .medium
        )
        show(notification)
    }
    
    func showOnlineNotification() {
        let notification = NotificationData(
            title: "Back Online",
            message: "Connection restored. Syncing your changes...",
            type: .success,
            icon: "wifi",
            duration: 3.0,
            hapticFeedback: .light
        )
        show(notification)
    }
    
    func showSyncCompleteNotification(itemCount: Int) {
        let message = itemCount == 1 ? "1 change synced" : "\(itemCount) changes synced"
        let notification = NotificationData(
            title: "Sync Complete",
            message: message,
            type: .success,
            icon: "checkmark.circle.fill",
            duration: 2.5,
            hapticFeedback: .light
        )
        show(notification)
    }
    
    func showError(_ error: Error) {
        let notification = NotificationData(
            title: "Error",
            message: error.localizedDescription,
            type: .error,
            icon: "exclamationmark.triangle.fill",
            duration: 4.0,
            hapticFeedback: .heavy
        )
        show(notification)
    }
    
    func showSuccess(_ message: String) {
        let notification = NotificationData(
            title: "Success",
            message: message,
            type: .success,
            icon: "checkmark.circle.fill",
            duration: 2.5,
            hapticFeedback: .light
        )
        show(notification)
    }
    
    func showInfo(_ message: String) {
        let notification = NotificationData(
            title: "Info",
            message: message,
            type: .info,
            icon: "info.circle.fill",
            duration: 3.0,
            hapticFeedback: .light
        )
        show(notification)
    }
    
    // MARK: - Private Methods
    
    private func show(_ notification: NotificationData) {
        notificationQueue.async { [weak self] in
            self?.pendingNotifications.append(notification)
            self?.processNextNotification()
        }
    }
    
    private func processNextNotification() {
        guard !isShowingNotification,
              !pendingNotifications.isEmpty else { return }
        
        let notification = pendingNotifications.removeFirst()
        isShowingNotification = true
        
        DispatchQueue.main.async { [weak self] in
            self?.displayNotification(notification)
        }
    }
    
    private func displayNotification(_ data: NotificationData) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            isShowingNotification = false
            processNextNotification()
            return
        }
        
        // Remove any existing notification
        currentNotification?.dismiss(animated: false)
        
        // Create new notification
        let notificationView = NotificationView(data: data)
        currentNotification = notificationView
        
        // Add to window
        window.addSubview(notificationView)
        notificationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notificationView.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 10),
            notificationView.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20),
            notificationView.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20)
        ])
        
        // Show with animation
        notificationView.show()
        
        // Trigger haptic feedback
        if let haptic = data.hapticFeedback {
            // Convert UIImpactFeedbackGenerator.FeedbackStyle to HapticFeedback.ImpactStyle
            let impactStyle: HapticFeedback.ImpactStyle
            switch haptic {
            case .light:
                impactStyle = .light
            case .medium:
                impactStyle = .medium
            case .heavy:
                impactStyle = .heavy
            case .soft:
                impactStyle = .soft
            case .rigid:
                impactStyle = .rigid
            default:
                impactStyle = .medium
            }
            HapticFeedback.shared.impact(impactStyle)
        }
        
        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + data.duration) { [weak self] in
            notificationView.dismiss {
                self?.currentNotification = nil
                self?.isShowingNotification = false
                self?.notificationQueue.async {
                    self?.processNextNotification()
                }
            }
        }
    }
}

// MARK: - Notification Data

struct NotificationData {
    let title: String
    let message: String
    let type: NotificationType
    let icon: String
    let duration: TimeInterval
    let hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle?
    
    enum NotificationType {
        case success
        case error
        case warning
        case info
        
        var backgroundColor: UIColor {
            switch self {
            case .success: return UIColor(red: 0.22, green: 1.0, blue: 0.08, alpha: 0.95) // Neon green
            case .error: return UIColor(red: 1.0, green: 0.03, blue: 0.43, alpha: 0.95) // Neon pink
            case .warning: return UIColor(red: 1.0, green: 0.91, blue: 0, alpha: 0.95) // Neon yellow
            case .info: return UIColor(red: 0, green: 0.85, blue: 1.0, alpha: 0.95) // Neon cyan
            }
        }
        
        var iconColor: UIColor {
            return .black
        }
    }
}

// MARK: - Notification View

class NotificationView: UIView {
    
    // MARK: - Properties
    
    private let data: NotificationData
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private var dismissTimer: Timer?
    
    // MARK: - Initialization
    
    init(data: NotificationData) {
        self.data = data
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Configure container
        containerView.backgroundColor = data.type.backgroundColor
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = data.type.backgroundColor.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOpacity = 0.5
        
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Configure icon
        iconImageView.image = UIImage(systemName: data.icon)
        iconImageView.tintColor = data.type.iconColor
        iconImageView.contentMode = .scaleAspectFit
        
        // Configure title
        titleLabel.text = data.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = data.type.iconColor
        
        // Configure message
        messageLabel.text = data.message
        messageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        messageLabel.textColor = data.type.iconColor.withAlphaComponent(0.9)
        messageLabel.numberOfLines = 2
        
        // Add subviews
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        
        // Layout
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Message
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        // Initial state
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: -20)
        
        // Add tap gesture to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        dismiss()
    }
    
    // MARK: - Animations
    
    func show() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        dismissTimer?.invalidate()
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(translationX: 0, y: -20)
            }) { _ in
                self.removeFromSuperview()
                completion?()
            }
        } else {
            removeFromSuperview()
            completion?()
        }
    }
}

// HapticFeedback is defined in Core/Utils/HapticFeedback.swift