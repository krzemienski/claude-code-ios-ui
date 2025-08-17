//
//  NoDataView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-16.
//

import UIKit

/// A reusable empty state view with cyberpunk ASCII art and customizable messages
public class NoDataView: UIView {
    
    // MARK: - Properties
    
    private let containerView = UIView()
    private let artLabel = UILabel()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private var actionHandler: (() -> Void)?
    
    /// Predefined ASCII art patterns for different empty states
    public enum ArtStyle {
        case noData
        case noConnection
        case noResults
        case error
        case custom(String)
        
        var ascii: String {
            switch self {
            case .noData:
                return """
                ╔═══════════════╗
                ║   NO DATA     ║
                ║   ┌─────┐     ║
                ║   │ 404 │     ║
                ║   └─────┘     ║
                ╚═══════════════╝
                """
            case .noConnection:
                return """
                    ╱╲
                   ╱  ╲
                  ╱ ⚠  ╲
                 ╱______╲
                [OFFLINE]
                """
            case .noResults:
                return """
                ┌──────────┐
                │ SEARCH   │
                │  ∅ → 0   │
                │ RESULTS  │
                └──────────┘
                """
            case .error:
                return """
                ╔════════╗
                ║ ERROR! ║
                ║   ✕    ║
                ║ SYSTEM ║
                ╚════════╝
                """
            case .custom(let art):
                return art
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
        backgroundColor = CyberpunkTheme.background
        
        // Container setup
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // ASCII Art label
        artLabel.translatesAutoresizingMaskIntoConstraints = false
        artLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        artLabel.textColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.6)
        artLabel.numberOfLines = 0
        artLabel.textAlignment = .center
        containerView.addSubview(artLabel)
        
        // Add glow effect to ASCII art
        artLabel.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        artLabel.layer.shadowRadius = 8
        artLabel.layer.shadowOpacity = 0.3
        artLabel.layer.shadowOffset = .zero
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = CyberpunkTheme.titleFont
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
        
        // Action button
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        actionButton.setTitleColor(UIColor.black, for: .normal)
        actionButton.backgroundColor = CyberpunkTheme.primaryCyan
        actionButton.layer.cornerRadius = 12
        actionButton.isHidden = true
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        containerView.addSubview(actionButton)
        
        // Add glow effect to button
        actionButton.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        actionButton.layer.shadowRadius = 8
        actionButton.layer.shadowOpacity = 0.5
        actionButton.layer.shadowOffset = .zero
        
        setupConstraints()
        addAnimations()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40),
            
            // ASCII Art
            artLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            artLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: artLabel.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Message
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Button
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            actionButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            actionButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            actionButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            actionButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor)
        ])
    }
    
    // MARK: - Animations
    
    private func addAnimations() {
        // Pulse animation for ASCII art
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.duration = 2.0
        pulseAnimation.fromValue = 0.6
        pulseAnimation.toValue = 1.0
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        artLabel.layer.add(pulseAnimation, forKey: "pulse")
        
        // Subtle float animation
        let floatAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        floatAnimation.duration = 3.0
        floatAnimation.fromValue = -5
        floatAnimation.toValue = 5
        floatAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        floatAnimation.autoreverses = true
        floatAnimation.repeatCount = .infinity
        containerView.layer.add(floatAnimation, forKey: "float")
    }
    
    // MARK: - Configuration
    
    /// Configures the empty state view
    public func configure(
        artStyle: ArtStyle = .noData,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        artLabel.text = artStyle.ascii
        titleLabel.text = title
        messageLabel.text = message
        
        if let buttonTitle = buttonTitle {
            actionButton.setTitle(buttonTitle, for: .normal)
            actionButton.isHidden = false
            actionHandler = buttonAction
        } else {
            actionButton.isHidden = true
            actionHandler = nil
        }
    }
    
    /// Shows the empty state view with animation
    public func show(animated: Bool = true) {
        isHidden = false
        
        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: .curveEaseOut,
                animations: {
                    self.alpha = 1
                    self.transform = .identity
                }
            )
        } else {
            alpha = 1
            transform = .identity
        }
    }
    
    /// Hides the empty state view with animation
    public func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated {
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.alpha = 0
                    self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
            ) { _ in
                self.isHidden = true
                self.transform = .identity
                completion?()
            }
        } else {
            isHidden = true
            alpha = 0
            completion?()
        }
    }
    
    // MARK: - Actions
    
    @objc private func actionButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Button press animation
        UIView.animate(withDuration: 0.1, animations: {
            self.actionButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.actionButton.transform = .identity
            }
        }
        
        actionHandler?()
    }
}

// MARK: - Geometric Pattern View

/// A view that displays animated geometric patterns for empty states
public class GeometricPatternView: UIView {
    
    private var shapeLayer = CAShapeLayer()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPattern()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPattern()
    }
    
    private func setupPattern() {
        backgroundColor = .clear
        
        // Create geometric pattern
        let path = UIBezierPath()
        
        // Draw hexagon pattern
        let size: CGFloat = 40
        let columns = 5
        let rows = 5
        
        for row in 0..<rows {
            for col in 0..<columns {
                let x = CGFloat(col) * size * 1.5 + (row % 2 == 0 ? 0 : size * 0.75)
                let y = CGFloat(row) * size * 1.5
                drawHexagon(at: CGPoint(x: x, y: y), size: size / 2, in: path)
            }
        }
        
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.2).cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 1
        layer.addSublayer(shapeLayer)
        
        // Add animation
        animatePattern()
    }
    
    private func drawHexagon(at center: CGPoint, size: CGFloat, in path: UIBezierPath) {
        let angles: [CGFloat] = [0, 60, 120, 180, 240, 300].map { $0 * .pi / 180 }
        
        for (index, angle) in angles.enumerated() {
            let x = center.x + size * cos(angle)
            let y = center.y + size * sin(angle)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.close()
    }
    
    private func animatePattern() {
        // Stroke animation
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.duration = 3.0
        strokeAnimation.fromValue = 0
        strokeAnimation.toValue = 1
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        strokeAnimation.repeatCount = .infinity
        
        // Opacity animation
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.duration = 2.0
        opacityAnimation.fromValue = 0.2
        opacityAnimation.toValue = 0.6
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity
        
        shapeLayer.add(strokeAnimation, forKey: "stroke")
        shapeLayer.add(opacityAnimation, forKey: "opacity")
    }
}