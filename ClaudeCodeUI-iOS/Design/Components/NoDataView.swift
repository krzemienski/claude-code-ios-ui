//
//  NoDataView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-17.
//  Enhanced empty state view with ASCII art and floating animations
//

import UIKit

// MARK: - Empty State Types

public enum EmptyStateType {
    case noSessions
    case noProjects
    case noMessages
    case noSearchResults
    case noFiles
    case offline
    case error(Error?)
    
    var icon: String {
        switch self {
        case .noSessions: return "bubble.left.and.bubble.right"
        case .noProjects: return "folder.badge.plus"
        case .noMessages: return "message"
        case .noSearchResults: return "magnifyingglass"
        case .noFiles: return "doc.text"
        case .offline: return "wifi.slash"
        case .error: return "exclamationmark.triangle"
        }
    }
    
    var title: String {
        switch self {
        case .noSessions: return "No Sessions Yet"
        case .noProjects: return "No Projects"
        case .noMessages: return "No Messages"
        case .noSearchResults: return "No Results Found"
        case .noFiles: return "No Files"
        case .offline: return "Offline Mode"
        case .error: return "Something Went Wrong"
        }
    }
    
    var message: String {
        switch self {
        case .noSessions: return "Start a new session to begin chatting with Claude"
        case .noProjects: return "Create your first project to get started"
        case .noMessages: return "Messages will appear here once you start chatting"
        case .noSearchResults: return "Try different keywords or check your spelling"
        case .noFiles: return "No files found in this directory"
        case .offline: return "Connect to the internet to access all features"
        case .error(let error): return error?.localizedDescription ?? "An unexpected error occurred"
        }
    }
    
    var asciiArt: String {
        switch self {
        case .noSessions:
            return """
                ╭─────────╮
                │  ◇ ◇ ◇  │
                │  ◆ ◆ ◆  │
                ╰─────────╯
                """
        case .noProjects:
            return """
                ╭───╮
                │╭─╮│
                ││ ││
                │╰─╯│
                ╰───╯
                """
        case .noMessages:
            return """
                ╭─────╮
                │ ╭─╮ │
                │ ╰─╯ │
                ╰─────╯
                """
        case .noSearchResults:
            return """
                ╭─────╮
                │ ╱ ╲ │
                │╱   ╲│
                ╰─────╯
                """
        case .noFiles:
            return """
                ╭───╮
                │   │
                │▤▤▤│
                ╰───╯
                """
        case .offline:
            return """
                ╭─╱─╲─╮
                │ ╱ ╲ │
                ╰─────╯
                """
        case .error:
            return """
                ╭─────╮
                │  ⚠  │
                │ ╱─╲ │
                ╰─────╯
                """
        }
    }
    
    var actionTitle: String? {
        switch self {
        case .noSessions: return "Start New Session"
        case .noProjects: return "Create Project"
        case .noMessages: return "Send Message"
        case .noSearchResults: return "Clear Search"
        case .noFiles: return "Refresh"
        case .offline: return "Retry Connection"
        case .error: return "Try Again"
        }
    }
    
    var color: UIColor {
        switch self {
        case .noSessions, .noMessages: return CyberpunkTheme.primaryCyan
        case .noProjects: return CyberpunkTheme.accentPink
        case .noSearchResults, .noFiles: return CyberpunkTheme.secondaryText
        case .offline: return CyberpunkTheme.warning
        case .error: return CyberpunkTheme.error
        }
    }
}

// MARK: - NoDataView Component

public class NoDataView: UIView {
    
    // MARK: - Properties
    
    private let type: EmptyStateType
    private var action: (() -> Void)?
    
    // UI Components
    private let containerStackView = UIStackView()
    private let asciiLabel = UILabel()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    
    // Animation properties
    private var floatingAnimationLayers: [CALayer] = []
    private var glowAnimationTimer: Timer?
    
    // MARK: - Initialization
    
    public init(type: EmptyStateType, action: (() -> Void)? = nil) {
        self.type = type
        self.action = action
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        self.type = .noMessages
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = .clear
        setupContainerStack()
        setupASCIIArt()
        setupIcon()
        setupLabels()
        setupActionButton()
        setupConstraints()
        setupFloatingElements()
        startAnimations()
    }
    
    private func setupContainerStack() {
        containerStackView.axis = .vertical
        containerStackView.alignment = .center
        containerStackView.spacing = 24
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
    }
    
