//
//  SkeletonView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-17.
//  Skeleton loading view with cyberpunk shimmer animations
//

import UIKit

// MARK: - SkeletonView Component

class SkeletonView: UIView {
    
    // MARK: - Properties
    
    private var shimmerLayers: [CAGradientLayer] = []
    private var isAnimating = false
    
    // Configuration
    var cornerRadius: CGFloat = 8 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    var shimmerColor: UIColor = CyberpunkTheme.primaryCyan {
        didSet {
            updateShimmerColors()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateShimmerLayout()
    }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = CyberpunkTheme.surface
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        
        // Add subtle border
        layer.borderWidth = 1
        layer.borderColor = CyberpunkTheme.border.cgColor
        
        createShimmerLayers()
    }
    
    private func createShimmerLayers() {
        // Primary shimmer layer
        let primaryShimmer = CAGradientLayer()
        primaryShimmer.colors = [
            CyberpunkTheme.surface.cgColor,
            shimmerColor.withAlphaComponent(0.3).cgColor,
            CyberpunkTheme.surface.cgColor
        ]
        primaryShimmer.locations = [0.0, 0.5, 1.0]
        primaryShimmer.startPoint = CGPoint(x: 0.0, y: 0.5)
        primaryShimmer.endPoint = CGPoint(x: 1.0, y: 0.5)
        layer.addSublayer(primaryShimmer)
        shimmerLayers.append(primaryShimmer)
        
        // Secondary shimmer layer for enhanced effect
        let secondaryShimmer = CAGradientLayer()
        secondaryShimmer.colors = [
            UIColor.clear.cgColor,
            shimmerColor.withAlphaComponent(0.1).cgColor,
            UIColor.clear.cgColor
        ]
        secondaryShimmer.locations = [0.0, 0.5, 1.0]
        secondaryShimmer.startPoint = CGPoint(x: 0.0, y: 0.5)
        secondaryShimmer.endPoint = CGPoint(x: 1.0, y: 0.5)
        layer.addSublayer(secondaryShimmer)
        shimmerLayers.append(secondaryShimmer)
    }
    
    private func updateShimmerColors() {
        guard shimmerLayers.count >= 2 else { return }
        
        shimmerLayers[0].colors = [
            CyberpunkTheme.surface.cgColor,
            shimmerColor.withAlphaComponent(0.3).cgColor,
            CyberpunkTheme.surface.cgColor
        ]
        
        shimmerLayers[1].colors = [
            UIColor.clear.cgColor,
            shimmerColor.withAlphaComponent(0.1).cgColor,
            UIColor.clear.cgColor
        ]
    }
    
    private func updateShimmerLayout() {
        let shimmerWidth = bounds.width * 3
        let shimmerFrame = CGRect(
            x: -bounds.width,
            y: 0,
            width: shimmerWidth,
            height: bounds.height
        )
        
        shimmerLayers.forEach { $0.frame = shimmerFrame }
    }
    
    // MARK: - Animation Control
    
    func startShimmering() {
        guard !isAnimating else { return }
        isAnimating = true
        
        shimmerLayers.enumerated().forEach { index, layer in
            let animation = CABasicAnimation(keyPath: "transform.translation.x")
            animation.duration = 1.5 + Double(index) * 0.2
            animation.fromValue = -bounds.width
            animation.toValue = bounds.width * 2
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.autoreverses = false
            
            layer.add(animation, forKey: "shimmer")
        }
    }
    
    func stopShimmering() {
        guard isAnimating else { return }
        isAnimating = false
        
        shimmerLayers.forEach { $0.removeAllAnimations() }
    }
    
    // MARK: - Factory Methods
    
    static func createLine(width: CGFloat = 100, height: CGFloat = 16) -> SkeletonView {
        let skeleton = SkeletonView()
        skeleton.translatesAutoresizingMaskIntoConstraints = false
        skeleton.cornerRadius = height / 2
        
        NSLayoutConstraint.activate([
            skeleton.widthAnchor.constraint(equalToConstant: width),
            skeleton.heightAnchor.constraint(equalToConstant: height)
        ])
        
        return skeleton
    }
    
