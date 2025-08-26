//
//  LoadingAnimations.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/21.
//

import UIKit

// MARK: - Pulse Loading View

class PulseLoadingView: UIView {
    
    private var pulseLayer: CAShapeLayer?
    private var animationGroup: CAAnimationGroup?
    
    var pulseColor: UIColor = CyberpunkTheme.neonCyan {
        didSet {
            pulseLayer?.strokeColor = pulseColor.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPulse()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPulse()
    }
    
    private func setupPulse() {
        let circleLayer = CAShapeLayer()
        let radius = min(bounds.width, bounds.height) / 2
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: 0,
                                endAngle: .pi * 2,
                                clockwise: true)
        
        circleLayer.path = path.cgPath
        circleLayer.strokeColor = pulseColor.cgColor
        circleLayer.lineWidth = 2
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = .round
        
        layer.addSublayer(circleLayer)
        pulseLayer = circleLayer
        
        startAnimation()
    }
    
    func startAnimation() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.8
        scaleAnimation.toValue = 1.2
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        animationGroup.duration = 1.5
        animationGroup.repeatCount = .infinity
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        pulseLayer?.add(animationGroup, forKey: "pulse")
        self.animationGroup = animationGroup
    }
    
    func stopAnimation() {
        pulseLayer?.removeAllAnimations()
    }
}

// MARK: - Wave Loading View

class WaveLoadingView: UIView {
    
    private var waveLayer: CAShapeLayer?
    private var displayLink: CADisplayLink?
    private var phase: CGFloat = 0
    
    var waveColor: UIColor = CyberpunkTheme.neonPink {
        didSet {
            waveLayer?.strokeColor = waveColor.cgColor
        }
    }
    
    var amplitude: CGFloat = 10
    var frequency: CGFloat = 1.5
    var speed: CGFloat = 0.1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWave()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWave()
    }
    
    private func setupWave() {
        let layer = CAShapeLayer()
        layer.strokeColor = waveColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 3
        layer.lineCap = .round
        
        self.layer.addSublayer(layer)
        waveLayer = layer
        
        startAnimation()
    }
    
    func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateWave))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateWave() {
        phase += speed
        
        let path = UIBezierPath()
        let width = bounds.width
        let height = bounds.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let y = sin(relativeX * .pi * frequency + phase) * amplitude + midHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        waveLayer?.path = path.cgPath
    }
}

// MARK: - Orbit Loading View

class OrbitLoadingView: UIView {
    
    private var orbitLayers: [CALayer] = []
    private let numberOfDots = 3
    
    var dotColor: UIColor = CyberpunkTheme.neonCyan {
        didSet {
            orbitLayers.forEach { $0.backgroundColor = dotColor.cgColor }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOrbit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOrbit()
    }
    
    private func setupOrbit() {
        let dotSize: CGFloat = 10
        let radius = min(bounds.width, bounds.height) / 3
        
        for i in 0..<numberOfDots {
            let dot = CALayer()
            dot.bounds = CGRect(x: 0, y: 0, width: dotSize, height: dotSize)
            dot.cornerRadius = dotSize / 2
            dot.backgroundColor = dotColor.cgColor
            
            let angle = (CGFloat(i) * 2 * .pi) / CGFloat(numberOfDots)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            dot.position = CGPoint(x: x, y: y)
            
            layer.addSublayer(dot)
            orbitLayers.append(dot)
            
            // Add orbit animation
            let orbitAnimation = CAKeyframeAnimation(keyPath: "position")
            let path = UIBezierPath(arcCenter: center,
                                   radius: radius,
                                   startAngle: angle,
                                   endAngle: angle + 2 * .pi,
                                   clockwise: true)
            orbitAnimation.path = path.cgPath
            orbitAnimation.duration = 2.0
            orbitAnimation.repeatCount = .infinity
            orbitAnimation.calculationMode = .paced
            
            // Add scale animation
            let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
            scaleAnimation.values = [1.0, 1.3, 1.0]
            scaleAnimation.keyTimes = [0, 0.5, 1.0]
            scaleAnimation.duration = 2.0
            scaleAnimation.repeatCount = .infinity
            
            // Add opacity animation
            let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
            opacityAnimation.values = [0.5, 1.0, 0.5]
            opacityAnimation.keyTimes = [0, 0.5, 1.0]
            opacityAnimation.duration = 2.0
            opacityAnimation.repeatCount = .infinity
            
            // Group animations
            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [orbitAnimation, scaleAnimation, opacityAnimation]
            animationGroup.duration = 2.0
            animationGroup.repeatCount = .infinity
            animationGroup.beginTime = CACurrentMediaTime() + Double(i) * 0.2
            
            dot.add(animationGroup, forKey: "orbit")
        }
    }
    
    func startAnimation() {
        orbitLayers.forEach { layer in
            if layer.animation(forKey: "orbit") == nil {
                setupOrbit()
            }
        }
    }
    
    func stopAnimation() {
        orbitLayers.forEach { $0.removeAllAnimations() }
    }
}

// MARK: - Morphing Loading View

class MorphingLoadingView: UIView {
    
