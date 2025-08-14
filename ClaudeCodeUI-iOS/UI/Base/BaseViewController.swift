//
//  BaseViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit
import SwiftUI

// MARK: - Full Screen Loading View
struct FullScreenLoadingView: View {
    let message: String?
    @State private var isAnimating = false
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Loading animation
                ZStack {
                    // Rotating rings
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0/255, green: 217/255, blue: 255/255).opacity(0.3 + Double(index) * 0.2),
                                        Color(red: 255/255, green: 0/255, blue: 110/255).opacity(0.3 + Double(index) * 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 60 + CGFloat(index * 20), 
                                   height: 60 + CGFloat(index * 20))
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 3 + Double(index))
                                    .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                    
                    // Center icon
                    Image(systemName: "cpu")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(
                            Animation.easeInOut(duration: 1)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                if let message = message {
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0/255, green: 217/255, blue: 255/255).opacity(0.5),
                                        Color(red: 255/255, green: 0/255, blue: 110/255).opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Base View Controller
public class BaseViewController: UIViewController {
    
    // MARK: - Properties
    lazy var gridBackgroundView = GridBackgroundView()
    
    // SwiftUI Loading View integration
    private var loadingHostingController: UIHostingController<AnyView>?
    private var currentLoadingMessage: String?
    
    // Loading state management with minimum display time
    private var loadingStartTime: Date?
    private var pendingHideTimer: Timer?
    private let minimumLoadingDisplayTime: TimeInterval = 1.0 // 1 second minimum
    
    public var isLoading: Bool = false {
        didSet {
            updateLoadingState()
        }
    }
    
    private lazy var loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
    }
    
    deinit {
        // Clean up timer when view controller is deallocated
        pendingHideTimer?.invalidate()
        pendingHideTimer = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add grid background
        view.insertSubview(gridBackgroundView, at: 0)
        gridBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add loading view
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Grid background
            gridBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            gridBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading view
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        // Configure navigation bar appearance
        navigationController?.navigationBar.tintColor = CyberpunkTheme.primaryCyan
        navigationController?.navigationBar.barTintColor = CyberpunkTheme.background
        navigationController?.navigationBar.isTranslucent = true
        
        // Configure title attributes
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: CyberpunkTheme.textPrimary,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]
        
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: CyberpunkTheme.textPrimary,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
    }
    
    // MARK: - Loading State
    private func updateLoadingState() {
        if isLoading {
            showLoadingWithMessage(currentLoadingMessage)
        } else {
            hideLoading()
        }
    }
    
    // MARK: - Public Loading Methods
    public func showLoading(message: String? = nil) {
        print("🔵 DEBUG: showLoading called with message: \(message ?? "nil")")
        print("🔵 DEBUG: Current thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Cancel any pending hide timer
        pendingHideTimer?.invalidate()
        pendingHideTimer = nil
        
        // Record when loading started
        loadingStartTime = Date()
        
        currentLoadingMessage = message
        isLoading = true
        showLoadingWithMessage(message)
    }
    
    public func hideLoading() {
        print("🔴 DEBUG: hideLoading called")
        print("🔴 DEBUG: Current thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Calculate how long the loading has been displayed
        guard let startTime = loadingStartTime else {
            // If no start time, just hide immediately
            isLoading = false
            hideLoadingView()
            return
        }
        
        let displayedDuration = Date().timeIntervalSince(startTime)
        let remainingTime = minimumLoadingDisplayTime - displayedDuration
        
        print("⏱️ DEBUG: Loading displayed for \(displayedDuration)s, minimum is \(minimumLoadingDisplayTime)s")
        
        if remainingTime > 0 {
            // Need to wait before hiding
            print("⏳ DEBUG: Waiting \(remainingTime)s before hiding loading indicator")
            
            // Schedule hide after remaining time
            pendingHideTimer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
                print("⏰ DEBUG: Timer fired, hiding loading indicator now")
                self?.isLoading = false
                self?.hideLoadingView()
                self?.loadingStartTime = nil
                self?.pendingHideTimer = nil
            }
        } else {
            // Has been displayed long enough, hide immediately
            print("✅ DEBUG: Loading displayed long enough, hiding immediately")
            isLoading = false
            hideLoadingView()
            loadingStartTime = nil
        }
    }
    
    // MARK: - Private Loading Methods
    private func showLoadingWithMessage(_ message: String?) {
        print("🟢 DEBUG: showLoadingWithMessage called")
        print("🟢 DEBUG: loadingView.isHidden = \(loadingView.isHidden)")
        print("🟢 DEBUG: loadingView.alpha = \(loadingView.alpha)")
        print("🟢 DEBUG: loadingView.superview = \(loadingView.superview != nil ? "exists" : "nil")")
        
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showLoadingWithMessage(message)
            }
            return
        }
        
        // Remove existing hosting controller if any
        loadingHostingController?.view.removeFromSuperview()
        loadingHostingController?.removeFromParent()
        
        // Create new SwiftUI loading view
        let loadingSwiftUIView = FullScreenLoadingView(message: message)
        let hostingController = UIHostingController(rootView: AnyView(loadingSwiftUIView))
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Add as child view controller
        addChild(hostingController)
        loadingView.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: loadingView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        loadingHostingController = hostingController
        
        // CRITICAL: Bring loading view to front
        view.bringSubviewToFront(loadingView)
        
        print("🟡 DEBUG: About to show loading view")
        print("🟡 DEBUG: loadingView.frame = \(loadingView.frame)")
        print("🟡 DEBUG: hostingController.view.frame = \(hostingController.view.frame)")
        
        // Animate appearance with haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        loadingView.alpha = 0
        loadingView.isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.loadingView.alpha = 1.0
        }) { completed in
            print("✅ DEBUG: Loading animation completed = \(completed)")
            print("✅ DEBUG: Final loadingView.isHidden = \(self.loadingView.isHidden)")
            print("✅ DEBUG: Final loadingView.alpha = \(self.loadingView.alpha)")
        }
    }
    
    private func hideLoadingView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.loadingView.alpha = 0.0
        }) { _ in
            self.loadingView.isHidden = true
            
            // Clean up hosting controller
            self.loadingHostingController?.view.removeFromSuperview()
            self.loadingHostingController?.removeFromParent()
            self.loadingHostingController = nil
            self.currentLoadingMessage = nil
        }
    }
    
    // MARK: - Error Handling
    func showError(_ error: Error, retryAction: (() -> Void)? = nil) {
        ErrorHandlingService.shared.handle(error, context: String(describing: type(of: self)), retryAction: retryAction)
    }
    
    // MARK: - Navigation Helpers
    func showViewController(_ viewController: UIViewController, animated: Bool = true) {
        navigationController?.pushViewController(viewController, animated: animated)
    }
    
    func showViewControllerModally(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: animated, completion: completion)
    }
    
    // MARK: - Keyboard Handling
    func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        // Override in subclasses
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        // Override in subclasses
    }
    
    // MARK: - Status Bar
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// MARK: - Table View Controller Base
public class BaseTableViewController: BaseViewController {
    
    // MARK: - Properties
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorColor = CyberpunkTheme.surfaceSecondary
        tableView.indicatorStyle = .white
        tableView.keyboardDismissMode = .interactive
        return tableView
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = CyberpunkTheme.primaryCyan
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return refreshControl
    }()
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    // MARK: - Setup
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.refreshControl = refreshControl
    }
    
    // MARK: - Actions
    @objc func refreshData() {
        // Override in subclasses
        refreshControl.endRefreshing()
    }
}

// MARK: - Collection View Controller Base
class BaseCollectionViewController: BaseViewController {
    
    // MARK: - Properties
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.indicatorStyle = .white
        collectionView.keyboardDismissMode = .interactive
        return collectionView
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = CyberpunkTheme.primaryCyan
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return refreshControl
    }()
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    // MARK: - Setup
    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        collectionView.refreshControl = refreshControl
    }
    
    // MARK: - Actions
    @objc func refreshData() {
        // Override in subclasses
        refreshControl.endRefreshing()
    }
}