    static func createCircle(diameter: CGFloat = 44) -> SkeletonView {
        let skeleton = SkeletonView()
        skeleton.translatesAutoresizingMaskIntoConstraints = false
        skeleton.cornerRadius = diameter / 2
        
        NSLayoutConstraint.activate([
            skeleton.widthAnchor.constraint(equalToConstant: diameter),
            skeleton.heightAnchor.constraint(equalToConstant: diameter)
        ])
        
        return skeleton
    }
    
    static func createRectangle(width: CGFloat = 100, height: CGFloat = 60, cornerRadius: CGFloat = 8) -> SkeletonView {
        let skeleton = SkeletonView()
        skeleton.translatesAutoresizingMaskIntoConstraints = false
        skeleton.cornerRadius = cornerRadius
        
        NSLayoutConstraint.activate([
            skeleton.widthAnchor.constraint(equalToConstant: width),
            skeleton.heightAnchor.constraint(equalToConstant: height)
        ])
        
        return skeleton
    }
}

// MARK: - UITableView Skeleton Extension

extension UITableView {
    
    func showSkeletonLoading(count: Int = 6, cellHeight: CGFloat = 80) {
        // Remove existing skeleton if any
        hideSkeletonLoading()
        
        let containerView = UIView()
        containerView.backgroundColor = CyberpunkTheme.background
        containerView.tag = 9999 // Tag for identification
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: CGFloat(count) * cellHeight)
        ])
        
        var previousCell: UIView?
        
        for i in 0..<count {
            let cellContainer = createSkeletonCell(height: cellHeight)
            containerView.addSubview(cellContainer)
            
            NSLayoutConstraint.activate([
                cellContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                cellContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                cellContainer.heightAnchor.constraint(equalToConstant: cellHeight)
            ])
            
            if let previous = previousCell {
                cellContainer.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 1).isActive = true
            } else {
                cellContainer.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
            }
            
            previousCell = cellContainer
        }
        
        // Animate appearance
        containerView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            containerView.alpha = 1
        }
        
        bringSubviewToFront(containerView)
    }
    
    func hideSkeletonLoading() {
        if let skeletonView = viewWithTag(9999) {
            UIView.animate(withDuration: 0.3, animations: {
                skeletonView.alpha = 0
            }) { _ in
                skeletonView.removeFromSuperview()
            }
        }
    }
    
    private func createSkeletonCell(height: CGFloat) -> UIView {
        let cellView = UIView()
        cellView.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.3)
        cellView.translatesAutoresizingMaskIntoConstraints = false
        
        // Avatar skeleton
        let avatar = SkeletonView.createCircle(diameter: 44)
        avatar.shimmerColor = CyberpunkTheme.primaryCyan
        cellView.addSubview(avatar)
        
        // Title skeleton
        let title = SkeletonView.createLine(width: 160, height: 20)
        title.shimmerColor = CyberpunkTheme.primaryCyan
        cellView.addSubview(title)
        
        // Subtitle skeleton
        let subtitle = SkeletonView.createLine(width: 120, height: 16)
        subtitle.shimmerColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.6)
        cellView.addSubview(subtitle)
        
        // Date skeleton
        let date = SkeletonView.createLine(width: 60, height: 12)
        date.shimmerColor = CyberpunkTheme.secondaryText
        cellView.addSubview(date)
        
        NSLayoutConstraint.activate([
            // Avatar
            avatar.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 16),
            avatar.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
            
            // Title
            title.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            title.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 16),
            
            // Subtitle
            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            
            // Date
            date.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -16),
            date.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 16)
        ])
        
        // Start animations with slight delays
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            [avatar, title, subtitle, date].forEach { $0.startShimmering() }
        }
        
        return cellView
    }
}

// MARK: - UICollectionView Skeleton Extension

extension UICollectionView {
    
    func showSkeletonLoading(count: Int = 6, itemSize: CGSize = CGSize(width: 160, height: 180)) {
        hideSkeletonLoading()
        
        let containerView = UIView()
        containerView.backgroundColor = CyberpunkTheme.background
        containerView.tag = 9999
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        let columns = 2
        let rows = (count + columns - 1) / columns
        let spacing: CGFloat = 16
        
        for i in 0..<count {
            let row = i / columns
            let col = i % columns
            
            let itemView = createSkeletonItem(size: itemSize)
            containerView.addSubview(itemView)
            
            NSLayoutConstraint.activate([
                itemView.widthAnchor.constraint(equalToConstant: itemSize.width),
                itemView.heightAnchor.constraint(equalToConstant: itemSize.height),
                itemView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, 
                                                 constant: spacing + CGFloat(col) * (itemSize.width + spacing)),
                itemView.topAnchor.constraint(equalTo: containerView.topAnchor, 
                                             constant: spacing + CGFloat(row) * (itemSize.height + spacing))
            ])
        }
        