    private var morphLayer: CAShapeLayer?
    private var currentShapeIndex = 0
    private let shapes: [UIBezierPath] = []
    
    var morphColor: UIColor = CyberpunkTheme.neonPink {
        didSet {
            morphLayer?.fillColor = morphColor.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMorphing()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMorphing()
    }
    
    private func setupMorphing() {
        let layer = CAShapeLayer()
        layer.fillColor = morphColor.cgColor
        layer.strokeColor = UIColor.clear.cgColor
        
        self.layer.addSublayer(layer)
        morphLayer = layer
        
        startAnimation()
    }
    
    private func createShapes() -> [UIBezierPath] {
        let size = min(bounds.width, bounds.height) * 0.5
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        // Circle
        let circle = UIBezierPath(arcCenter: center,
                                 radius: size / 2,
                                 startAngle: 0,
                                 endAngle: .pi * 2,
                                 clockwise: true)
        
        // Square
        let square = UIBezierPath(rect: CGRect(x: center.x - size/2,
                                              y: center.y - size/2,
                                              width: size,
                                              height: size))
        
        // Triangle
        let triangle = UIBezierPath()
        triangle.move(to: CGPoint(x: center.x, y: center.y - size/2))
        triangle.addLine(to: CGPoint(x: center.x - size/2, y: center.y + size/2))
        triangle.addLine(to: CGPoint(x: center.x + size/2, y: center.y + size/2))
        triangle.close()
        
        return [circle, square, triangle]
    }
    
    func startAnimation() {
        let shapes = createShapes()
        guard shapes.count > 1 else { return }
        
        morphLayer?.path = shapes[0].cgPath
        
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let nextIndex = (self.currentShapeIndex + 1) % shapes.count
            
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = shapes[self.currentShapeIndex].cgPath
            animation.toValue = shapes[nextIndex].cgPath
            animation.duration = 0.5
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            self.morphLayer?.add(animation, forKey: "morph")
            self.morphLayer?.path = shapes[nextIndex].cgPath
            self.currentShapeIndex = nextIndex
        }
    }
    
    func stopAnimation() {
        morphLayer?.removeAllAnimations()
    }
}

// MARK: - Matrix Loading View (Cyberpunk Style)

class MatrixLoadingView: UIView {
    
    private var textLayers: [CATextLayer] = []
    private var displayLink: CADisplayLink?
    private let characters = "01アイウエオカキクケコサシスセソタチツテト"
    
    var matrixColor: UIColor = CyberpunkTheme.neonGreen {
        didSet {
            updateColors()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMatrix()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMatrix()
    }
    
    private func setupMatrix() {
        backgroundColor = UIColor.black.withAlphaComponent(0.9)
        
        let columnWidth: CGFloat = 20
        let numberOfColumns = Int(bounds.width / columnWidth)
        
        for column in 0..<numberOfColumns {
            let x = CGFloat(column) * columnWidth
            let columnHeight = bounds.height
            let numberOfCharacters = Int(columnHeight / columnWidth)
            
            for row in 0..<numberOfCharacters {
                let textLayer = CATextLayer()
                textLayer.frame = CGRect(x: x, y: CGFloat(row) * columnWidth,
                                        width: columnWidth, height: columnWidth)
                textLayer.fontSize = 14
                textLayer.alignmentMode = .center
                textLayer.foregroundColor = matrixColor.withAlphaComponent(CGFloat.random(in: 0.1...1.0)).cgColor
                textLayer.string = String(characters.randomElement()!)
                
                layer.addSublayer(textLayer)
                textLayers.append(textLayer)
                
                // Animate falling
                animateFalling(layer: textLayer, delay: Double.random(in: 0...3))
            }
        }
    }
    
    private func animateFalling(layer: CATextLayer, delay: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = -20
        animation.toValue = bounds.height + 20
        animation.duration = Double.random(in: 2...5)
        animation.repeatCount = .infinity
        animation.beginTime = CACurrentMediaTime() + delay
        
        layer.add(animation, forKey: "falling")
        
        // Randomly change characters
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            if Bool.random() {
                layer.string = String(self.characters.randomElement()!)
            }
        }
    }
    
