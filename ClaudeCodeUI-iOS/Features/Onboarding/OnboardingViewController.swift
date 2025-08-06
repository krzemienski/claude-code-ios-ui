//
//  OnboardingViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025/01/05.
//

import UIKit

/// Onboarding flow controller for new users
class OnboardingViewController: UIViewController {
    
    // MARK: - Properties
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private var pages: [UIViewController] = []
    private var currentIndex = 0
    
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = CyberpunkTheme.primaryCyan
        control.pageIndicatorTintColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Skip", for: .normal)
        button.setTitleColor(CyberpunkTheme.primaryCyan, for: .normal)
        button.titleLabel?.font = .claudeCodeFont(style: .body, weight: .medium)
        button.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.setTitleColor(CyberpunkTheme.background, for: .normal)
        button.backgroundColor = CyberpunkTheme.primaryCyan
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .claudeCodeFont(style: .headline, weight: .semibold)
        button.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addCyberpunkGlow()
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        createPages()
        setupPageViewController()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add page view controller
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.didMove(toParent: self)
        
        // Add controls
        view.addSubview(pageControl)
        view.addSubview(skipButton)
        view.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            // Page view controller
            pageViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),
            
            // Page control
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -30),
            
            // Skip button
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Next button
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // Add accessibility
        skipButton.accessibilityLabel = "Skip onboarding"
        nextButton.accessibilityLabel = "Next page"
        pageControl.accessibilityLabel = "Onboarding progress"
    }
    
    private func createPages() {
        // Page 1: Welcome
        let welcomePage = OnboardingPageViewController(
            title: "Welcome to Claude Code",
            subtitle: "Your AI-powered coding companion",
            imageName: "sparkles",
            description: "Experience the future of development with Claude's intelligent assistance"
        )
        
        // Page 2: Projects
        let projectsPage = OnboardingPageViewController(
            title: "Manage Your Projects",
            subtitle: "Organize and access your work",
            imageName: "folder.fill",
            description: "Create, manage, and sync projects across all your devices"
        )
        
        // Page 3: Chat
        let chatPage = OnboardingPageViewController(
            title: "Chat with Claude",
            subtitle: "Get instant coding help",
            imageName: "message.fill",
            description: "Ask questions, debug code, and learn new concepts in real-time"
        )
        
        // Page 4: File Explorer
        let filesPage = OnboardingPageViewController(
            title: "Browse Your Files",
            subtitle: "Navigate your codebase",
            imageName: "doc.text.fill",
            description: "View, edit, and manage files with syntax highlighting"
        )
        
        // Page 5: Terminal
        let terminalPage = OnboardingPageViewController(
            title: "Terminal Access",
            subtitle: "Run commands directly",
            imageName: "terminal.fill",
            description: "Execute commands and scripts within your project environment"
        )
        
        // Page 6: Get Started
        let getStartedPage = OnboardingPageViewController(
            title: "Ready to Begin",
            subtitle: "Let's configure your setup",
            imageName: "checkmark.circle.fill",
            description: "Connect to your backend and start coding with Claude"
        )
        
        pages = [welcomePage, projectsPage, chatPage, filesPage, terminalPage, getStartedPage]
        pageControl.numberOfPages = pages.count
    }
    
    private func setupPageViewController() {
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        if let firstPage = pages.first {
            pageViewController.setViewControllers([firstPage], direction: .forward, animated: false)
        }
    }
    
    // MARK: - Actions
    @objc private func skipTapped() {
        completeOnboarding()
    }
    
    @objc private func nextTapped() {
        if currentIndex < pages.count - 1 {
            currentIndex += 1
            pageViewController.setViewControllers([pages[currentIndex]], direction: .forward, animated: true)
            pageControl.currentPage = currentIndex
            updateButtonTitle()
        } else {
            completeOnboarding()
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func updateButtonTitle() {
        if currentIndex == pages.count - 1 {
            nextButton.setTitle("Get Started", for: .normal)
            nextButton.accessibilityLabel = "Get started"
        } else {
            nextButton.setTitle("Next", for: .normal)
            nextButton.accessibilityLabel = "Next page"
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
        
        // Animate out
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
            self.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.dismiss(animated: false) {
                // Navigate to main app
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let mainTabBar = MainTabBarController()
                    window.rootViewController = mainTabBar
                    
                    // Animate in
                    window.alpha = 0
                    UIView.animate(withDuration: 0.3) {
                        window.alpha = 1
                    }
                }
            }
        }
    }
}

// MARK: - UIPageViewControllerDataSource
extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index > 0 else { return nil }
        return pages[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }
}

// MARK: - UIPageViewControllerDelegate
extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let currentVC = pageViewController.viewControllers?.first,
           let index = pages.firstIndex(of: currentVC) {
            currentIndex = index
            pageControl.currentPage = index
            updateButtonTitle()
        }
    }
}

// MARK: - Onboarding Page View Controller
class OnboardingPageViewController: UIViewController {
    
    // MARK: - Properties
    private let titleText: String
    private let subtitleText: String
    private let imageName: String
    private let descriptionText: String
    
    // MARK: - UI Elements
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = CyberpunkTheme.primaryCyan
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .claudeCodeFont(style: .largeTitle, weight: .bold)
        label.textColor = CyberpunkTheme.text
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .claudeCodeFont(style: .title3, weight: .medium)
        label.textColor = CyberpunkTheme.primaryCyan
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .claudeCodeFont(style: .body)
        label.textColor = CyberpunkTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    init(title: String, subtitle: String, imageName: String, description: String) {
        self.titleText = title
        self.subtitleText = subtitle
        self.imageName = imageName
        self.descriptionText = description
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Create stack view
        let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, subtitleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        // Configure content
        if let image = UIImage(systemName: imageName) {
            imageView.image = image.withConfiguration(UIImage.SymbolConfiguration(pointSize: 80, weight: .light))
        }
        titleLabel.text = titleText
        subtitleLabel.text = subtitleText
        descriptionLabel.text = descriptionText
        
        // Add glow to image
        imageView.addCyberpunkGlow(intensity: 0.5, radius: 20)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Accessibility
        view.accessibilityLabel = "\(titleText). \(subtitleText). \(descriptionText)"
    }
    
    private func animateIn() {
        imageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        imageView.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.imageView.transform = .identity
            self.imageView.alpha = 1
        }
    }
}