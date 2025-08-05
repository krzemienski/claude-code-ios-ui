//
//  GradientBlock.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

class GradientBlock: UIView {
    
    enum GradientType {
        case blue
        case purple
        
        var colors: [UIColor] {
            switch self {
            case .blue:
                return [
                    UIColor(hex: "#0066FF")!,
                    UIColor(hex: "#0044CC")!
                ]
            case .purple:
                return [
                    UIColor(hex: "#9933FF")!,
                    UIColor(hex: "#FF006E")!
                ]
            }
        }
    }
    
    private let gradientLayer = CAGradientLayer()
    let type: GradientType
    
    init(type: GradientType) {
        self.type = type
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.type = .blue
        super.init(coder: coder)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    private func setupView() {
        // Configure gradient
        gradientLayer.colors = type.colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 12
        
        layer.insertSublayer(gradientLayer, at: 0)
        layer.cornerRadius = 12
        
        // Add shadow
        layer.shadowColor = type.colors.first?.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 8
        layer.shadowOffset = .zero
    }
}

class GradientBlockPair: UIView {
    
    private let blueBlock = GradientBlock(type: .blue)
    private let purpleBlock = GradientBlock(type: .purple)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(blueBlock)
        addSubview(purpleBlock)
        
        blueBlock.translatesAutoresizingMaskIntoConstraints = false
        purpleBlock.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Blue block
            blueBlock.leadingAnchor.constraint(equalTo: leadingAnchor),
            blueBlock.topAnchor.constraint(equalTo: topAnchor),
            blueBlock.bottomAnchor.constraint(equalTo: bottomAnchor),
            blueBlock.widthAnchor.constraint(equalToConstant: 44),
            blueBlock.heightAnchor.constraint(equalToConstant: 44),
            
            // Purple block
            purpleBlock.leadingAnchor.constraint(equalTo: blueBlock.trailingAnchor, constant: 12),
            purpleBlock.topAnchor.constraint(equalTo: topAnchor),
            purpleBlock.bottomAnchor.constraint(equalTo: bottomAnchor),
            purpleBlock.trailingAnchor.constraint(equalTo: trailingAnchor),
            purpleBlock.widthAnchor.constraint(equalToConstant: 44),
            purpleBlock.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: 44)
    }
}