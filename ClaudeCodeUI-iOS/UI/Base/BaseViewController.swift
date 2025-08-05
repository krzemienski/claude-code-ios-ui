//
//  BaseViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

// MARK: - Base View Controller
class BaseViewController: UIViewController {
    
    // MARK: - Properties
    lazy var gridBackgroundView = GridBackgroundView()
    
    var isLoading: Bool = false {
        didSet {
            updateLoadingState()
        }
    }
    
    private lazy var loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.isHidden = true
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = CyberpunkTheme.primaryCyan
        activityIndicator.startAnimating()
        
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add grid background
        view.insertSubview(gridBackgroundView, at: 0)
        
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
        UIView.animate(withDuration: 0.3) {
            self.loadingView.isHidden = !self.isLoading
            self.loadingView.alpha = self.isLoading ? 1.0 : 0.0
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
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// MARK: - Table View Controller Base
class BaseTableViewController: BaseViewController {
    
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
    override func viewDidLoad() {
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
    override func viewDidLoad() {
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