        // Animate appearance
        containerView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            containerView.alpha = 1
        }
        
        bringSubviewToFront(containerView)
    }
    
    func hideSkeletonLoading() {
        if let skeletonView = viewWithTag(9999) {
            UIView.animate(withDuration: 0.3, animations: {
                skeletonView.alpha = 0
            }) { _ in
                skeletonView.removeFromSuperview()
            }
        }
    }
    
    private func createSkeletonItem(size: CGSize) -> UIView {
        let itemView = UIView()
        itemView.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.3)
        itemView.layer.cornerRadius = 12
        itemView.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon skeleton
        let icon = SkeletonView.createCircle(diameter: 40)
        icon.shimmerColor = CyberpunkTheme.primaryCyan
        itemView.addSubview(icon)
        
        // Title skeleton
        let title = SkeletonView.createLine(width: size.width - 32, height: 18)
        title.shimmerColor = CyberpunkTheme.primaryCyan
        itemView.addSubview(title)
        
        // Description skeleton
        let desc1 = SkeletonView.createLine(width: size.width - 32, height: 14)
        desc1.shimmerColor = CyberpunkTheme.secondaryText
        itemView.addSubview(desc1)
        
        let desc2 = SkeletonView.createLine(width: (size.width - 32) * 0.7, height: 14)
        desc2.shimmerColor = CyberpunkTheme.secondaryText
        itemView.addSubview(desc2)
        
        NSLayoutConstraint.activate([
            // Icon
            icon.centerXAnchor.constraint(equalTo: itemView.centerXAnchor),
            icon.topAnchor.constraint(equalTo: itemView.topAnchor, constant: 20),
            
            // Title
            title.centerXAnchor.constraint(equalTo: itemView.centerXAnchor),
            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 16),
            
            // Description lines
            desc1.centerXAnchor.constraint(equalTo: itemView.centerXAnchor),
            desc1.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            
            desc2.centerXAnchor.constraint(equalTo: itemView.centerXAnchor),
            desc2.topAnchor.constraint(equalTo: desc1.bottomAnchor, constant: 8)
        ])
        
        // Start animations
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.1...0.3)) {
            [icon, title, desc1, desc2].forEach { $0.startShimmering() }
        }
        
        return itemView
    }
}

// MARK: - View Extension for Enhanced Loading States

extension UIView {
    
    var skeletonLoadingStateManager: SkeletonLoadingStateManager {
        return SkeletonLoadingStateManager(view: self)
    }
}

struct SkeletonLoadingStateManager {
    private weak var view: UIView?
    
    init(view: UIView) {
        self.view = view
    }
    
    func showSkeleton(count: Int = 6, cellHeight: CGFloat = 80) {
        if let tableView = view as? UITableView {
            tableView.showSkeletonLoading(count: count, cellHeight: cellHeight)
        } else if let collectionView = view as? UICollectionView {
            collectionView.showSkeletonLoading(count: count)
        }
    }
    
    func hideSkeleton() {
        if let tableView = view as? UITableView {
            tableView.hideSkeletonLoading()
        } else if let collectionView = view as? UICollectionView {
            collectionView.hideSkeletonLoading()
        }
    }
    
    func showEmpty(type: EmptyStateType) {
        guard let view = view else { return }
        
        // Remove existing empty state
        hide()
        
        let emptyView = NoDataView(type: type)
        emptyView.tag = 8888
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(emptyView)
        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
        
        // Animate appearance
        emptyView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            emptyView.alpha = 1
        }
        
        view.bringSubviewToFront(emptyView)
    }
    
    func hide() {
        // Hide skeleton
        hideSkeleton()
        
        // Hide empty state
        if let emptyView = view?.viewWithTag(8888) {
            UIView.animate(withDuration: 0.3, animations: {
                emptyView.alpha = 0
            }) { _ in
                emptyView.removeFromSuperview()
            }
        }
    }
}