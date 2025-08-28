//
//  CyberpunkButton.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-20.
//

import UIKit

/// Enhanced button component with cyberpunk-themed animations and effects
public class CyberpunkButton: UIButton {
    
    // MARK: - Button Styles
    
    public enum ButtonStyle {
        case primary      // Cyan with glow
        case secondary    // Pink accent
        case outline      // Transparent with border
        case ghost        // Minimal style
        case destructive  // Red for dangerous actions
        case success      // Green for positive actions
    }
    
    public enum ButtonSize {
        case small        // 32pt height
        case medium       // 44pt height
        case large        // 56pt height
        case custom(CGFloat)
        
        var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            case .custom(let height): return height
            }
        }
    }
    
    // MARK: - Properties
    
    private var style: ButtonStyle = .primary
    private var size: ButtonSize = .medium
    private var isAnimating = false
    private var glowLayer: CALayer?
    private var borderLayer: CAShapeLayer?
    private var backgroundGradientLayer: CAGradientLayer?
    
    // Animation properties
    private var pulseTimer: Timer?
    private var glowAnimation: CABasicAnimation?
    
    // MARK: - Initialization
    
    public init(style: ButtonStyle = .primary, size: ButtonSize = .medium) {
        self.style = style
        self.size = size
        super.init(frame: .zero)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    // MARK: - Setup
    
    private func setupButton() {
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.font = CyberpunkTheme.bodyFont
        layer.cornerRadius = 12
        layer.masksToBounds = false
        
        // Set height constraint
        heightAnchor.constraint(equalToConstant: size.height).isActive = true
        
        // Apply style
        applyStyle()
        
        // Add touch events
        addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        // Add hover effect for Mac Catalyst
        if #available(iOS 14.0, *) {
            addTarget(self, action: #selector(buttonHoverEnter), for: .touchDragEnter)
            addTarget(self, action: #selector(buttonHoverExit), for: .touchDragExit)
        }
    }
    
    private func applyStyle() {
        switch style {
        case .primary:
            setupPrimaryStyle()
        case .secondary:
            setupSecondaryStyle()
        case .outline:
            setupOutlineStyle()
        case .ghost:
            setupGhostStyle()
        case .destructive:
            setupDestructiveStyle()
        case .success:
            setupSuccessStyle()
        }
    }
    
    private func setupPrimaryStyle() {
        backgroundColor = CyberpunkTheme.primaryCyan
        setTitleColor(.black, for: .normal)
        setTitleColor(.black.withAlphaComponent(0.7), for: .highlighted)
        
        // Add gradient background
        setupGradientBackground([
            CyberpunkTheme.primaryCyan.cgColor,
            CyberpunkTheme.primaryCyan.withAlphaComponent(0.8).cgColor
        ])
        
        // Add glow effect
        setupGlowEffect(color: CyberpunkTheme.primaryCyan)
    }
    
    private func setupSecondaryStyle() {
        backgroundColor = CyberpunkTheme.accentPink
        setTitleColor(.white, for: .normal)
        setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
        
        setupGradientBackground([
            CyberpunkTheme.accentPink.cgColor,
            CyberpunkTheme.accentPink.withAlphaComponent(0.8).cgColor
        ])
        
        setupGlowEffect(color: CyberpunkTheme.accentPink)
    }
    
    private func setupOutlineStyle() {
        backgroundColor = .clear
        setTitleColor(CyberpunkTheme.primaryCyan, for: .normal)
        setTitleColor(CyberpunkTheme.primaryCyan.withAlphaComponent(0.7), for: .highlighted)
        
        setupBorderEffect(color: CyberpunkTheme.primaryCyan)
    }
    
    private func setupGhostStyle() {
        backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.5)
        setTitleColor(CyberpunkTheme.primaryText, for: .normal)
        setTitleColor(CyberpunkTheme.primaryText.withAlphaComponent(0.7), for: .highlighted)
        
        layer.borderWidth = 1
        layer.borderColor = CyberpunkTheme.border.cgColor
    }
    
    private func setupDestructiveStyle() {
        backgroundColor = CyberpunkTheme.error
        setTitleColor(.white, for: .normal)
        setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
        
        setupGlowEffect(color: CyberpunkTheme.error)
    }
    
    private func setupSuccessStyle() {
        backgroundColor = CyberpunkTheme.success
        setTitleColor(.black, for: .normal)
        setTitleColor(.black.withAlphaComponent(0.7), for: .highlighted)
        
        setupGlowEffect(color: CyberpunkTheme.success)
    }
    
    private func setupGradientBackground(_ colors: [CGColor]) {
        backgroundGradientLayer?.removeFromSuperlayer()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = layer.cornerRadius
        
        layer.insertSublayer(gradientLayer, at: 0)
        backgroundGradientLayer = gradientLayer
    }
    
    private func setupGlowEffect(color: UIColor) {
        layer.shadowColor = color.cgColor
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.6
        layer.shadowOffset = .zero
    }
    
    private func setupBorderEffect(color: UIColor) {
        borderLayer?.removeFromSuperlayer()
        
        let borderLayer = CAShapeLayer()
        borderLayer.strokeColor = color.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 2
        borderLayer.cornerRadius = layer.cornerRadius
        
        layer.addSublayer(borderLayer)
        self.borderLayer = borderLayer
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        backgroundGradientLayer?.frame = bounds
        
        // Update border frame
        if let borderLayer = borderLayer {
            borderLayer.frame = bounds
            borderLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        }
    }
    
    // MARK: - Touch Handling
    
    @objc private func buttonTouchDown() {
        // Scale down animation
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseOut],
            animations: {
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        )
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Enhance glow effect
        if layer.shadowOpacity > 0 {
            layer.shadowOpacity = 0.9
        }
    }
    
    @objc private func buttonTouchUp() {
        // Scale back up animation
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: [.allowUserInteraction, .curveEaseOut],
            animations: {
                self.transform = .identity
            }
        )
        
        // Restore glow effect
        if layer.shadowOpacity > 0.6 {
            UIView.animate(withDuration: 0.3) {
                self.layer.shadowOpacity = 0.6
            }
        }
    }
    
    @objc private func buttonHoverEnter() {
        UIView.animate(withDuration: 0.2) {
            self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            self.layer.shadowOpacity = 0.9
        }
    }
    
    @objc private func buttonHoverExit() {
        UIView.animate(withDuration: 0.2) {
            self.transform = .identity
            self.layer.shadowOpacity = 0.6
        }
    }
    
    // MARK: - Loading State
    
    public func setLoading(_ loading: Bool, animated: Bool = true) {
        if loading {
            startLoadingAnimation()
        } else {
            stopLoadingAnimation()
        }
    }
    
    private func startLoadingAnimation() {
        isEnabled = false
        
        // Hide title
        titleLabel?.alpha = 0
        
        // Add loading spinner
        let spinner = createLoadingSpinner()
        addSubview(spinner)
        spinner.center = CGPoint(x: bounds.midX, y: bounds.midY)
        spinner.tag = 999 // For identification
        
        // Start spinner animation
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.duration = 1.0
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = 2 * Double.pi
        rotationAnimation.repeatCount = .infinity
        spinner.layer.add(rotationAnimation, forKey: "rotation")
    }
    
    private func stopLoadingAnimation() {
        isEnabled = true
        
        // Show title
        UIView.animate(withDuration: 0.3) {
            self.titleLabel?.alpha = 1
        }
        
        // Remove spinner
        viewWithTag(999)?.removeFromSuperview()
    }
    
    private func createLoadingSpinner() -> UIView {
        let size: CGFloat = min(bounds.height * 0.6, 24)
        let spinner = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        
        let circle = CAShapeLayer()
        let path = UIBezierPath(arcCenter: CGPoint(x: size/2, y: size/2), radius: size/2 - 2, startAngle: 0, endAngle: 1.5 * .pi, clockwise: true)
        
        circle.path = path.cgPath
        circle.strokeColor = (titleColor(for: .normal) ?? .white).cgColor
        circle.fillColor = UIColor.clear.cgColor
        circle.lineWidth = 2
        circle.lineCap = .round
        
        spinner.layer.addSublayer(circle)
        return spinner
    }
    
    // MARK: - Pulse Animation
    
    public func startPulseAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.05
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        layer.add(pulseAnimation, forKey: "pulse")
    }
    
    public func stopPulseAnimation() {
        isAnimating = false
        layer.removeAnimation(forKey: "pulse")
    }
    
    // MARK: - Configuration Methods
    
    public func setStyle(_ style: ButtonStyle) {
        self.style = style
        applyStyle()
    }
    
    public func setSize(_ size: ButtonSize) {
        self.size = size
        
        // Update height constraint
        for constraint in constraints {
            if constraint.firstAttribute == .height {
                constraint.constant = size.height
            }
        }
    }
    
    // MARK: - Success/Error States
    
    public func showSuccess(completion: (() -> Void)? = nil) {
        let originalTitle = title(for: .normal)
        let originalColor = backgroundColor
        
        // Change to success state
        setTitle("✓", for: .normal)
        backgroundColor = CyberpunkTheme.success
        
        // Scale animation
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
        ) { _ in
            UIView.animate(
                withDuration: 0.3,
                delay: 0.5,
                animations: {
                    self.transform = .identity
                    self.setTitle(originalTitle, for: .normal)
                    self.backgroundColor = originalColor
                }
            ) { _ in
                completion?()
            }
        }
    }
    
    public func showError(completion: (() -> Void)? = nil) {
        let originalTitle = title(for: .normal)
        let originalColor = backgroundColor
        
        // Change to error state
        setTitle("✗", for: .normal)
        backgroundColor = CyberpunkTheme.error
        
        // Shake animation
        let shake = CABasicAnimation(keyPath: "position")
        shake.duration = 0.1
        shake.repeatCount = 2
        shake.autoreverses = true
        shake.fromValue = NSValue(cgPoint: CGPoint(x: center.x - 5, y: center.y))
        shake.toValue = NSValue(cgPoint: CGPoint(x: center.x + 5, y: center.y))
        
        layer.add(shake, forKey: "shake")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.setTitle(originalTitle, for: .normal)
                    self.backgroundColor = originalColor
                }
            ) { _ in
                completion?()
            }
        }
    }
}

// MARK: - Convenience Initializers

extension CyberpunkButton {
    
    public static func primary(title: String, size: ButtonSize = .medium) -> CyberpunkButton {
        let button = CyberpunkButton(style: .primary, size: size)
        button.setTitle(title, for: .normal)
        return button
    }
    
    public static func secondary(title: String, size: ButtonSize = .medium) -> CyberpunkButton {
        let button = CyberpunkButton(style: .secondary, size: size)
        button.setTitle(title, for: .normal)
        return button
    }
    
    public static func outline(title: String, size: ButtonSize = .medium) -> CyberpunkButton {
        let button = CyberpunkButton(style: .outline, size: size)
        button.setTitle(title, for: .normal)
        return button
    }
    
    public static func destructive(title: String, size: ButtonSize = .medium) -> CyberpunkButton {
        let button = CyberpunkButton(style: .destructive, size: size)
        button.setTitle(title, for: .normal)
        return button
    }
}