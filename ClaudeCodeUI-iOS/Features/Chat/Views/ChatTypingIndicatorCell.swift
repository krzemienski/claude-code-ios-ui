//
//  ChatTypingIndicatorCell.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-30.
//  Animated typing indicator cell for chat
//

import UIKit

// MARK: - ChatTypingIndicatorCell

/// Table view cell showing animated typing indicator with cyberpunk theme
final class ChatTypingIndicatorCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let bubbleView = UIView()
    private let dotsContainer = UIStackView()
    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()
    private let avatarImageView = UIImageView()
    private let labelView = UILabel()
    
    // MARK: - Properties
    
    private var animationTimer: Timer?
    private var pulseAnimation: CABasicAnimation?
    private var isAnimating = false
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    deinit {
        stopAnimating()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        setupBubbleView()
        setupAvatar()
        setupDotsContainer()
        setupDots()
        setupLabel()
        setupConstraints()
    }
    
    private func setupBubbleView() {
        bubbleView.backgroundColor = CyberpunkTheme.surface
        bubbleView.layer.cornerRadius = 18
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.borderColor = CyberpunkTheme.accentPink.cgColor
        
        // Add glow effect
        bubbleView.layer.shadowColor = CyberpunkTheme.accentPink.cgColor
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 0)
        bubbleView.layer.shadowOpacity = 0.3
        bubbleView.layer.shadowRadius = 8
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
    }
    
    private func setupAvatar() {
        avatarImageView.image = UIImage(systemName: "cpu")
        avatarImageView.tintColor = CyberpunkTheme.accentPink
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.layer.cornerRadius = 16
        avatarImageView.backgroundColor = CyberpunkTheme.surface
        avatarImageView.layer.borderWidth = 1
        avatarImageView.layer.borderColor = CyberpunkTheme.accentPink.cgColor
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(avatarImageView)
    }
    
    private func setupDotsContainer() {
        dotsContainer.axis = .horizontal
        dotsContainer.distribution = .equalSpacing
        dotsContainer.alignment = .center
        dotsContainer.spacing = 8
        dotsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        bubbleView.addSubview(dotsContainer)
    }
    
    private func setupDots() {
        [dot1, dot2, dot3].forEach { dot in
            dot.backgroundColor = CyberpunkTheme.accentPink
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            
            // Add glow to each dot
            dot.layer.shadowColor = CyberpunkTheme.accentPink.cgColor
            dot.layer.shadowOffset = CGSize(width: 0, height: 0)
            dot.layer.shadowOpacity = 0.5
            dot.layer.shadowRadius = 4
            
            dotsContainer.addArrangedSubview(dot)
            
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 8),
                dot.heightAnchor.constraint(equalToConstant: 8)
            ])
        }
    }
    
    private func setupLabel() {
        labelView.text = "Claude is thinking..."
        labelView.font = .preferredFont(forTextStyle: .caption1)
        labelView.textColor = CyberpunkTheme.textSecondary
        labelView.isHidden = true
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        bubbleView.addSubview(labelView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Avatar
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // Bubble
            bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(equalToConstant: 80),
            bubbleView.heightAnchor.constraint(equalToConstant: 40),
            
            // Dots container
            dotsContainer.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            dotsContainer.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            
            // Label (alternative to dots)
            labelView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor)
        ])
    }
    
    // MARK: - Animation
    
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // Start wave animation
        animateDots()
        
        // Pulse the bubble glow
        animateBubbleGlow()
        
        // Rotate avatar slightly
        animateAvatar()
    }
    
    func stopAnimating() {
        isAnimating = false
        
        // Stop all animations
        animationTimer?.invalidate()
        animationTimer = nil
        
        [dot1, dot2, dot3].forEach { dot in
            dot.layer.removeAllAnimations()
            dot.transform = .identity
            dot.alpha = 1.0
        }
        
        bubbleView.layer.removeAllAnimations()
        avatarImageView.layer.removeAllAnimations()
    }
    
    private func animateDots() {
        let dots = [dot1, dot2, dot3]
        let duration: TimeInterval = 0.4
        let delay: TimeInterval = 0.15
        
        for (index, dot) in dots.enumerated() {
            animateDotWave(dot: dot, delay: delay * Double(index), duration: duration)
        }
    }
    
    private func animateDotWave(dot: UIView, delay: TimeInterval, duration: TimeInterval) {
        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: [.repeat, .autoreverse, .curveEaseInOut],
            animations: {
                dot.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                dot.alpha = 0.5
            }
        )
    }
    
    private func animateBubbleGlow() {
        let pulseAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        pulseAnimation.fromValue = 0.3
        pulseAnimation.toValue = 0.6
        pulseAnimation.duration = 1.0
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        bubbleView.layer.add(pulseAnimation, forKey: "pulse")
        
        // Also animate border opacity
        let borderAnimation = CABasicAnimation(keyPath: "borderColor")
        borderAnimation.fromValue = CyberpunkTheme.accentPink.cgColor
        borderAnimation.toValue = CyberpunkTheme.accentPink.withAlphaComponent(0.5).cgColor
        borderAnimation.duration = 1.0
        borderAnimation.autoreverses = true
        borderAnimation.repeatCount = .infinity
        borderAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        bubbleView.layer.add(borderAnimation, forKey: "borderPulse")
    }
    
    private func animateAvatar() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = -0.05
        rotationAnimation.toValue = 0.05
        rotationAnimation.duration = 2.0
        rotationAnimation.autoreverses = true
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        avatarImageView.layer.add(rotationAnimation, forKey: "rotation")
    }
    
    // MARK: - Configuration
    
    func configure(withText text: String? = nil) {
        if let text = text {
            // Show custom text instead of dots
            labelView.text = text
            labelView.isHidden = false
            dotsContainer.isHidden = true
        } else {
            // Show animated dots
            labelView.isHidden = true
            dotsContainer.isHidden = false
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopAnimating()
        configure(withText: nil)
    }
}

// MARK: - Cyberpunk Theme Extension

private extension CyberpunkTheme {
    static func createTypingGradient() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [
            primaryCyan.cgColor,
            accentPink.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        return gradient
    }
}