import UIKit

/// A cyberpunk-themed progress indicator for long operations
class ProgressIndicatorView: UIView {
    
    // MARK: - Properties
    
    private let containerView = UIView()
    private let progressBar = UIProgressView()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let percentageLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    private let glowLayer = CAGradientLayer()
    
    var onCancel: (() -> Void)?
    
    private var displayLink: CADisplayLink?
    private var targetProgress: Float = 0
    private var currentProgress: Float = 0
    
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
        // Configure background
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        // Setup container
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = CyberpunkTheme.neonCyan.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Add glow effect
        setupGlowEffect()
        
        // Setup title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = CyberpunkTheme.neonCyan
        titleLabel.textAlignment = .center
        titleLabel.text = "Processing..."
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Setup progress bar
        progressBar.progressTintColor = CyberpunkTheme.neonCyan
        progressBar.trackTintColor = UIColor.gray.withAlphaComponent(0.3)
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(progressBar)
        
        // Setup percentage label
        percentageLabel.font = .monospacedSystemFont(ofSize: 24, weight: .bold)
        percentageLabel.textColor = CyberpunkTheme.neonCyan
        percentageLabel.textAlignment = .center
        percentageLabel.text = "0%"
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(percentageLabel)
        
        // Setup status label
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .lightGray
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.text = "Please wait..."
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)
        
        // Setup cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.setTitleColor(CyberpunkTheme.neonPink, for: .normal)
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = CyberpunkTheme.neonPink.cgColor
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            percentageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            percentageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            progressBar.topAnchor.constraint(equalTo: percentageLabel.bottomAnchor, constant: 20),
            progressBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            progressBar.heightAnchor.constraint(equalToConstant: 8),
            
            statusLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            cancelButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 36),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupGlowEffect() {
        glowLayer.colors = [
            CyberpunkTheme.neonCyan.withAlphaComponent(0.3).cgColor,
            CyberpunkTheme.neonCyan.withAlphaComponent(0.1).cgColor,
            UIColor.clear.cgColor
        ]
        glowLayer.locations = [0, 0.5, 1]
        glowLayer.frame = containerView.bounds
        containerView.layer.insertSublayer(glowLayer, at: 0)
    }
    
    // MARK: - Public Methods
    
    func show(title: String = "Processing...", in view: UIView) {
        titleLabel.text = title
        
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        animateIn()
    }
    
    func updateProgress(_ progress: Float, status: String? = nil) {
        targetProgress = min(max(progress, 0), 1)
        
        if let status = status {
            statusLabel.text = status
        }
        
        // Start display link for smooth animation
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(updateProgressAnimation))
            displayLink?.add(to: .main, forMode: .common)
        }
    }
    
    func setIndeterminate(_ indeterminate: Bool) {
        if indeterminate {
            // Create pulsing animation
            let pulseAnimation = CABasicAnimation(keyPath: "opacity")
            pulseAnimation.fromValue = 0.3
            pulseAnimation.toValue = 1.0
            pulseAnimation.duration = 1.0
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = .infinity
            progressBar.layer.add(pulseAnimation, forKey: "pulse")
            
            percentageLabel.text = "..."
        } else {
            progressBar.layer.removeAnimation(forKey: "pulse")
        }
    }
    
    func dismiss(completion: (() -> Void)? = nil) {
        displayLink?.invalidate()
        displayLink = nil
        
        animateOut {
            completion?()
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        onCancel?()
        dismiss()
    }
    
    @objc private func updateProgressAnimation() {
        // Smooth progress animation
        let delta = (targetProgress - currentProgress) * 0.1
        currentProgress += delta
        
        progressBar.setProgress(currentProgress, animated: false)
        percentageLabel.text = "\(Int(currentProgress * 100))%"
        
        if abs(targetProgress - currentProgress) < 0.001 {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
    
    // MARK: - Animations
    
    private func animateIn() {
        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    private func animateOut(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        glowLayer.frame = containerView.bounds
    }
}

// MARK: - Convenience Extension

extension UIViewController {
    func showProgressIndicator(title: String = "Processing...") -> ProgressIndicatorView {
        let indicator = ProgressIndicatorView()
        indicator.show(title: title, in: view)
        return indicator
    }
}