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
    
    public enum EmptyStateType {
        case noProjects
        case noSessions
        case noMessages
        case noFiles
        case noSearchResults
        case noConnection
        case generic(title: String, message: String)
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
        ])\n        \n        if animated {\n            loadingView.alpha = 0\n            loadingView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)\n            \n            UIView.animate(\n                withDuration: 0.4,\n                delay: 0,\n                usingSpringWithDamping: 0.8,\n                initialSpringVelocity: 0.5,\n                options: .curveEaseOut,\n                animations: {\n                    loadingView.alpha = 1\n                    loadingView.transform = .identity\n                }\n            )\n        }\n    }\n    \n    private func createCyberpunkLoadingView(message: String?) -> UIView {\n        let containerView = UIView()\n        containerView.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.95)\n        containerView.layer.cornerRadius = 20\n        containerView.layer.borderWidth = 1\n        containerView.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.5).cgColor\n        \n        // Add glow effect\n        containerView.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor\n        containerView.layer.shadowRadius = 12\n        containerView.layer.shadowOpacity = 0.3\n        containerView.layer.shadowOffset = .zero\n        \n        // Create animated rings\n        let ringsContainer = UIView()\n        ringsContainer.translatesAutoresizingMaskIntoConstraints = false\n        containerView.addSubview(ringsContainer)\n        \n        for i in 0..<3 {\n            let ring = createAnimatedRing(index: i)\n            ringsContainer.addSubview(ring)\n        }\n        \n        // Loading text\n        let messageLabel = UILabel()\n        messageLabel.text = message ?? \"Loading...\"\n        messageLabel.font = CyberpunkTheme.bodyFont\n        messageLabel.textColor = CyberpunkTheme.primaryText\n        messageLabel.textAlignment = .center\n        messageLabel.numberOfLines = 0\n        messageLabel.translatesAutoresizingMaskIntoConstraints = false\n        containerView.addSubview(messageLabel)\n        \n        NSLayoutConstraint.activate([\n            // Rings container\n            ringsContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),\n            ringsContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),\n            ringsContainer.widthAnchor.constraint(equalToConstant: 80),\n            ringsContainer.heightAnchor.constraint(equalToConstant: 80),\n            \n            // Message label\n            messageLabel.topAnchor.constraint(equalTo: ringsContainer.bottomAnchor, constant: 20),\n            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),\n            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),\n            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30)\n        ])\n        \n        return containerView\n    }\n    \n    private func createAnimatedRing(index: Int) -> UIView {\n        let ringView = UIView()\n        let size: CGFloat = 60 - CGFloat(index * 15)\n        \n        ringView.frame = CGRect(x: (80 - size) / 2, y: (80 - size) / 2, width: size, height: size)\n        ringView.layer.borderWidth = 2\n        ringView.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.8 - CGFloat(index) * 0.2).cgColor\n        ringView.layer.cornerRadius = size / 2\n        ringView.backgroundColor = .clear\n        \n        // Rotation animation\n        let rotationAnimation = CABasicAnimation(keyPath: \"transform.rotation\")\n        rotationAnimation.duration = 1.5 + Double(index) * 0.5\n        rotationAnimation.fromValue = 0\n        rotationAnimation.toValue = 2 * Double.pi\n        rotationAnimation.repeatCount = .infinity\n        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)\n        \n        // Scale animation\n        let scaleAnimation = CABasicAnimation(keyPath: \"transform.scale\")\n        scaleAnimation.duration = 2.0\n        scaleAnimation.fromValue = 1.0\n        scaleAnimation.toValue = 1.1\n        scaleAnimation.autoreverses = true\n        scaleAnimation.repeatCount = .infinity\n        scaleAnimation.timeOffset = Double(index) * 0.3\n        \n        ringView.layer.add(rotationAnimation, forKey: \"rotation\")\n        ringView.layer.add(scaleAnimation, forKey: \"scale\")\n        \n        return ringView\n    }\n    \n    // MARK: - Empty State\n    \n    private func showEmptyState(type: EmptyStateType, animated: Bool) {\n        guard let parentView = parentView else { return }\n        \n        let emptyStateView = NoDataView()\n        currentEmptyStateView = emptyStateView\n        \n        let (artStyle, title, message, buttonTitle, buttonAction) = getEmptyStateConfig(for: type)\n        \n        emptyStateView.configure(\n            artStyle: artStyle,\n            title: title,\n            message: message,\n            buttonTitle: buttonTitle,\n            buttonAction: buttonAction\n        )\n        \n        parentView.addSubview(emptyStateView)\n        emptyStateView.translatesAutoresizingMaskIntoConstraints = false\n        \n        NSLayoutConstraint.activate([\n            emptyStateView.topAnchor.constraint(equalTo: parentView.topAnchor),\n            emptyStateView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),\n            emptyStateView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),\n            emptyStateView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)\n        ])\n        \n        emptyStateView.show(animated: animated)\n    }\n    \n    private func getEmptyStateConfig(for type: EmptyStateType) -> (NoDataView.ArtStyle, String, String, String?, (() -> Void)?) {\n        switch type {\n        case .noProjects:\n            return (.noProjects, \"No Projects Yet\", \"Create your first project to get started with Claude Code\", \"Create Project\", nil)\n            \n        case .noSessions:\n            return (.noSessions, \"No Sessions\", \"Start a new session to begin chatting with Claude\", \"New Session\", nil)\n            \n        case .noMessages:\n            return (.noMessages, \"No Messages\", \"Send a message to start the conversation\", nil, nil)\n            \n        case .noFiles:\n            return (.noFiles, \"No Files\", \"This directory is empty\", \"Browse Files\", nil)\n            \n        case .noSearchResults:\n            return (.noResults, \"No Results Found\", \"Try adjusting your search terms or filters\", \"Clear Search\", nil)\n            \n        case .noConnection:\n            return (.noConnection, \"No Connection\", \"Check your internet connection and try again\", \"Retry\", nil)\n            \n        case .generic(let title, let message):\n            return (.noData, title, message, nil, nil)\n        }\n    }\n    \n    // MARK: - Error State\n    \n    private func showErrorState(message: String, retryAction: (() -> Void)?, animated: Bool) {\n        guard let parentView = parentView else { return }\n        \n        let errorView = NoDataView()\n        currentEmptyStateView = errorView\n        \n        errorView.configure(\n            artStyle: .error,\n            title: \"Something Went Wrong\",\n            message: message,\n            buttonTitle: retryAction != nil ? \"Try Again\" : nil,\n            buttonAction: retryAction\n        )\n        \n        parentView.addSubview(errorView)\n        errorView.translatesAutoresizingMaskIntoConstraints = false\n        \n        NSLayoutConstraint.activate([\n            errorView.topAnchor.constraint(equalTo: parentView.topAnchor),\n            errorView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),\n            errorView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),\n            errorView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)\n        ])\n        \n        errorView.show(animated: animated)\n    }\n    \n    // MARK: - Skeleton State\n    \n    private func showSkeletonState(count: Int, animated: Bool) {\n        guard let parentView = parentView else { return }\n        \n        let skeletonContainer = SkeletonContainerView()\n        currentSkeletonView = skeletonContainer\n        \n        // Create multiple skeleton items\n        let stackView = UIStackView()\n        stackView.axis = .vertical\n        stackView.spacing = 12\n        stackView.translatesAutoresizingMaskIntoConstraints = false\n        \n        for _ in 0..<count {\n            let skeletonItem = SkeletonContainerView()\n            skeletonItem.setupListItemSkeleton()\n            skeletonItem.translatesAutoresizingMaskIntoConstraints = false\n            stackView.addArrangedSubview(skeletonItem)\n            \n            NSLayoutConstraint.activate([\n                skeletonItem.heightAnchor.constraint(equalToConstant: 80)\n            ])\n        }\n        \n        skeletonContainer.addSubview(stackView)\n        parentView.addSubview(skeletonContainer)\n        skeletonContainer.translatesAutoresizingMaskIntoConstraints = false\n        \n        NSLayoutConstraint.activate([\n            skeletonContainer.topAnchor.constraint(equalTo: parentView.topAnchor),\n            skeletonContainer.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),\n            skeletonContainer.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),\n            skeletonContainer.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),\n            \n            stackView.topAnchor.constraint(equalTo: skeletonContainer.topAnchor, constant: 16),\n            stackView.leadingAnchor.constraint(equalTo: skeletonContainer.leadingAnchor, constant: 16),\n            stackView.trailingAnchor.constraint(equalTo: skeletonContainer.trailingAnchor, constant: -16)\n        ])\n        \n        if animated {\n            skeletonContainer.alpha = 0\n            UIView.animate(withDuration: 0.3) {\n                skeletonContainer.alpha = 1\n            }\n        }\n        \n        skeletonContainer.startAnimating()\n    }\n    \n    // MARK: - Convenience Methods\n    \n    public func showLoading(message: String? = nil) {\n        setState(.loading(message: message))\n    }\n    \n    public func showSkeleton(count: Int = 5) {\n        setState(.skeleton(count: count))\n    }\n    \n    public func showEmpty(type: EmptyStateType) {\n        setState(.empty(type: type))\n    }\n    \n    public func showError(_ message: String, retryAction: (() -> Void)? = nil) {\n        setState(.error(message: message, retryAction: retryAction))\n    }\n    \n    public func showSuccess() {\n        setState(.success)\n    }\n    \n    public func hide() {\n        clearCurrentState(animated: true)\n    }\n}\n\n// MARK: - UIView Extension\n\nextension UIView {\n    private static var loadingStateManagerKey: UInt8 = 0\n    \n    public var loadingStateManager: LoadingStateManager {\n        if let manager = objc_getAssociatedObject(self, &UIView.loadingStateManagerKey) as? LoadingStateManager {\n            return manager\n        }\n        \n        let manager = LoadingStateManager(parentView: self)\n        objc_setAssociatedObject(self, &UIView.loadingStateManagerKey, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)\n        return manager\n    }\n}\n