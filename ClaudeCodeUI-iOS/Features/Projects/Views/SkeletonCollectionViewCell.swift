//
//  SkeletonCollectionViewCell.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-20.
//

import UIKit

class SkeletonCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "SkeletonCollectionViewCell"
    
    // MARK: - UI Elements
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = CyberpunkTheme.background
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = CyberpunkTheme.border.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleSkeleton: UIView = {
        let view = UIView()
        view.backgroundColor = CyberpunkTheme.secondaryText.withAlphaComponent(0.2)
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let pathSkeleton: UIView = {
        let view = UIView()
        view.backgroundColor = CyberpunkTheme.secondaryText.withAlphaComponent(0.15)
        view.layer.cornerRadius = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statusSkeleton: UIView = {
        let view = UIView()
        view.backgroundColor = CyberpunkTheme.secondaryText.withAlphaComponent(0.1)
        view.layer.cornerRadius = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconSkeleton: UIView = {
        let view = UIView()
        view.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.15)
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var shimmerLayer: CAGradientLayer?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupShimmerAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconSkeleton)
        containerView.addSubview(titleSkeleton)
        containerView.addSubview(pathSkeleton)
        containerView.addSubview(statusSkeleton)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Icon skeleton
            iconSkeleton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconSkeleton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconSkeleton.widthAnchor.constraint(equalToConstant: 40),
            iconSkeleton.heightAnchor.constraint(equalToConstant: 40),
            
            // Title skeleton
            titleSkeleton.topAnchor.constraint(equalTo: iconSkeleton.topAnchor),
            titleSkeleton.leadingAnchor.constraint(equalTo: iconSkeleton.trailingAnchor, constant: 12),
            titleSkeleton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleSkeleton.heightAnchor.constraint(equalToConstant: 20),
            
            // Path skeleton
            pathSkeleton.topAnchor.constraint(equalTo: titleSkeleton.bottomAnchor, constant: 8),
            pathSkeleton.leadingAnchor.constraint(equalTo: titleSkeleton.leadingAnchor),
            pathSkeleton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.6),
            pathSkeleton.heightAnchor.constraint(equalToConstant: 14),
            
            // Status skeleton
            statusSkeleton.topAnchor.constraint(equalTo: pathSkeleton.bottomAnchor, constant: 12),
            statusSkeleton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            statusSkeleton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.4),
            statusSkeleton.heightAnchor.constraint(equalToConstant: 14),
            statusSkeleton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupShimmerAnimation() {
        // Create gradient layer for shimmer effect
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.05).cgColor,
            UIColor.white.withAlphaComponent(0.1).cgColor,
            UIColor.white.withAlphaComponent(0.05).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0, 0.4, 0.5, 0.6, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = CGRect(x: -bounds.width, y: 0, width: bounds.width * 3, height: bounds.height)
        
        containerView.layer.mask = gradientLayer
        shimmerLayer = gradientLayer
    }
    
    // MARK: - Animation
    
    func startAnimating() {
        guard let shimmerLayer = shimmerLayer else { return }
        
        // Remove any existing animations
        shimmerLayer.removeAllAnimations()
        
        // Update frame
        shimmerLayer.frame = CGRect(x: -bounds.width, y: 0, width: bounds.width * 3, height: bounds.height)
        
        // Create shimmer animation
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -bounds.width
        animation.toValue = bounds.width
        animation.duration = 1.5
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        shimmerLayer.add(animation, forKey: "shimmer")
        
        // Also add a subtle pulse animation to the skeleton elements
        [titleSkeleton, pathSkeleton, statusSkeleton, iconSkeleton].forEach { view in
            UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
                view.alpha = 0.5
            })
        }
    }
    
    func stopAnimating() {
        shimmerLayer?.removeAllAnimations()
        [titleSkeleton, pathSkeleton, statusSkeleton, iconSkeleton].forEach { view in
            view.layer.removeAllAnimations()
            view.alpha = 1.0
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update shimmer layer frame when cell layout changes
        shimmerLayer?.frame = CGRect(x: -bounds.width, y: 0, width: bounds.width * 3, height: bounds.height)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopAnimating()
    }
}