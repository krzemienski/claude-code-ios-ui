//
//  ChatAnimationManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-20.
//

import UIKit

/// Manages animations for chat interface including message send, typing indicators, and scroll effects
public class ChatAnimationManager {
    
    // MARK: - Properties
    
    private weak var tableView: UITableView?
    private weak var inputView: UIView?
    private var typingIndicatorView: TypingIndicatorView?
    
    // MARK: - Initialization
    
    public init(tableView: UITableView, inputView: UIView) {
        self.tableView = tableView
        self.inputView = inputView
        setupTypingIndicator()
    }
    
    // MARK: - Typing Indicator
    
    private func setupTypingIndicator() {
        guard let tableView = tableView else { return }
        
        typingIndicatorView = TypingIndicatorView()
        typingIndicatorView?.translatesAutoresizingMaskIntoConstraints = false
        typingIndicatorView?.isHidden = true
        
        if let typingView = typingIndicatorView {
            tableView.addSubview(typingView)
            NSLayoutConstraint.activate([
                typingView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 16),
                typingView.trailingAnchor.constraint(lessThanOrEqualTo: tableView.centerXAnchor),
                typingView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor, constant: -20),
                typingView.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
    }
    
    public func showTypingIndicator() {
        guard let typingView = typingIndicatorView else { return }
        
        typingView.alpha = 0
        typingView.isHidden = false
        typingView.transform = CGAffineTransform(translationX: -50, y: 0)
        
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                typingView.alpha = 1
                typingView.transform = .identity
            }
        )
        
        typingView.startAnimating()
    }
    
    public func hideTypingIndicator() {
        guard let typingView = typingIndicatorView else { return }
        
        typingView.stopAnimating()
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                typingView.alpha = 0
                typingView.transform = CGAffineTransform(translationX: -30, y: 0)
            }
        ) { _ in
            typingView.isHidden = true
        }
    }
    
    // MARK: - Message Send Animation
    
    public func animateMessageSend(from inputView: UIView, completion: @escaping () -> Void) {
        // Create a temporary view for the send animation
        let tempMessageView = createTempMessageView(from: inputView)
        
        guard let tableView = tableView,
              let parentView = tableView.superview else {
            completion()
            return
        }
        
        parentView.addSubview(tempMessageView)
        
        // Set initial position at input view
        tempMessageView.frame = CGRect(
            x: inputView.frame.origin.x + 16,
            y: inputView.frame.origin.y - 50,
            width: inputView.frame.width - 32,
            height: 44
        )
        
        // Animate to chat area
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.8,
            options: .curveEaseOut,
            animations: {
                tempMessageView.transform = CGAffineTransform(translationX: 0, y: -100)
                tempMessageView.alpha = 0
            }
        ) { _ in
            tempMessageView.removeFromSuperview()
            completion()
        }
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func createTempMessageView(from inputView: UIView) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.8)
        containerView.layer.cornerRadius = 22
        containerView.layer.masksToBounds = true
        
        // Add glow effect
        containerView.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.6
        containerView.layer.shadowOffset = .zero
        containerView.layer.masksToBounds = false
        
        let label = UILabel()
        label.text = "Sending..."
        label.font = CyberpunkTheme.bodyFont
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        return containerView
    }
    
    // MARK: - Message Receive Animation
    
    public func animateMessageReceive(at indexPath: IndexPath) {
        guard let tableView = tableView,
              let cell = tableView.cellForRow(at: indexPath) else { return }
        
        // Initial state
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: -50, y: 20)
        
        // Animate in
        UIView.animate(
            withDuration: 0.5,
            delay: 0.1,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                cell.alpha = 1
                cell.transform = .identity
            }
        )
    }
    
    // MARK: - Scroll Animations
    
    public func smoothScrollToBottom(animated: Bool = true) {
        guard let tableView = tableView,
              tableView.numberOfSections > 0 else { return }
        
        let lastSection = tableView.numberOfSections - 1
        let lastRow = tableView.numberOfRows(inSection: lastSection) - 1
        
        guard lastRow >= 0 else { return }
        
        let indexPath = IndexPath(row: lastRow, section: lastSection)
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            })
        } else {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    public func animateContentSizeChange() {
        guard let tableView = tableView else { return }
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            tableView.layoutIfNeeded()
        })
    }
    
    // MARK: - Parallax Scroll Effect
    
    public func updateParallaxEffect(scrollView: UIScrollView) {
        let cells = tableView?.visibleCells ?? []
        
        for cell in cells {
            guard let indexPath = tableView?.indexPath(for: cell) else { continue }
            
            let cellFrame = cell.frame
            let scrollOffset = scrollView.contentOffset.y
            let cellCenter = cellFrame.midY
            let viewCenter = scrollView.bounds.midY + scrollOffset
            
            let distance = abs(cellCenter - viewCenter)
            let maxDistance = scrollView.bounds.height / 2
            
            let parallaxOffset = (distance / maxDistance) * 10
            let scale = 1.0 - (distance / maxDistance) * 0.02
            
            // Apply subtle parallax and scale effects
            cell.transform = CGAffineTransform(translationX: 0, y: parallaxOffset).scaledBy(x: scale, y: scale)
            cell.alpha = 1.0 - (distance / maxDistance) * 0.1
        }
    }
}

// MARK: - Typing Indicator View

public class TypingIndicatorView: UIView {
    
    private let containerView = UIView()
    private let dotViews: [UIView] = (0..<3).map { _ in UIView() }
    private var animationTimer: Timer?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = CyberpunkTheme.surface
        layer.cornerRadius = 22
        layer.masksToBounds = true
        
        // Add subtle border and glow
        layer.borderWidth = 1
        layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.3
        layer.shadowOffset = .zero
        layer.masksToBounds = false
        
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup dots
        for (index, dot) in dotViews.enumerated() {
            dot.backgroundColor = CyberpunkTheme.primaryCyan
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(dot)
            
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 8),
                dot.heightAnchor.constraint(equalToConstant: 8),
                dot.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])
            
            if index == 0 {
                dot.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
            } else {
                dot.leadingAnchor.constraint(equalTo: dotViews[index - 1].trailingAnchor, constant: 8).isActive = true
            }
            
            if index == dotViews.count - 1 {
                dot.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
            }
        }
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    public func startAnimating() {
        stopAnimating()
        
        for (index, dot) in dotViews.enumerated() {
            let animation = CABasicAnimation(keyPath: "transform.scale")
            animation.duration = 0.8
            animation.fromValue = 1.0
            animation.toValue = 1.5
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.timeOffset = Double(index) * 0.2
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            dot.layer.add(animation, forKey: "pulsing")
            
            // Add opacity animation
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.duration = 0.8
            opacityAnimation.fromValue = 0.5
            opacityAnimation.toValue = 1.0
            opacityAnimation.autoreverses = true
            opacityAnimation.repeatCount = .infinity
            opacityAnimation.timeOffset = Double(index) * 0.2
            
            dot.layer.add(opacityAnimation, forKey: "opacity")
        }
    }
    
    public func stopAnimating() {
        dotViews.forEach { dot in
            dot.layer.removeAllAnimations()
        }
    }
}