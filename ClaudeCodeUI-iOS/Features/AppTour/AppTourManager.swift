//
//  AppTourManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025/01/05.
//

import UIKit

/// Interactive app tour manager with spotlight effects
class AppTourManager: NSObject {
    
    // MARK: - Singleton
    static let shared = AppTourManager()
    
    // MARK: - Properties
    private var tourSteps: [TourStep] = []
    private var currentStepIndex = 0
    private var overlayView: AppTourOverlayView?
    private var targetWindow: UIWindow?
    
    // MARK: - Tour Steps
    struct TourStep {
        let title: String
        let description: String
        let targetView: UIView?
        let targetRect: CGRect?
        let position: TooltipPosition
        
        init(title: String, description: String, targetView: UIView? = nil, targetRect: CGRect? = nil, position: TooltipPosition = .bottom) {
            self.title = title
            self.description = description
            self.targetView = targetView
            self.targetRect = targetRect
            self.position = position
        }
    }
    
    enum TooltipPosition {
        case top, bottom, left, right
    }
    
    // MARK: - Public Methods
    
    /// Start the app tour
    func startTour(in window: UIWindow, steps: [TourStep]) {
        guard !steps.isEmpty else { return }
        
        self.targetWindow = window
        self.tourSteps = steps
        self.currentStepIndex = 0
        
        showOverlay()
        showCurrentStep()
    }
    
    /// Start project tour
    func startProjectsTour(in viewController: UIViewController) {
        guard let window = viewController.view.window else { return }
        
        let steps = [
            TourStep(
                title: "Welcome to Projects",
                description: "This is where all your Claude Code projects live. Tap any project to open it.",
                targetRect: CGRect(x: 20, y: 100, width: window.bounds.width - 40, height: 200),
                position: .bottom
            ),
            TourStep(
                title: "Create New Project",
                description: "Tap the + button to create a new project",
                targetRect: CGRect(x: window.bounds.width - 70, y: 50, width: 50, height: 50),
                position: .left
            ),
            TourStep(
                title: "Pull to Refresh",
                description: "Swipe down to sync your projects with the backend",
                targetRect: CGRect(x: 20, y: 100, width: window.bounds.width - 40, height: 100),
                position: .bottom
            )
        ]
        
        startTour(in: window, steps: steps)
    }
    
    /// Start chat tour
    func startChatTour(in viewController: UIViewController) {
        guard let window = viewController.view.window else { return }
        
        let steps = [
            TourStep(
                title: "Chat with Claude",
                description: "Type your questions here and Claude will help you code",
                targetRect: CGRect(x: 20, y: window.bounds.height - 100, width: window.bounds.width - 40, height: 50),
                position: .top
            ),
            TourStep(
                title: "File Attachments",
                description: "Tap the paperclip to attach files to your message",
                targetRect: CGRect(x: 20, y: window.bounds.height - 100, width: 44, height: 44),
                position: .top
            ),
            TourStep(
                title: "Terminal Access",
                description: "Tap the terminal icon to open the command line",
                targetRect: CGRect(x: 70, y: window.bounds.height - 100, width: 44, height: 44),
                position: .top
            )
        ]
        
        startTour(in: window, steps: steps)
    }
    
    /// End the tour
    func endTour() {
        overlayView?.removeFromSuperview()
        overlayView = nil
        tourSteps.removeAll()
        currentStepIndex = 0
        
        // Mark tour as completed
        UserDefaults.standard.set(true, forKey: "HasCompletedAppTour")
    }
    
    // MARK: - Private Methods
    
    private func showOverlay() {
        guard let window = targetWindow else { return }
        
        overlayView = AppTourOverlayView(frame: window.bounds)
        overlayView?.onNextTapped = { [weak self] in
            self?.nextStep()
        }
        overlayView?.onSkipTapped = { [weak self] in
            self?.endTour()
        }
        
        window.addSubview(overlayView!)
    }
    
    private func showCurrentStep() {
        guard currentStepIndex < tourSteps.count else {
            endTour()
            return
        }
        
        let step = tourSteps[currentStepIndex]
        overlayView?.showStep(step, index: currentStepIndex, total: tourSteps.count)
    }
    
    private func nextStep() {
        currentStepIndex += 1
        showCurrentStep()
    }
}

// MARK: - App Tour Overlay View
class AppTourOverlayView: UIView {
    
    // MARK: - Properties
    var onNextTapped: (() -> Void)?
    var onSkipTapped: (() -> Void)?
    
