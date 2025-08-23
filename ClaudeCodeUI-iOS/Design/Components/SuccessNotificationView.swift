import UIKit

/// A cyberpunk-themed success notification view with animations
class SuccessNotificationView: UIView {
    
    // MARK: - Properties
    
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let glowLayer = CALayer()
    private var dismissTimer: Timer?
    
    // Configuration
    var autoDismissDelay: TimeInterval = 3.0
    var hapticFeedback: Bool = true
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // Configure self
        backgroundColor = UIColor.black.withAlphaComponent(0.95)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = CyberpunkTheme.neonGreen.cgColor
        
        // Add glow effect
        setupGlowEffect()
        
        // Setup icon
        iconView.image = UIImage(systemName: "checkmark.circle.fill")
        iconView.tintColor = CyberpunkTheme.neonGreen
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        
        // Setup title label
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = CyberpunkTheme.neonGreen
        titleLabel.text = "Success"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // Setup message label
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
    
    private func setupGlowEffect() {
        glowLayer.shadowColor = CyberpunkTheme.neonGreen.cgColor
        glowLayer.shadowRadius = 10
        glowLayer.shadowOpacity = 0.8
        glowLayer.shadowOffset = .zero
        layer.insertSublayer(glowLayer, at: 0)
    }
    
    // MARK: - Public Methods
    
    func show(message: String, title: String = "Success", in view: UIView) {
        titleLabel.text = title
        messageLabel.text = message
        
        // Add to view
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        // Animate in
        animateIn()
        
        // Haptic feedback
        if hapticFeedback {
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
        }
        
        // Auto dismiss
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissDelay, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
    
    func dismiss() {
        dismissTimer?.invalidate()
        animateOut()
    }
    
    // MARK: - Animations
    
    private func animateIn() {
        // Initial state
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: 0, y: -20)
        
        // Animate
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
        
        // Pulse glow
        let pulseAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        pulseAnimation.fromValue = 0.8
        pulseAnimation.toValue = 0.3
        pulseAnimation.duration = 1.0
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        glowLayer.add(pulseAnimation, forKey: "pulse")
    }
    
    private func animateOut() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: 0, y: -20)
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

// MARK: - Convenience Methods

extension UIViewController {
    func showSuccessNotification(_ message: String, title: String = "Success") {
        let notification = SuccessNotificationView()
        notification.show(message: message, title: title, in: view)
    }
}