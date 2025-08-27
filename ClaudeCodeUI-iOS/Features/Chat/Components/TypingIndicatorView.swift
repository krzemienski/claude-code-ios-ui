//
//  TypingIndicatorView.swift
//  ClaudeCodeUI
//
//  Created by Context Manager on 2025-01-21.
//  Implements CM-Chat-02: Typing indicator animation
//

import UIKit

/// Animated typing indicator showing "Claude is typing..." with dots animation
class UIKitTypingIndicatorView: UIView {
    
    // MARK: - Properties
    
    private let containerView = UIView()
    private let textLabel = UILabel()
    private let dotsContainer = UIView()
    private var dotViews: [UIView] = []
    private var animationTimer: Timer?
    private var currentDot = 0
    
    // Animation settings
    private let dotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 6
    private let animationDuration: TimeInterval = 0.4
    private let numberOfDots = 3
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Container with cyberpunk styling
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = CyberpunkTheme.surfacePrimary
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        
        // Add glow effect
        containerView.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = .zero
        
        addSubview(containerView)
        
        // Text label
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = "Claude is typing"
        textLabel.font = .systemFont(ofSize: 14, weight: .medium)
        textLabel.textColor = CyberpunkTheme.textSecondary
        containerView.addSubview(textLabel)
        
        // Dots container
        dotsContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dotsContainer)
        
        // Create dots
        for i in 0..<numberOfDots {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = CyberpunkTheme.primaryCyan
            dot.layer.cornerRadius = dotSize / 2
            dot.alpha = 0.3
            
            // Add glow to dots
            dot.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
            dot.layer.shadowRadius = 3
            dot.layer.shadowOpacity = 0.5
            dot.layer.shadowOffset = .zero
            
            dotsContainer.addSubview(dot)
            dotViews.append(dot)
            
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: dotSize),
                dot.heightAnchor.constraint(equalToConstant: dotSize),
                dot.centerYAnchor.constraint(equalTo: dotsContainer.centerYAnchor),
                dot.leadingAnchor.constraint(equalTo: i == 0 ? dotsContainer.leadingAnchor : dotViews[i-1].trailingAnchor, 
                                            constant: i == 0 ? 0 : dotSpacing)
            ])
        }
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Container
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Text label
            textLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // Dots container
            dotsContainer.leadingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 8),
            dotsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            dotsContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            dotsContainer.heightAnchor.constraint(equalToConstant: dotSize),
            
            // Container height
            containerView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Animation Control
    
    /// Start the typing animation
    func startAnimating() {
        stopAnimating()
        animateNextDot()
        
        // Add entrance animation
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: 0, y: 10)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    /// Stop the typing animation
    func stopAnimating() {
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Reset all dots
        dotViews.forEach { $0.alpha = 0.3 }
        currentDot = 0
        
        // Add exit animation
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: 0, y: -10)
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    private func animateNextDot() {
        // Reset previous dot
        if currentDot > 0 {
            UIView.animate(withDuration: animationDuration / 2) {
                self.dotViews[self.currentDot - 1].alpha = 0.3
                self.dotViews[self.currentDot - 1].transform = .identity
            }
        } else if currentDot == 0 && dotViews.count > 0 {
            // Reset last dot when starting new cycle
            UIView.animate(withDuration: animationDuration / 2) {
                self.dotViews[self.numberOfDots - 1].alpha = 0.3
                self.dotViews[self.numberOfDots - 1].transform = .identity
            }
        }
        
        // Animate current dot
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, animations: {
            self.dotViews[self.currentDot].alpha = 1.0
            self.dotViews[self.currentDot].transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            // Move to next dot
            self.currentDot = (self.currentDot + 1) % self.numberOfDots
            
            // Schedule next animation
            self.animationTimer = Timer.scheduledTimer(withTimeInterval: self.animationDuration / 2, repeats: false) { _ in
                self.animateNextDot()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Update the typing text
    func updateText(_ text: String) {
        textLabel.text = text
    }
    
    /// Check if currently animating
    var isAnimating: Bool {
        return animationTimer != nil
    }
}