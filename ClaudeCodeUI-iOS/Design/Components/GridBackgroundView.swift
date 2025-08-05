//
//  GridBackgroundView.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

class GridBackgroundView: UIView {
    
    private let gridSize: CGFloat = 40
    private var gridLayer: CAShapeLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateGrid()
    }
    
    private func setupView() {
        backgroundColor = CyberpunkTheme.background
        updateGrid()
    }
    
    private func updateGrid() {
        // Remove existing grid layer
        gridLayer?.removeFromSuperlayer()
        
        // Create new grid layer
        let layer = CAShapeLayer()
        let path = UIBezierPath()
        
        // Vertical lines
        var x: CGFloat = 0
        while x <= bounds.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: bounds.height))
            x += gridSize
        }
        
        // Horizontal lines
        var y: CGFloat = 0
        while y <= bounds.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: bounds.width, y: y))
            y += gridSize
        }
        
        layer.path = path.cgPath
        layer.strokeColor = CyberpunkTheme.gridLineColor.cgColor
        layer.lineWidth = 0.5
        layer.opacity = 0.3
        
        self.layer.insertSublayer(layer, at: 0)
        gridLayer = layer
    }
}

// MARK: - UIView Extension for Grid Background
extension UIView {
    func addClaudeCodeGridBackground() {
        // Check if grid background already exists
        if subviews.contains(where: { $0 is GridBackgroundView }) {
            return
        }
        
        let gridView = GridBackgroundView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(gridView, at: 0)
        
        NSLayoutConstraint.activate([
            gridView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gridView.topAnchor.constraint(equalTo: topAnchor),
            gridView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}