    private func setupASCIIArt() {
        asciiLabel.text = type.asciiArt
        asciiLabel.font = .monospacedSystemFont(ofSize: 20, weight: .medium)
        asciiLabel.textColor = type.color.withAlphaComponent(0.6)
        asciiLabel.numberOfLines = 0
        asciiLabel.textAlignment = .center
        asciiLabel.layer.shadowColor = type.color.cgColor
        asciiLabel.layer.shadowRadius = 4
        asciiLabel.layer.shadowOpacity = 0.5
        asciiLabel.layer.shadowOffset = .zero
        
        // Add ASCII art to stack
        containerStackView.addArrangedSubview(asciiLabel)
    }
    
    private func setupIcon() {
        let config = UIImage.SymbolConfiguration(pointSize: 64, weight: .thin)
        iconImageView.image = UIImage(systemName: type.icon, withConfiguration: config)
        iconImageView.tintColor = type.color
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add glow effect to icon
        iconImageView.layer.shadowColor = type.color.cgColor
        iconImageView.layer.shadowRadius = 12
        iconImageView.layer.shadowOpacity = 0.6
        iconImageView.layer.shadowOffset = .zero
        
        containerStackView.addArrangedSubview(iconImageView)
    }
    
    private func setupLabels() {
        // Title label
        titleLabel.text = type.title
        titleLabel.font = CyberpunkTheme.headlineFont
        titleLabel.textColor = CyberpunkTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Message label
        messageLabel.text = type.message
        messageLabel.font = CyberpunkTheme.bodyFont
        messageLabel.textColor = CyberpunkTheme.secondaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        // Create text container
        let textContainer = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        textContainer.axis = .vertical
        textContainer.spacing = 12
        textContainer.alignment = .center
        
        containerStackView.addArrangedSubview(textContainer)
    }
    