    private let spotlightLayer = CAShapeLayer()
    private let tooltipView = TooltipView()
    
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Skip Tour", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .claudeCodeFont(style: .body, weight: .medium)
        button.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .claudeCodeFont(style: .caption1, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // Add spotlight layer
        spotlightLayer.fillRule = .evenOdd
        layer.addSublayer(spotlightLayer)
        
        // Add tooltip
        addSubview(tooltipView)
        
        // Add controls
        addSubview(skipButton)
        addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            skipButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            progressLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            progressLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
        ])
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Public Methods
    func showStep(_ step: AppTourManager.TourStep, index: Int, total: Int) {
        // Update progress
        progressLabel.text = "\(index + 1) of \(total)"
        
        // Calculate spotlight rect
        let spotlightRect: CGRect
        if let targetView = step.targetView,
           let window = targetView.window {
            spotlightRect = window.convert(targetView.bounds, from: targetView)
        } else if let rect = step.targetRect {
            spotlightRect = rect
        } else {
            spotlightRect = CGRect(x: bounds.midX - 50, y: bounds.midY - 50, width: 100, height: 100)
        }
        
        // Create spotlight path
        let path = UIBezierPath(rect: bounds)
        let spotlightPath = UIBezierPath(roundedRect: spotlightRect.insetBy(dx: -10, dy: -10), cornerRadius: 12)
        path.append(spotlightPath)
        
        // Animate spotlight
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        spotlightLayer.path = path.cgPath
        spotlightLayer.fillColor = UIColor.black.withAlphaComponent(0.8).cgColor
        CATransaction.commit()
        
        // Position tooltip
        tooltipView.configure(title: step.title, description: step.description)
        positionTooltip(for: spotlightRect, position: step.position)
        
        // Animate tooltip
        tooltipView.alpha = 0
        tooltipView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.3, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.tooltipView.alpha = 1
            self.tooltipView.transform = .identity
        }
    }
    
    // MARK: - Private Methods
    private func positionTooltip(for spotlightRect: CGRect, position: AppTourManager.TooltipPosition) {
        let tooltipSize = tooltipView.sizeThatFits(CGSize(width: bounds.width - 40, height: .greatestFiniteMagnitude))
        var tooltipFrame = CGRect(origin: .zero, size: tooltipSize)
        
        switch position {
        case .top:
            tooltipFrame.origin.x = spotlightRect.midX - tooltipSize.width / 2
            tooltipFrame.origin.y = spotlightRect.minY - tooltipSize.height - 20
        case .bottom:
            tooltipFrame.origin.x = spotlightRect.midX - tooltipSize.width / 2
            tooltipFrame.origin.y = spotlightRect.maxY + 20
        case .left:
            tooltipFrame.origin.x = spotlightRect.minX - tooltipSize.width - 20
            tooltipFrame.origin.y = spotlightRect.midY - tooltipSize.height / 2
        case .right:
            tooltipFrame.origin.x = spotlightRect.maxX + 20
            tooltipFrame.origin.y = spotlightRect.midY - tooltipSize.height / 2
        }
        
        // Keep within bounds
        tooltipFrame.origin.x = max(20, min(bounds.width - tooltipSize.width - 20, tooltipFrame.origin.x))
        tooltipFrame.origin.y = max(60, min(bounds.height - tooltipSize.height - 100, tooltipFrame.origin.y))
        
        tooltipView.frame = tooltipFrame
    }
    
    // MARK: - Actions
    @objc private func skipTapped() {
        onSkipTapped?()
    }
    
    @objc private func overlayTapped() {
        onNextTapped?()
    }
}

// MARK: - Tooltip View
class TooltipView: UIView {
    
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = CyberpunkTheme.surface
        layer.cornerRadius = 16
        
        // Add glow
        addCyberpunkGlow(color: CyberpunkTheme.primaryCyan, intensity: 0.8, radius: 20)
        
        // Configure labels
        titleLabel.font = .claudeCodeFont(style: .headline, weight: .bold)
        titleLabel.textColor = CyberpunkTheme.primaryCyan
        titleLabel.numberOfLines = 0
        
        descriptionLabel.font = .claudeCodeFont(style: .body)
        descriptionLabel.textColor = CyberpunkTheme.text
        descriptionLabel.numberOfLines = 0
        
        nextButton.setTitle("Next →", for: .normal)
        nextButton.setTitleColor(CyberpunkTheme.primaryCyan, for: .normal)
        nextButton.titleLabel?.font = .claudeCodeFont(style: .body, weight: .semibold)
        
        // Layout
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, nextButton])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .trailing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    func configure(title: String, description: String) {
        titleLabel.text = title
        descriptionLabel.text = description
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let width = min(size.width, 320)
        let titleSize = titleLabel.sizeThatFits(CGSize(width: width - 40, height: .greatestFiniteMagnitude))
        let descSize = descriptionLabel.sizeThatFits(CGSize(width: width - 40, height: .greatestFiniteMagnitude))
        let buttonSize = nextButton.sizeThatFits(CGSize(width: width - 40, height: 44))
        
        let height = titleSize.height + descSize.height + buttonSize.height + 12 * 2 + 40
        return CGSize(width: width, height: height)
    }
}