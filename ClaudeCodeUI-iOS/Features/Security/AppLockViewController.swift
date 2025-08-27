import UIKit
import LocalAuthentication

/// App lock screen with biometric authentication
class AppLockViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    private let lockIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = CyberpunkTheme.primaryCyan
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Claude Code Locked"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .lightGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var authenticateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Authenticate", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = CyberpunkTheme.accentPink
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(authenticateButtonTapped), for: .touchUpInside)
        
        // Add glow effect
        button.layer.shadowColor = CyberpunkTheme.accentPink.cgColor
        button.layer.shadowRadius = 10
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = .zero
        
        return button
    }()
    
    private let biometricAuthManager = BiometricAuthManager.shared
    private var unlockCompletion: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBiometricIcon()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Auto-trigger authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.performAuthentication()
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add blur background
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)
        
        // Add elements
        view.addSubview(lockIconView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(authenticateButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Lock icon
            lockIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lockIconView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150),
            lockIconView.widthAnchor.constraint(equalToConstant: 120),
            lockIconView.heightAnchor.constraint(equalToConstant: 120),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: lockIconView.bottomAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // Authenticate button
            authenticateButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            authenticateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authenticateButton.widthAnchor.constraint(equalToConstant: 200),
            authenticateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add animations
        addPulseAnimation()
    }
    
    private func setupBiometricIcon() {
        let biometricType = getBiometricType()
        
        switch biometricType {
        case .faceID:
            lockIconView.image = UIImage(systemName: "faceid")
            subtitleLabel.text = "Use Face ID to unlock"
            authenticateButton.setTitle("Unlock with Face ID", for: .normal)
            
        case .touchID:
            lockIconView.image = UIImage(systemName: "touchid")
            subtitleLabel.text = "Use Touch ID to unlock"
            authenticateButton.setTitle("Unlock with Touch ID", for: .normal)
            
        case .opticID:
            lockIconView.image = UIImage(systemName: "opticid")
            subtitleLabel.text = "Use Optic ID to unlock"
            authenticateButton.setTitle("Unlock with Optic ID", for: .normal)
            
        default:
            lockIconView.image = UIImage(systemName: "lock.shield")
            subtitleLabel.text = "Enter your passcode to unlock"
            authenticateButton.setTitle("Enter Passcode", for: .normal)
        }
    }
    
    private func getBiometricType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        return context.biometryType
    }
    
    // MARK: - Actions
    
    @objc private func authenticateButtonTapped() {
        performAuthentication()
    }
    
    private func performAuthentication() {
        Task {
            do {
                // Show loading state
                authenticateButton.isEnabled = false
                authenticateButton.alpha = 0.6
                
                try await biometricAuthManager.authenticateWithPasscodeFallback(
                    reason: "Authenticate to unlock Claude Code"
                )
                
                // Success
                await unlockApp()
                
            } catch {
                // Handle error
                await MainActor.run {
                    authenticateButton.isEnabled = true
                    authenticateButton.alpha = 1.0
                    showError(error)
                }
            }
        }
    }
    
    @MainActor
    private func unlockApp() {
        // Play success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Animate unlock
        UIView.animate(withDuration: 0.3, animations: {
            self.lockIconView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.lockIconView.alpha = 0
            self.view.alpha = 0
        }) { _ in
            self.unlockCompletion?()
            self.dismiss(animated: false)
        }
    }
    
    private func showError(_ error: Error) {
        // Shake animation
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        lockIconView.layer.add(animation, forKey: "shake")
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Update UI
        subtitleLabel.text = error.localizedDescription
        subtitleLabel.textColor = CyberpunkTheme.accentPink
        
        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.setupBiometricIcon()
            self?.subtitleLabel.textColor = .lightGray
        }
    }
    
    // MARK: - Animations
    
    private func addPulseAnimation() {
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.duration = 2.0
        pulse.fromValue = 0.5
        pulse.toValue = 1.0
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        
        lockIconView.layer.add(pulse, forKey: "pulse")
    }
    
    // MARK: - Public Methods
    
    static func present(from viewController: UIViewController, completion: (() -> Void)? = nil) {
        let lockVC = AppLockViewController()
        lockVC.unlockCompletion = completion
        lockVC.modalPresentationStyle = .fullScreen
        lockVC.modalTransitionStyle = .crossDissolve
        viewController.present(lockVC, animated: true)
    }
}

// MARK: - App Lock Manager

class AppLockManager {
    static let shared = AppLockManager()
    private init() {}
    
    private var lockTimer: Timer?
    private let lockTimeout: TimeInterval = 180 // 3 minutes
    private var isLocked = false
    
    /// Start monitoring for app lock
    func startMonitoring() {
        // Monitor app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Monitor user activity
        resetLockTimer()
    }
    
    @objc private func appDidEnterBackground() {
        // Start lock timer
        lockTimer?.invalidate()
        lockTimer = Timer.scheduledTimer(withTimeInterval: lockTimeout, repeats: false) { [weak self] _ in
            self?.isLocked = true
        }
    }
    
    @objc private func appWillEnterForeground() {
        if isLocked {
            presentLockScreen()
        }
    }
    
    private func presentLockScreen() {
        guard let window = UIApplication.shared.windows.first,
              let rootViewController = window.rootViewController else { return }
        
        // Check if lock screen is already presented
        if rootViewController.presentedViewController is AppLockViewController {
            return
        }
        
        AppLockViewController.present(from: rootViewController) { [weak self] in
            self?.isLocked = false
            self?.resetLockTimer()
        }
    }
    
    func resetLockTimer() {
        lockTimer?.invalidate()
        lockTimer = nil
        isLocked = false
    }
    
    func lock() {
        isLocked = true
        presentLockScreen()
    }
}