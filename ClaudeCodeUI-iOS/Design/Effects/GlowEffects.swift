//
//  GlowEffects.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025/01/05.
//

import UIKit

// MARK: - Glow Effect Extension
extension UIView {
    
    /// Add a cyberpunk glow effect to the view
    func addCyberpunkGlow(color: UIColor = CyberpunkTheme.primaryCyan, 
                          intensity: CGFloat = 0.8,
                          radius: CGFloat = 10) {
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOpacity = Float(intensity)
        layer.shadowOffset = .zero
        layer.masksToBounds = false
    }
    
    /// Add an animated pulsing glow effect
    func addPulsingGlow(color: UIColor = CyberpunkTheme.primaryCyan,
                       duration: TimeInterval = 2.0) {
        // Add base glow
        addCyberpunkGlow(color: color)
        
        // Create pulsing animation
        let pulseAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        pulseAnimation.fromValue = 0.3
        pulseAnimation.toValue = 0.9
        pulseAnimation.duration = duration
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        layer.add(pulseAnimation, forKey: "pulseGlow")
    }
    
    /// Remove glow effect
    func removeGlow() {
        layer.shadowColor = UIColor.clear.cgColor
        layer.shadowRadius = 0
        layer.shadowOpacity = 0
        layer.shadowOffset = .zero
        layer.removeAnimation(forKey: "pulseGlow")
    }
    
    /// Add neon border with glow
    func addNeonBorder(color: UIColor = CyberpunkTheme.primaryCyan,
                       width: CGFloat = 2.0,
                       cornerRadius: CGFloat = 16.0) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        layer.cornerRadius = cornerRadius
        addCyberpunkGlow(color: color, intensity: 0.6, radius: 8)
    }
    
    /// Add interactive glow that responds to touch
    func addInteractiveGlow() {
        isUserInteractionEnabled = true
        
        // Add gesture recognizers
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleGlowTap))
        addGestureRecognizer(tapGesture)
        
        let pressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleGlowPress))
        pressGesture.minimumPressDuration = 0.1
        addGestureRecognizer(pressGesture)
    }
    
    @objc private func handleGlowTap() {
        // Flash glow effect
        UIView.animate(withDuration: 0.1, animations: {
            self.layer.shadowOpacity = 1.0
            self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.layer.shadowOpacity = 0.6
                self.transform = .identity
            }
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func handleGlowPress(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1) {
                self.layer.shadowOpacity = 1.0
                self.layer.shadowRadius = 15
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.2) {
                self.layer.shadowOpacity = 0.6
                self.layer.shadowRadius = 10
                self.transform = .identity
            }
        default:
            break
        }
    }
}

// MARK: - Animated Scanline Effect
class ScanlineView: UIView {
    private let scanlineLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScanline()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScanline()
    }
    
    private func setupScanline() {
        // Configure gradient
        scanlineLayer.colors = [
            UIColor.clear.cgColor,
            CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor,
            CyberpunkTheme.primaryCyan.withAlphaComponent(0.5).cgColor,
            CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        scanlineLayer.locations = [0, 0.4, 0.5, 0.6, 1]
        scanlineLayer.startPoint = CGPoint(x: 0, y: 0)
        scanlineLayer.endPoint = CGPoint(x: 0, y: 1)
        
        layer.addSublayer(scanlineLayer)
        
        // Start animation
        startScanlineAnimation()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scanlineLayer.frame = CGRect(x: 0, y: -bounds.height, width: bounds.width, height: bounds.height * 0.2)
    }
    
    private func startScanlineAnimation() {
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = -bounds.height * 0.2
        animation.toValue = bounds.height + bounds.height * 0.2
        animation.duration = 3.0
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        scanlineLayer.add(animation, forKey: "scanline")
    }
}

// MARK: - Matrix Rain Effect
class MatrixRainView: UIView {
    private var columns: [MatrixColumn] = []
    private var displayLink: CADisplayLink?
    