    private func updateColors() {
        textLayers.forEach {
            $0.foregroundColor = matrixColor.withAlphaComponent(CGFloat.random(in: 0.1...1.0)).cgColor
        }
    }
    
    func startAnimation() {
        // Animation starts automatically
    }
    
    func stopAnimation() {
        textLayers.forEach { $0.removeAllAnimations() }
    }
}

// MARK: - Loading View Factory

class LoadingViewFactory {
    
    enum LoadingStyle {
        case pulse
        case wave
        case orbit
        case morphing
        case matrix
        case typing
        case spinner
    }
    
    static func createLoadingView(style: LoadingStyle, frame: CGRect) -> UIView {
        switch style {
        case .pulse:
            return PulseLoadingView(frame: frame)
        case .wave:
            return WaveLoadingView(frame: frame)
        case .orbit:
            return OrbitLoadingView(frame: frame)
        case .morphing:
            return MorphingLoadingView(frame: frame)
        case .matrix:
            return MatrixLoadingView(frame: frame)
        case .typing:
            return AnimationManager.shared.createTypingIndicator()
        case .spinner:
            return AnimationManager.shared.createLoadingSpinner()
        }
    }
}

// MARK: - Loading Overlay

class LoadingOverlay: UIView {
    
    private let loadingView: UIView
    private let messageLabel = UILabel()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    init(style: LoadingViewFactory.LoadingStyle = .orbit, message: String? = nil) {
        self.loadingView = LoadingViewFactory.createLoadingView(style: style,
                                                               frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        super.init(frame: UIScreen.main.bounds)
        setupOverlay(message: message)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupOverlay(message: String?) {
        // Add blur background
        blurView.frame = bounds
        addSubview(blurView)
        
        // Container for loading view
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        container.layer.cornerRadius = 20
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        
        // Add loading view
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(loadingView)
        
        // Setup message label if provided
        if let message = message {
            messageLabel.text = message
            messageLabel.textColor = .white
            messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
            messageLabel.textAlignment = .center
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(messageLabel)
            
            NSLayoutConstraint.activate([
                container.centerXAnchor.constraint(equalTo: centerXAnchor),
                container.centerYAnchor.constraint(equalTo: centerYAnchor),
                container.widthAnchor.constraint(equalToConstant: 200),
                container.heightAnchor.constraint(equalToConstant: 180),
                
                loadingView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                loadingView.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
                loadingView.widthAnchor.constraint(equalToConstant: 100),
                loadingView.heightAnchor.constraint(equalToConstant: 100),
                
                messageLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
                messageLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
                messageLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
            ])
        } else {
            NSLayoutConstraint.activate([
                container.centerXAnchor.constraint(equalTo: centerXAnchor),
                container.centerYAnchor.constraint(equalTo: centerYAnchor),
                container.widthAnchor.constraint(equalToConstant: 150),
                container.heightAnchor.constraint(equalToConstant: 150),
                
                loadingView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                loadingView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                loadingView.widthAnchor.constraint(equalToConstant: 100),
                loadingView.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
        
        // Add glow effect
        container.layer.shadowColor = CyberpunkTheme.neonCyan.cgColor
        container.layer.shadowRadius = 20
        container.layer.shadowOpacity = 0.5
        container.layer.shadowOffset = .zero
    }
    
    func show(in view: UIView, animated: Bool = true) {
        view.addSubview(self)
        
        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            UIView.animate(withDuration: 0.3,
                          delay: 0,
                          usingSpringWithDamping: 0.8,
                          initialSpringVelocity: 0,
                          options: .curveEaseOut) {
                self.alpha = 1
                self.transform = .identity
            }
        }
    }
    
    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated {
            UIView.animate(withDuration: 0.3,
                          delay: 0,
                          options: .curveEaseIn,
                          animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { _ in
                self.removeFromSuperview()
                completion?()
            }
        } else {
            removeFromSuperview()
            completion?()
        }
    }
}