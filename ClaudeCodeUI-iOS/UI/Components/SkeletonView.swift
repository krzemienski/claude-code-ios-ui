//
//  SkeletonView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-16.
//

import UIKit

/// A reusable skeleton loading view with cyberpunk shimmer animations
public class SkeletonView: UIView {
    
    // MARK: - Properties
    
    private let gradientLayer = CAGradientLayer()
    private let animationGroup = CAAnimationGroup()
    
    /// The style of the skeleton view
    public enum Style {
        case listItem
        case card
        case textBlock
        case circle
        case custom(cornerRadius: CGFloat)
    }
    
    private var style: Style = .listItem
    
    // MARK: - Initialization
    
    public init(style: Style = .listItem) {
        self.style = style
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = CyberpunkTheme.surface
        
        // Configure corner radius based on style
        switch style {
        case .listItem:
            layer.cornerRadius = 8
        case .card:
            layer.cornerRadius = 16
        case .textBlock:
            layer.cornerRadius = 4
        case .circle:
            // Will be set after layout
            break
        case .custom(let radius):
            layer.cornerRadius = radius
        }
        
        layer.masksToBounds = true
        
        // Setup gradient layer for shimmer effect
        setupGradientLayer()
    }
    
    private func setupGradientLayer() {
        // Cyberpunk gradient colors
        let baseColor = CyberpunkTheme.surface.cgColor
        let shimmerColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        let highlightColor = CyberpunkTheme.accentPink.withAlphaComponent(0.2).cgColor
        
        gradientLayer.colors = [
            baseColor,
            shimmerColor,
            highlightColor,
            shimmerColor,
            baseColor
        ]
        
        gradientLayer.locations = [0.0, 0.4, 0.5, 0.6, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        layer.addSublayer(gradientLayer)
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        gradientLayer.frame = CGRect(x: -bounds.width, y: 0, width: bounds.width * 3, height: bounds.height)
        
        // Set corner radius for circle style
        if case .circle = style {
            layer.cornerRadius = min(bounds.width, bounds.height) / 2
        }
    }
    
    // MARK: - Animation
    
    /// Starts the shimmer animation
    public func startAnimating() {
        // Remove any existing animations
        gradientLayer.removeAllAnimations()
        
        // Create shimmer animation
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.duration = 2.0
        animation.fromValue = -bounds.width
        animation.toValue = bounds.width
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Add glow pulse animation for extra cyberpunk effect
        let glowAnimation = CABasicAnimation(keyPath: "opacity")
        glowAnimation.duration = 1.5
        glowAnimation.fromValue = 0.7
        glowAnimation.toValue = 1.0
        glowAnimation.repeatCount = .infinity
        glowAnimation.autoreverses = true
        glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Combine animations
        animationGroup.duration = 2.0
        animationGroup.repeatCount = .infinity
        animationGroup.animations = [animation, glowAnimation]
        
        gradientLayer.add(animationGroup, forKey: "shimmer")
    }
    
    /// Stops the shimmer animation
    public func stopAnimating() {
        gradientLayer.removeAllAnimations()
    }
}

// MARK: - Skeleton Container View

/// A container view for multiple skeleton elements
public class SkeletonContainerView: UIView {
    
    private var skeletonViews: [SkeletonView] = []
    
    /// Creates a list item skeleton with title and subtitle
    public func setupListItemSkeleton() {
        // Clear existing skeletons
        skeletonViews.forEach { $0.removeFromSuperview() }
        skeletonViews.removeAll()
        
        // Title skeleton
        let titleSkeleton = SkeletonView(style: .textBlock)
        titleSkeleton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleSkeleton)
        skeletonViews.append(titleSkeleton)
        
        // Subtitle skeleton
        let subtitleSkeleton = SkeletonView(style: .textBlock)
        subtitleSkeleton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleSkeleton)
        skeletonViews.append(subtitleSkeleton)
        
