//
//  LoadingStateManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-20.
//

import UIKit

/// Centralized manager for all loading states and animations
public class LoadingStateManager {
    
    // MARK: - Loading State Types
    
    public enum LoadingState {
        case loading(message: String?)
        case empty(type: EmptyStateType)
        case error(message: String, retryAction: (() -> Void)?)
        case success
        case skeleton(count: Int)
    }
    
    // MARK: - Properties
    
    private weak var parentView: UIView?
    private var currentLoadingView: UIView?
    private var currentSkeletonView: UIView?
    private var currentEmptyStateView: NoDataView?
    
    // MARK: - Initialization
    
    public init(parentView: UIView) {
        self.parentView = parentView
    }
    
    // MARK: - State Management
    
    public func setState(_ state: LoadingState, animated: Bool = true) {
        // Clear existing states
        clearCurrentState(animated: animated)
        
        switch state {
        case .loading(let message):
            showLoadingState(message: message, animated: animated)
            
        case .empty(let type):
            showEmptyState(type: type, animated: animated)
            
        case .error(let message, let retryAction):
            showErrorState(message: message, retryAction: retryAction, animated: animated)
            
        case .skeleton(let count):
            showSkeletonState(count: count, animated: animated)
            
        case .success:
            // Clear all states - success means showing actual content
            break
        }
    }
    