    private class MatrixColumn {
        var characters: [String] = []
        var position: CGFloat = 0
        var speed: CGFloat = 0
        let x: CGFloat
        
        init(x: CGFloat) {
            self.x = x
            self.speed = CGFloat.random(in: 2...8)
            self.position = CGFloat.random(in: -500...0)
            
            // Generate random characters
            let chars = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789"
            for _ in 0..<20 {
                let randomIndex = chars.index(chars.startIndex, offsetBy: Int.random(in: 0..<chars.count))
                characters.append(String(chars[randomIndex]))
            }
        }
        
        func update() {
            position += speed
            if position > UIScreen.main.bounds.height + 500 {
                position = -500
                speed = CGFloat.random(in: 2...8)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMatrix()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMatrix()
    }
    
    private func setupMatrix() {
        backgroundColor = .clear
        
        // Create columns
        let columnWidth: CGFloat = 20
        let numberOfColumns = Int(bounds.width / columnWidth)
        
        for i in 0..<numberOfColumns {
            let column = MatrixColumn(x: CGFloat(i) * columnWidth)
            columns.append(column)
        }
        
        // Start animation
        displayLink = CADisplayLink(target: self, selector: #selector(updateMatrix))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    @objc private func updateMatrix() {
        for column in columns {
            column.update()
        }
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        for column in columns {
            for (index, char) in column.characters.enumerated() {
                let y = column.position + CGFloat(index * 20)
                
                // Calculate alpha based on position
                let alpha = max(0, min(1, 1 - (CGFloat(index) / CGFloat(column.characters.count))))
                
                // Draw character
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                    .foregroundColor: CyberpunkTheme.primaryCyan.withAlphaComponent(alpha)
                ]
                
                let attributedString = NSAttributedString(string: char, attributes: attributes)
                attributedString.draw(at: CGPoint(x: column.x, y: y))
            }
        }
    }
    
    deinit {
        displayLink?.invalidate()
    }
}

// MARK: - Holographic Shimmer Effect
extension UIView {
    func addHolographicShimmer() {
        let shimmerLayer = CAGradientLayer()
        shimmerLayer.frame = bounds
        shimmerLayer.colors = [
            UIColor.clear.cgColor,
            CyberpunkTheme.primaryCyan.withAlphaComponent(0.2).cgColor,
            CyberpunkTheme.accentPink.withAlphaComponent(0.2).cgColor,
            UIColor.clear.cgColor
        ]
        shimmerLayer.locations = [0, 0.4, 0.6, 1]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0, 0, 0.1, 0.2]
        animation.toValue = [0.8, 0.9, 1, 1]
        animation.duration = 2.0
        animation.repeatCount = .infinity
        
        shimmerLayer.add(animation, forKey: "shimmer")
        layer.addSublayer(shimmerLayer)
    }
}

// MARK: - Loading Spinner with Glow
class CyberpunkSpinner: UIView {
    private let spinnerLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSpinner()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSpinner()
    }
    
    private func setupSpinner() {
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                radius: min(bounds.width, bounds.height) / 2 - 5,
                                startAngle: 0,
                                endAngle: .pi * 1.5,
                                clockwise: true)
        
        spinnerLayer.path = path.cgPath
        spinnerLayer.strokeColor = CyberpunkTheme.primaryCyan.cgColor
        spinnerLayer.fillColor = UIColor.clear.cgColor
        spinnerLayer.lineWidth = 3
        spinnerLayer.lineCap = .round
        spinnerLayer.strokeEnd = 0.8
        
        layer.addSublayer(spinnerLayer)
        
        // Add glow
        addCyberpunkGlow(color: CyberpunkTheme.primaryCyan, intensity: 1.0, radius: 15)
        
        // Animate
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1.0
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        spinnerLayer.add(rotation, forKey: "rotation")
    }
}