        // Avatar skeleton
        let avatarSkeleton = SkeletonView(style: .circle)
        avatarSkeleton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarSkeleton)
        skeletonViews.append(avatarSkeleton)
        
        NSLayoutConstraint.activate([
            // Avatar
            avatarSkeleton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarSkeleton.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarSkeleton.widthAnchor.constraint(equalToConstant: 44),
            avatarSkeleton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title
            titleSkeleton.leadingAnchor.constraint(equalTo: avatarSkeleton.trailingAnchor, constant: 12),
            titleSkeleton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleSkeleton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleSkeleton.heightAnchor.constraint(equalToConstant: 20),
            
            // Subtitle
            subtitleSkeleton.leadingAnchor.constraint(equalTo: titleSkeleton.leadingAnchor),
            subtitleSkeleton.topAnchor.constraint(equalTo: titleSkeleton.bottomAnchor, constant: 8),
            subtitleSkeleton.widthAnchor.constraint(equalTo: titleSkeleton.widthAnchor, multiplier: 0.7),
            subtitleSkeleton.heightAnchor.constraint(equalToConstant: 16),
            subtitleSkeleton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    /// Creates a card skeleton with image and text
    public func setupCardSkeleton() {
        // Clear existing skeletons
        skeletonViews.forEach { $0.removeFromSuperview() }
        skeletonViews.removeAll()
        
        // Image skeleton
        let imageSkeleton = SkeletonView(style: .card)
        imageSkeleton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageSkeleton)
        skeletonViews.append(imageSkeleton)
        
        // Title skeleton
        let titleSkeleton = SkeletonView(style: .textBlock)
        titleSkeleton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleSkeleton)
        skeletonViews.append(titleSkeleton)
        
        // Description skeleton lines
        for i in 0..<3 {
            let lineSkeleton = SkeletonView(style: .textBlock)
            lineSkeleton.translatesAutoresizingMaskIntoConstraints = false
            addSubview(lineSkeleton)
            skeletonViews.append(lineSkeleton)
            
            NSLayoutConstraint.activate([
                lineSkeleton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                lineSkeleton.topAnchor.constraint(equalTo: titleSkeleton.bottomAnchor, constant: CGFloat(20 + i * 24)),
                lineSkeleton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: CGFloat(i == 2 ? -80 : -16)),
                lineSkeleton.heightAnchor.constraint(equalToConstant: 14)
            ])
        }
        
        NSLayoutConstraint.activate([
            // Image
            imageSkeleton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            imageSkeleton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            imageSkeleton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            imageSkeleton.heightAnchor.constraint(equalToConstant: 180),
            
            // Title
            titleSkeleton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleSkeleton.topAnchor.constraint(equalTo: imageSkeleton.bottomAnchor, constant: 16),
            titleSkeleton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            titleSkeleton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    /// Starts animating all skeleton views
    public func startAnimating() {
        skeletonViews.forEach { $0.startAnimating() }
    }
    
    /// Stops animating all skeleton views
    public func stopAnimating() {
        skeletonViews.forEach { $0.stopAnimating() }
    }
    
    /// Shows the skeleton view with animation
    public func show() {
        isHidden = false
        alpha = 0
        startAnimating()
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    /// Hides the skeleton view with animation
    public func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.stopAnimating()
            self.isHidden = true
            completion?()
        }
    }
}

// MARK: - UITableView Extension for Skeleton Loading

public extension UITableView {
    
    private static var skeletonViewKey: UInt8 = 0
    
    private var skeletonView: UIView? {
        get {
            return objc_getAssociatedObject(self, &UITableView.skeletonViewKey) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &UITableView.skeletonViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Shows skeleton loading cells
    func showSkeletonLoading(count: Int = 5) {
        // Create container view
        let containerView = UIView(frame: bounds)
        containerView.backgroundColor = backgroundColor
        
        // Add skeleton cells
        var previousSkeleton: SkeletonContainerView?
        for i in 0..<count {
            let skeleton = SkeletonContainerView()
            skeleton.translatesAutoresizingMaskIntoConstraints = false
            skeleton.setupListItemSkeleton()
            containerView.addSubview(skeleton)
            
            NSLayoutConstraint.activate([
                skeleton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                skeleton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                skeleton.heightAnchor.constraint(equalToConstant: 80)
            ])
            
            if let previous = previousSkeleton {
                skeleton.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 1).isActive = true
            } else {
                skeleton.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
            }
            
            skeleton.show()
            previousSkeleton = skeleton
        }
        
        // Add as overlay
        skeletonView = containerView
        addSubview(containerView)
        bringSubviewToFront(containerView)
    }
    
    /// Hides skeleton loading
    func hideSkeletonLoading() {
        UIView.animate(withDuration: 0.3, animations: {
            self.skeletonView?.alpha = 0
        }) { _ in
            self.skeletonView?.removeFromSuperview()
            self.skeletonView = nil
        }
    }
}