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
    private var typingIndicatorView: UIKitTypingIndicatorView?
    
    // MARK: - Initialization
    
    public init(tableView: UITableView, inputView: UIView) {
        self.tableView = tableView
        self.inputView = inputView
        setupTypingIndicator()
    }
    
    // MARK: - Typing Indicator
    
    private func setupTypingIndicator() {
        guard let tableView = tableView else { return }
        
        typingIndicatorView = UIKitTypingIndicatorView()
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

