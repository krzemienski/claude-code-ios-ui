//
//  CyberpunkLoadingIndicator.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-21.
//

import UIKit

/// A cyberpunk-themed loading indicator for UIKit
class CyberpunkLoadingIndicator: UIView {
    
    // MARK: - Properties
    
    private let containerView = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private var loadingBars: [UIView] = []
    
    private var message: String? {
        didSet {
            messageLabel.text = message
            messageLabel.isHidden = message?.isEmpty ?? true
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        // Container setup
        containerView.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.95)
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        
        // Add glow effect
        containerView.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        containerView.layer.shadowOffset = .zero
        containerView.layer.shadowRadius = 10
        containerView.layer.shadowOpacity = 0.5
        
        // Setup activity indicator with cyberpunk colors
        activityIndicator.color = CyberpunkTheme.primaryCyan
        activityIndicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
        // Setup message label
        messageLabel.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        messageLabel.textColor = CyberpunkTheme.primaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.isHidden = true
        
        // Add custom loading bars
        setupLoadingBars()
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(activityIndicator)
        containerView.addSubview(messageLabel)
        
        // Setup constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            
            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupLoadingBars() {
        let barCount = 5
        let barWidth: CGFloat = 3
        let barHeight: CGFloat = 20
        let spacing: CGFloat = 8
        
        for i in 0..<barCount {
            let bar = UIView()
            bar.backgroundColor = CyberpunkTheme.primaryCyan
            bar.layer.cornerRadius = barWidth / 2
            bar.alpha = 0.3
            
            // Add glow
            bar.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
            bar.layer.shadowRadius = 4
            bar.layer.shadowOpacity = 0.8
            bar.layer.shadowOffset = .zero
            
            containerView.addSubview(bar)
            bar.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                bar.widthAnchor.constraint(equalToConstant: barWidth),
                bar.heightAnchor.constraint(equalToConstant: barHeight),
                bar.centerYAnchor.constraint(equalTo: activityIndicator.centerYAnchor),
                bar.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, 
                                            constant: CGFloat(i - 2) * (barWidth + spacing))
            ])
            
            loadingBars.append(bar)
        }
    }
    
    // MARK: - Public Methods
    
    func show(in view: UIView, message: String? = nil) {
        self.message = message
        
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Start animations
        activityIndicator.startAnimating()
        startBarAnimation()
        
        // Fade in
        alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.activityIndicator.stopAnimating()
            self.stopBarAnimation()
            self.removeFromSuperview()
        }
    }
    
    func updateMessage(_ message: String?) {
        UIView.animate(withDuration: 0.2) {
            self.message = message
        }
    }
    
    // MARK: - Animations
    
    private func startBarAnimation() {
        for (index, bar) in loadingBars.enumerated() {
            UIView.animate(withDuration: 0.6,
                          delay: Double(index) * 0.1,
                          options: [.repeat, .autoreverse, .curveEaseInOut],
                          animations: {
                bar.alpha = 1.0
                bar.transform = CGAffineTransform(scaleX: 1.0, y: 1.5)
            })
        }
    }
    
    private func stopBarAnimation() {
        loadingBars.forEach { bar in
            bar.layer.removeAllAnimations()
            bar.alpha = 0.3
            bar.transform = .identity
        }
    }
}

// MARK: - UIViewController Extension

extension UIViewController {
    private struct AssociatedKeys {
        static var loadingIndicator = "loadingIndicator"
    }
    
    private var loadingIndicator: CyberpunkLoadingIndicator? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.loadingIndicator) as? CyberpunkLoadingIndicator
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.loadingIndicator, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Shows cyberpunk-themed loading indicator
    func showCyberpunkLoading(message: String? = nil) {
        DispatchQueue.main.async {
            if self.loadingIndicator == nil {
                self.loadingIndicator = CyberpunkLoadingIndicator()
            }
            self.loadingIndicator?.show(in: self.view, message: message)
        }
    }
    
    /// Hides the loading indicator
    func hideCyberpunkLoading() {
        DispatchQueue.main.async {
            self.loadingIndicator?.hide()
            self.loadingIndicator = nil
        }
    }
    
    /// Updates the loading message
    func updateCyberpunkLoadingMessage(_ message: String?) {
        DispatchQueue.main.async {
            self.loadingIndicator?.updateMessage(message)
        }
    }
}