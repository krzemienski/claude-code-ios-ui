//
//  TypingIndicatorView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-16.
//

import UIKit

/// A typing indicator view with animated pulsing dots
public class TypingIndicatorView: UIView {
    
    // MARK: - Properties
    
    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()
    private let containerView = UIView()
    private let label = UILabel()
    
    private var dots: [UIView] = []
    private var isAnimating = false
    private var hideTimer: Timer?
    
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
        backgroundColor = .clear
        
        // Container setup
        containerView.backgroundColor = CyberpunkTheme.surface
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Add glow effect
        containerView.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = .zero
        
        // Label setup
        label.text = "Claude is thinking"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = CyberpunkTheme.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        
        // Setup dots
        dots = [dot1, dot2, dot3]
        let dotSize: CGFloat = 8
        
        for (index, dot) in dots.enumerated() {
            dot.backgroundColor = CyberpunkTheme.primaryCyan
            dot.layer.cornerRadius = dotSize / 2
            dot.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(dot)
            
            // Add glow to dots
            dot.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
            dot.layer.shadowRadius = 4
            dot.layer.shadowOpacity = 0.8
            dot.layer.shadowOffset = .zero
            
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: dotSize),
                dot.heightAnchor.constraint(equalToConstant: dotSize),
                dot.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 8),
                dot.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: CGFloat(16 + index * 14))
            ])
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 120),
            containerView.heightAnchor.constraint(equalToConstant: 50),
            
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8)
        ])
    }
    
    // MARK: - Animation
    
    /// Starts the typing animation
    public func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        
        for (index, dot) in dots.enumerated() {
            // Reset dot state
            dot.transform = .identity
            dot.alpha = 0.3
            
            // Create bounce animation with delay
            let delay = Double(index) * 0.15
            
            UIView.animateKeyframes(
                withDuration: 1.4,
                delay: delay,
                options: [.repeat, .calculationModeCubic],
                animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) {
                        dot.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                        dot.alpha = 1.0
                    }
                    UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) {
                        dot.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                        dot.alpha = 0.6
                    }
                    UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.25) {
                        dot.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                        dot.alpha = 0.9
                    }
                    UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                        dot.transform = .identity
                        dot.alpha = 0.3
                    }
                }
            )
        }
        
        // Pulse the container glow
        let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        glowAnimation.duration = 1.5
        glowAnimation.fromValue = 0.3
        glowAnimation.toValue = 0.6
        glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = .infinity
        containerView.layer.add(glowAnimation, forKey: "glow")
    }
    
    /// Stops the typing animation
    public func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        
        // Remove all animations
        dots.forEach { dot in
            dot.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.2) {
                dot.transform = .identity
                dot.alpha = 0.3
            }
        }
        
        containerView.layer.removeAllAnimations()
    }
    
    /// Shows the typing indicator with animation and optional timeout
    public func show(timeout: TimeInterval = 30) {
        // Cancel any existing timer
        hideTimer?.invalidate()
        
        isHidden = false
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: -20, y: 0)
        
        startAnimating()
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                self.alpha = 1
                self.transform = .identity
            }
        )
        
        // Set timeout to automatically hide indicator
        hideTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }
    
    /// Hides the typing indicator with animation
    public func hide(completion: (() -> Void)? = nil) {
        // Cancel any existing timer
        hideTimer?.invalidate()
        hideTimer = nil
        
        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: -20, y: 0)
            }
        ) { _ in
            self.stopAnimating()
            self.isHidden = true
            self.transform = .identity
            completion?()
        }
    }
}

// MARK: - Message Animation Helper

public class MessageAnimator {
    
    /// Animates a message being sent
    public static func animateSend(view: UIView, completion: (() -> Void)? = nil) {
        // Initial state
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: 50, y: 0)
        
        // Animate to final state
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                view.alpha = 1
                view.transform = .identity
            },
            completion: { _ in
                // Add subtle bounce
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0,
                    usingSpringWithDamping: 0.5,
                    initialSpringVelocity: 0.5,
                    options: .curveEaseOut,
                    animations: {
                        view.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
                    }
                ) { _ in
                    UIView.animate(withDuration: 0.1) {
                        view.transform = .identity
                    }
                    completion?()
                }
            }
        )
    }
    
    /// Animates a message being received
    public static func animateReceive(view: UIView, completion: (() -> Void)? = nil) {
        // Initial state
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: -50, y: 0)
        
        // Animate to final state
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                view.alpha = 1
                view.transform = .identity
            },
            completion: { _ in
                completion?()
            }
        )
    }
    
    /// Adds a glow effect to a message
    public static func addGlowEffect(to view: UIView, color: UIColor = CyberpunkTheme.primaryCyan) {
        view.layer.shadowColor = color.cgColor
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0
        view.layer.shadowOffset = .zero
        
        // Animate glow
        let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        glowAnimation.duration = 0.5
        glowAnimation.fromValue = 0
        glowAnimation.toValue = 0.5
        glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = 2
        view.layer.add(glowAnimation, forKey: "glow")
    }
    
    /// Animates scroll to bottom with momentum
    public static func scrollToBottom(tableView: UITableView, animated: Bool = true) {
        guard tableView.numberOfSections > 0 else { return }
        
        let lastSection = tableView.numberOfSections - 1
        let lastRow = tableView.numberOfRows(inSection: lastSection) - 1
        
        guard lastRow >= 0 else { return }
        
        let indexPath = IndexPath(row: lastRow, section: lastSection)
        
        if animated {
            // Add momentum scrolling effect
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                options: [.curveEaseInOut],
                animations: {
                    tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                }
            )
        } else {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
}