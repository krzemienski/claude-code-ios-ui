//
//  NeonButton.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

class NeonButton: UIButton {
    
    private var glowLayer: CALayer?
    private let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        // Configure button appearance
        backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.3)
        layer.cornerRadius = CyberpunkTheme.borderRadius
        layer.borderWidth = 2
        layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
        
        // Configure title
        setTitleColor(CyberpunkTheme.primaryCyan, for: .normal)
        setTitleColor(CyberpunkTheme.primaryCyan.withAlphaComponent(0.7), for: .highlighted)
        titleLabel?.font = Typography.medium
        
        // Add glow effect
        layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.5
        layer.shadowOffset = .zero
        
        // Add touch handlers
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func touchDown() {
        // Animate button press
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.layer.shadowOpacity = 0.8
        }
    }
    
    @objc private func touchUp() {
        // Animate button release
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.layer.shadowOpacity = 0.5
        }
    }
    
    func startGlowing() {
        glowAnimation.fromValue = 0.5
        glowAnimation.toValue = 0.8
        glowAnimation.duration = 0.8
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = .infinity
        
        layer.add(glowAnimation, forKey: "glow")
    }
    
    func stopGlowing() {
        layer.removeAnimation(forKey: "glow")
    }
}

// MARK: - Face ID Sign In Button
class FaceIDSignInButton: NeonButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureFaceIDButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureFaceIDButton()
    }
    
    private func configureFaceIDButton() {
        // Create container stack view
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Face ID icon
        let faceIDImage = IconSystem.icon(.faceId, size: 40)
        let imageView = UIImageView(image: faceIDImage)
        imageView.tintColor = CyberpunkTheme.primaryCyan
        imageView.contentMode = .scaleAspectFit
        
        // Sign In label
        let label = UILabel()
        label.text = "Sign In"
        label.font = Typography.medium
        label.textColor = CyberpunkTheme.primaryCyan
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Button size
            widthAnchor.constraint(equalToConstant: 200),
            heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Start glowing by default
        startGlowing()
    }
}