    private func clearCurrentState(animated: Bool) {
        let views = [currentLoadingView, currentSkeletonView, currentEmptyStateView].compactMap { $0 }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                views.forEach { $0.alpha = 0 }
            }) { _ in
                views.forEach { $0.removeFromSuperview() }
                self.resetViews()
            }
        } else {
            views.forEach { $0.removeFromSuperview() }
            resetViews()
        }
    }
    
    private func resetViews() {
        currentLoadingView = nil
        currentSkeletonView = nil
        currentEmptyStateView = nil
    }
    
    // MARK: - Loading State
    
    private func showLoadingState(message: String?, animated: Bool) {
        guard let parentView = parentView else { return }
        
        let loadingView = createCyberpunkLoadingView(message: message)
        currentLoadingView = loadingView
        
        parentView.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            loadingView.leadingAnchor.constraint(greaterThanOrEqualTo: parentView.leadingAnchor, constant: 40),
            loadingView.trailingAnchor.constraint(lessThanOrEqualTo: parentView.trailingAnchor, constant: -40)
        ])
        
        if animated {
            loadingView.alpha = 0
            loadingView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: .curveEaseOut,
                animations: {
                    loadingView.alpha = 1
                    loadingView.transform = .identity
                }
            )
        }
    }
    
    private func createCyberpunkLoadingView(message: String?) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.95)
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.5).cgColor
        
        // Add glow effect
        containerView.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = .zero
        
        // Create animated rings
        let ringsContainer = UIView()
        ringsContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(ringsContainer)
        
        for i in 0..<3 {
            let ring = createAnimatedRing(index: i)
            ringsContainer.addSubview(ring)
        }
        
        // Loading text
        let messageLabel = UILabel()
        messageLabel.text = message ?? "Loading..."
        messageLabel.font = CyberpunkTheme.bodyFont
        messageLabel.textColor = CyberpunkTheme.primaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            // Rings container
            ringsContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            ringsContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            ringsContainer.widthAnchor.constraint(equalToConstant: 80),
            ringsContainer.heightAnchor.constraint(equalToConstant: 80),
            
            // Message label
            messageLabel.topAnchor.constraint(equalTo: ringsContainer.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30)
        ])
        
        return containerView
    }
    
    private func createAnimatedRing(index: Int) -> UIView {
        let ringView = UIView()
        let size: CGFloat = 60 - CGFloat(index * 15)
        
        ringView.frame = CGRect(x: (80 - size) / 2, y: (80 - size) / 2, width: size, height: size)
        ringView.layer.borderWidth = 2
        ringView.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.8 - CGFloat(index) * 0.2).cgColor
        ringView.layer.cornerRadius = size / 2
        ringView.backgroundColor = .clear
        
        // Rotation animation
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.duration = 1.5 + Double(index) * 0.5
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = 2 * Double.pi
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        // Scale animation
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = 2.0
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.1
        scaleAnimation.autoreverses = true
        scaleAnimation.repeatCount = .infinity
        scaleAnimation.timeOffset = Double(index) * 0.3
        
        ringView.layer.add(rotationAnimation, forKey: "rotation")
        ringView.layer.add(scaleAnimation, forKey: "scale")
        
        return ringView
    }
    
    // MARK: - Empty State
    
    private func showEmptyState(type: EmptyStateType, animated: Bool) {
        guard let parentView = parentView else { return }
        
        let emptyStateView = NoDataView(type: type)
        currentEmptyStateView = emptyStateView
        
        parentView.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: parentView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
        
        if animated {
            emptyStateView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                emptyStateView.alpha = 1
            }
        }
    }
    
    // MARK: - Error State
    
    private func showErrorState(message: String, retryAction: (() -> Void)?, animated: Bool) {
        guard let parentView = parentView else { return }
        
        let errorView = NoDataView(type: .error(nil), action: retryAction)
        currentEmptyStateView = errorView
        
        parentView.addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: parentView.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
        
        if animated {
            errorView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                errorView.alpha = 1
            }
        }
    }
    
    // MARK: - Skeleton State
    
    private func showSkeletonState(count: Int, animated: Bool) {
        guard let parentView = parentView else { return }
        
        // Create a container view for the skeleton items
        let containerView = UIView()
        containerView.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.95)
        currentSkeletonView = containerView
        
        // Create multiple skeleton items
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        for _ in 0..<count {
            // Create a skeleton row using SkeletonView factory methods
            let rowContainer = UIView()
            rowContainer.translatesAutoresizingMaskIntoConstraints = false
            
            // Create avatar skeleton
            let avatar = SkeletonView.createCircle(diameter: 44)
            avatar.shimmerColor = CyberpunkTheme.primaryCyan
            rowContainer.addSubview(avatar)
            
            // Create title skeleton
            let title = SkeletonView.createLine(width: 200, height: 18)
            title.shimmerColor = CyberpunkTheme.primaryCyan
            rowContainer.addSubview(title)
            
            // Create subtitle skeleton
            let subtitle = SkeletonView.createLine(width: 150, height: 14)
            subtitle.shimmerColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.6)
            rowContainer.addSubview(subtitle)
            
            // Layout constraints for skeleton row
            NSLayoutConstraint.activate([
                avatar.leadingAnchor.constraint(equalTo: rowContainer.leadingAnchor),
                avatar.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor),
                
                title.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
                title.topAnchor.constraint(equalTo: rowContainer.topAnchor, constant: 10),
                
                subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
                subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
                
                rowContainer.heightAnchor.constraint(equalToConstant: 80)
            ])
            
            // Start shimmer animation
            avatar.startShimmering()
            title.startShimmering()
            subtitle.startShimmering()
            
            stackView.addArrangedSubview(rowContainer)
        }
        
        containerView.addSubview(stackView)
        parentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: parentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        if animated {
            containerView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                containerView.alpha = 1
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    public func showLoading(message: String? = nil) {
        setState(.loading(message: message))
    }
    
    public func showSkeleton(count: Int = 5) {
        setState(.skeleton(count: count))
    }
    
    public func showEmpty(type: EmptyStateType) {
        setState(.empty(type: type))
    }
    
    public func showError(_ message: String, retryAction: (() -> Void)? = nil) {
        setState(.error(message: message, retryAction: retryAction))
    }
    
    public func showSuccess() {
        setState(.success)
    }
    
    public func hide() {
        clearCurrentState(animated: true)
    }
}

// MARK: - UIView Extension

extension UIView {
    private static var loadingStateManagerKey: UInt8 = 0
    
    public var loadingStateManager: LoadingStateManager {
        if let manager = objc_getAssociatedObject(self, &UIView.loadingStateManagerKey) as? LoadingStateManager {
            return manager
        }
        
        let manager = LoadingStateManager(parentView: self)
        objc_setAssociatedObject(self, &UIView.loadingStateManagerKey, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return manager
    }
}