    private func setupActionButton() {
        guard let actionTitle = type.actionTitle else { return }
        
        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        actionButton.setTitleColor(.black, for: .normal)
        actionButton.backgroundColor = type.color
        actionButton.layer.cornerRadius = 12
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add glow effect
        actionButton.layer.shadowColor = type.color.cgColor
        actionButton.layer.shadowRadius = 8
        actionButton.layer.shadowOpacity = 0.5
        actionButton.layer.shadowOffset = .zero
        
        // Add target
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        // Add button press animation
        actionButton.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        actionButton.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        containerStackView.addArrangedSubview(actionButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container stack
            containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            
            // Icon size
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Button size
            actionButton.heightAnchor.constraint(equalToConstant: 44),
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160)
        ])
    }
    
    // MARK: - Floating Elements Animation
    
    private func setupFloatingElements() {
        // Create floating particles
        for i in 0..<8 {
            let particle = createFloatingParticle(index: i)
            layer.addSublayer(particle)
            floatingAnimationLayers.append(particle)
        }
    }
    
    private func createFloatingParticle(index: Int) -> CAShapeLayer {
        let particle = CAShapeLayer()
        let size: CGFloat = CGFloat.random(in: 2...6)
        
        // Create different shapes
        let shapes = ["circle", "square", "triangle", "diamond"]
        let shapeType = shapes[index % shapes.count]
        
        switch shapeType {
        case "circle":
            particle.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).cgPath
        case "square":
            particle.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size, height: size)).cgPath
        case "triangle":
            let trianglePath = UIBezierPath()
            trianglePath.move(to: CGPoint(x: size/2, y: 0))
            trianglePath.addLine(to: CGPoint(x: 0, y: size))
            trianglePath.addLine(to: CGPoint(x: size, y: size))
            trianglePath.close()
            particle.path = trianglePath.cgPath
        case "diamond":
            let diamondPath = UIBezierPath()
            diamondPath.move(to: CGPoint(x: size/2, y: 0))
            diamondPath.addLine(to: CGPoint(x: size, y: size/2))
            diamondPath.addLine(to: CGPoint(x: size/2, y: size))
            diamondPath.addLine(to: CGPoint(x: 0, y: size/2))
            diamondPath.close()
            particle.path = diamondPath.cgPath
        default:
            break
        }
        
        particle.fillColor = type.color.withAlphaComponent(0.3).cgColor
        particle.strokeColor = type.color.withAlphaComponent(0.6).cgColor
        particle.lineWidth = 0.5
        
        // Add glow effect
        particle.shadowColor = type.color.cgColor
        particle.shadowOpacity = 0.8
        particle.shadowRadius = 2
        particle.shadowOffset = .zero
        
        return particle
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        startFloatingAnimation()
        startGlowAnimation()
        startIconBreathingAnimation()
        startASCIIGlitchAnimation()
    }
    
    private func startFloatingAnimation() {
        guard !floatingAnimationLayers.isEmpty else { return }
        
        for (index, particle) in floatingAnimationLayers.enumerated() {
            // Random starting position
            let startX = CGFloat.random(in: 0...bounds.width)
            let startY = CGFloat.random(in: 0...bounds.height)
            particle.position = CGPoint(x: startX, y: startY)
            
            // Create floating animation
            let floatAnimation = CAKeyframeAnimation(keyPath: "position")
            let duration = TimeInterval.random(in: 8...15)
            
            // Create random path
            let path = UIBezierPath()
            path.move(to: CGPoint(x: startX, y: startY))
            
            for _ in 0..<4 {
                let randomX = CGFloat.random(in: -20...bounds.width + 20)
                let randomY = CGFloat.random(in: -20...bounds.height + 20)
                path.addCurve(
                    to: CGPoint(x: randomX, y: randomY),
                    controlPoint1: CGPoint(
                        x: CGFloat.random(in: startX - 50...startX + 50),
                        y: CGFloat.random(in: startY - 50...startY + 50)
                    ),
                    controlPoint2: CGPoint(
                        x: CGFloat.random(in: randomX - 50...randomX + 50),
                        y: CGFloat.random(in: randomY - 50...randomY + 50)
                    )
                )
            }
            
            floatAnimation.path = path.cgPath
            floatAnimation.duration = duration
            floatAnimation.repeatCount = .infinity
            floatAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            floatAnimation.beginTime = CACurrentMediaTime() + Double(index) * 0.5
            
            particle.add(floatAnimation, forKey: "floating")
            
            // Add opacity animation
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = 0.2
            opacityAnimation.toValue = 0.8
            opacityAnimation.duration = TimeInterval.random(in: 2...4)
            opacityAnimation.autoreverses = true
            opacityAnimation.repeatCount = .infinity
            opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            particle.add(opacityAnimation, forKey: "opacity")
        }
    }
    
    private func startGlowAnimation() {
        let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        glowAnimation.fromValue = 0.3
        glowAnimation.toValue = 0.8
        glowAnimation.duration = 2.0
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = .infinity
        glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        iconImageView.layer.add(glowAnimation, forKey: "glow")
        asciiLabel.layer.add(glowAnimation, forKey: "asciiGlow")
    }
    
    private func startIconBreathingAnimation() {
        let breathingAnimation = CABasicAnimation(keyPath: "transform.scale")
        breathingAnimation.fromValue = 0.95
        breathingAnimation.toValue = 1.05
        breathingAnimation.duration = 3.0
        breathingAnimation.autoreverses = true
        breathingAnimation.repeatCount = .infinity
        breathingAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        iconImageView.layer.add(breathingAnimation, forKey: "breathing")
    }
    
    private func startASCIIGlitchAnimation() {
        // Subtle glitch effect for ASCII art
        let glitchTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Brief position glitch
            let originalTransform = self.asciiLabel.transform
            
            UIView.animate(withDuration: 0.1, animations: {
                self.asciiLabel.transform = CGAffineTransform(translationX: CGFloat.random(in: -2...2), y: 0)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    self.asciiLabel.transform = originalTransform
                }
            }
        }
        
        glowAnimationTimer = glitchTimer
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update particle positions for new bounds
        for particle in floatingAnimationLayers {
            particle.removeAnimation(forKey: "floating")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startFloatingAnimation()
        }
    }
    
    // MARK: - Actions
    
    @objc private func actionButtonTapped() {
        HapticFeedback.shared.buttonTap()
        action?()
    }
    
    @objc private func buttonPressed() {
        UIView.animate(withDuration: 0.1) {
            self.actionButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonReleased() {
        UIView.animate(withDuration: 0.1) {
            self.actionButton.transform = .identity
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        glowAnimationTimer?.invalidate()
        floatingAnimationLayers.forEach { $0.removeAllAnimations() }
    }
}

// MARK: - CyberpunkTheme Extension

extension CyberpunkTheme {
    static let headingFont = UIFont.systemFont(ofSize: 22, weight: .semibold)
}