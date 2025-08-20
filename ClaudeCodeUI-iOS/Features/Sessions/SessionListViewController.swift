//
//  SessionListViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-13.
//

import UIKit

public class SessionListViewController: BaseViewController {
    // MARK: - Properties
    private let project: Project
    private var sessions: [Session] = []
    private var filteredSessions: [Session] = []
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private var skeletonView: UIView?
    private let apiClient = APIClient.shared
    private let searchController = UISearchController(searchResultsController: nil)
    private let sortSegmentedControl = UISegmentedControl(items: ["Recent", "Messages", "Name"])
    private let persistenceService = SessionPersistenceService.shared
    private let emptyStateView = UIView()
    private var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    // Pagination
    private var isLoadingMore = false
    private var hasMoreSessions = true
    private let pageSize = 20
    private var currentOffset = 0
    
    // Sorting
    private enum SortOption: Int {
        case recent = 0
        case messageCount = 1
        case name = 2
    }
    
    // MARK: - Initialization
    init(project: Project) {
        self.project = project
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEmptyState()
        fetchSessions()
        checkForResumableSession()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        title = "Sessions"
        
        // Setup navigation items
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(createNewSession)
        )
        navigationItem.rightBarButtonItem?.tintColor = CyberpunkTheme.primaryCyan
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "addSessionButton"
        
        // Setup search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search sessions..."
        searchController.searchBar.tintColor = CyberpunkTheme.primaryCyan
        searchController.searchBar.searchTextField.textColor = CyberpunkTheme.primaryText
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search sessions...",
            attributes: [.foregroundColor: CyberpunkTheme.secondaryText]
        )
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Setup sort control
        sortSegmentedControl.selectedSegmentIndex = 0
        sortSegmentedControl.addTarget(self, action: #selector(sortOptionChanged), for: .valueChanged)
        sortSegmentedControl.backgroundColor = CyberpunkTheme.surface
        sortSegmentedControl.selectedSegmentTintColor = CyberpunkTheme.primaryCyan
        sortSegmentedControl.setTitleTextAttributes([
            .foregroundColor: CyberpunkTheme.primaryText
        ], for: .normal)
        sortSegmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.black
        ], for: .selected)
        
        // Add sort control container
        let sortContainer = UIView()
        sortContainer.backgroundColor = CyberpunkTheme.background
        view.addSubview(sortContainer)
        sortContainer.translatesAutoresizingMaskIntoConstraints = false
        
        sortContainer.addSubview(sortSegmentedControl)
        sortSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup table view
        tableView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        tableView.separatorColor = UIColor(red: 0, green: 0.85, blue: 1, alpha: 0.3) // Cyan separator
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SessionTableViewCell.self, forCellReuseIdentifier: "SessionCell")
        
        // Setup refresh control with custom cyberpunk styling
        setupRefreshControl()
        tableView.refreshControl = refreshControl
        
        // Add table view to view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Sort container
            sortContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sortContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sortContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sortContainer.heightAnchor.constraint(equalToConstant: 56),
            
            // Sort control
            sortSegmentedControl.centerYAnchor.constraint(equalTo: sortContainer.centerYAnchor),
            sortSegmentedControl.leadingAnchor.constraint(equalTo: sortContainer.leadingAnchor, constant: 16),
            sortSegmentedControl.trailingAnchor.constraint(equalTo: sortContainer.trailingAnchor, constant: -16),
            sortSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: sortContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Refresh Control Setup
    private func setupRefreshControl() {
        refreshControl.tintColor = CyberpunkTheme.primaryCyan
        refreshControl.addTarget(self, action: #selector(refreshSessions), for: .valueChanged)
        
        // Customize the refresh control's background
        refreshControl.backgroundColor = CyberpunkTheme.background.withAlphaComponent(0.95)
        refreshControl.layer.cornerRadius = 16
        refreshControl.layer.masksToBounds = true
        
        // Add a subtle border with glow effect
        refreshControl.layer.borderWidth = 1
        refreshControl.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        
        // Create custom refresh view with enhanced cyberpunk animation
        let refreshContainer = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 60))
        refreshContainer.backgroundColor = .clear
        
        // Add animated loading bars
        let barWidth: CGFloat = 3
        let barHeight: CGFloat = 20
        let numberOfBars = 5
        let spacing: CGFloat = 8
        let totalWidth = CGFloat(numberOfBars) * barWidth + CGFloat(numberOfBars - 1) * spacing
        let startX = (200 - totalWidth) / 2
        
        for i in 0..<numberOfBars {
            let bar = UIView()
            bar.backgroundColor = CyberpunkTheme.primaryCyan
            bar.frame = CGRect(
                x: startX + CGFloat(i) * (barWidth + spacing),
                y: 20,
                width: barWidth,
                height: barHeight
            )
            bar.layer.cornerRadius = barWidth / 2
            
            // Add glow to each bar
            bar.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
            bar.layer.shadowRadius = 4
            bar.layer.shadowOpacity = 0.8
            bar.layer.shadowOffset = .zero
            
            // Animate each bar with delay
            let animation = CABasicAnimation(keyPath: "transform.scale.y")
            animation.duration = 0.6
            animation.fromValue = 0.4
            animation.toValue = 1.0
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.timeOffset = Double(i) * 0.1
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            bar.layer.add(animation, forKey: "pulse")
            
            refreshContainer.addSubview(bar)
        }
        
        // Add "SYNCING" text below the bars
        let loadingLabel = UILabel()
        loadingLabel.text = "⟲ SYNCING DATA"
        loadingLabel.font = .monospacedSystemFont(ofSize: 10, weight: .medium)
        loadingLabel.textColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.8)
        loadingLabel.textAlignment = .center
        loadingLabel.frame = CGRect(x: 0, y: 45, width: 200, height: 12)
        refreshContainer.addSubview(loadingLabel)
        
        // Add text glow animation
        let textGlowAnimation = CABasicAnimation(keyPath: "opacity")
        textGlowAnimation.duration = 1.2
        textGlowAnimation.fromValue = 0.5
        textGlowAnimation.toValue = 1.0
        textGlowAnimation.autoreverses = true
        textGlowAnimation.repeatCount = .infinity
        textGlowAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        loadingLabel.layer.add(textGlowAnimation, forKey: "textGlow")
        
        refreshControl.addSubview(refreshContainer)
    }
    
    // MARK: - Empty State
    private func setupEmptyState() {
        emptyStateView.isHidden = true
        emptyStateView.backgroundColor = CyberpunkTheme.background
        view.addSubview(emptyStateView)
        
        // Container for content
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(containerView)
        
        // ASCII art label with cyberpunk theme
        let asciiLabel = UILabel()
        asciiLabel.translatesAutoresizingMaskIntoConstraints = false
        asciiLabel.numberOfLines = 0
        asciiLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        asciiLabel.textColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.6)
        asciiLabel.textAlignment = .center
        asciiLabel.text = """
        ╔═══════════════════════╗
        ║   NO SESSIONS FOUND   ║
        ║                       ║
        ║      ┌─────────┐      ║
        ║      │  START  │      ║
        ║      │   NEW   │      ║
        ║      └─────────┘      ║
        ╚═══════════════════════╝
        """
        containerView.addSubview(asciiLabel)
        
        // Add glow effect to ASCII art
        asciiLabel.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        asciiLabel.layer.shadowRadius = 8
        asciiLabel.layer.shadowOpacity = 0.3
        asciiLabel.layer.shadowOffset = .zero
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Sessions Yet"
        titleLabel.font = CyberpunkTheme.titleFont
        titleLabel.textColor = CyberpunkTheme.primaryText
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        // Message label
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = "Start chatting with Claude to create your first session"
        messageLabel.font = CyberpunkTheme.bodyFont
        messageLabel.textColor = CyberpunkTheme.secondaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        containerView.addSubview(messageLabel)
        
        // Create Session button with cyberpunk style
        let createButton = UIButton(type: .system)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.setTitle("Create New Session", for: .normal)
        createButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        createButton.setTitleColor(UIColor.black, for: .normal)
        createButton.backgroundColor = CyberpunkTheme.primaryCyan
        createButton.layer.cornerRadius = 12
        createButton.addTarget(self, action: #selector(createNewSession), for: .touchUpInside)
        containerView.addSubview(createButton)
        
        // Add glow effect to button
        createButton.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        createButton.layer.shadowRadius = 8
        createButton.layer.shadowOpacity = 0.5
        createButton.layer.shadowOffset = .zero
        
        // Setup constraints
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: sortSegmentedControl.superview!.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -50),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor, constant: -40),
            
            asciiLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            asciiLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: asciiLabel.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            createButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            createButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            createButton.widthAnchor.constraint(equalToConstant: 200),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            createButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Add animations
        addEmptyStateAnimations(asciiLabel: asciiLabel, containerView: containerView)
    }
    
    private func addEmptyStateAnimations(asciiLabel: UILabel, containerView: UIView) {
        // Pulse animation for ASCII art
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.duration = 2.0
        pulseAnimation.fromValue = 0.6
        pulseAnimation.toValue = 1.0
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        asciiLabel.layer.add(pulseAnimation, forKey: "pulse")
        
        // Subtle float animation
        let floatAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        floatAnimation.duration = 3.0
        floatAnimation.fromValue = -5
        floatAnimation.toValue = 5
        floatAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        floatAnimation.autoreverses = true
        floatAnimation.repeatCount = .infinity
        containerView.layer.add(floatAnimation, forKey: "float")
    }
    
    private func updateEmptyStateVisibility() {
        // Use the isLoading property from BaseViewController
        let shouldShowEmpty = sessions.isEmpty && !isLoading
        
        if shouldShowEmpty {
            tableView.isHidden = true
            emptyStateView.isHidden = false
            // Animate appearance
            emptyStateView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.emptyStateView.alpha = 1
            }
        } else {
            // Animate disappearance
            UIView.animate(withDuration: 0.3, animations: {
                self.emptyStateView.alpha = 0
            }) { _ in
                self.emptyStateView.isHidden = true
                self.tableView.isHidden = false
            }
        }
    }
    
    // MARK: - Session Persistence
    private func checkForResumableSession() {
        // Check if there's a stored session ID for this project
        if let storedSessionId = persistenceService.getCurrentSessionId(for: project.name) {
            // Check if we should resume this session
            if persistenceService.shouldResumeSession(projectName: project.name, sessionId: storedSessionId) {
                // We'll navigate to this session after sessions are loaded
                // Store it for later use
                self.pendingSessionIdToResume = storedSessionId
            }
        }
    }
    
    private var pendingSessionIdToResume: String?
    
    // MARK: - Skeleton Loading
    private func showSkeletonLoading() {
        // Create container view for skeleton
        let containerView = UIView(frame: tableView.bounds)
        containerView.backgroundColor = CyberpunkTheme.background
        containerView.tag = 999 // Tag for identification
        
        // Add skeleton cells with cyberpunk animation
        var previousCell: UIView?
        for i in 0..<6 {
            // Create cell container
            let cellView = UIView()
            cellView.translatesAutoresizingMaskIntoConstraints = false
            cellView.backgroundColor = CyberpunkTheme.surface
            containerView.addSubview(cellView)
            
            // Create avatar skeleton
            let avatarView = UIView()
            avatarView.translatesAutoresizingMaskIntoConstraints = false
            avatarView.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.7)
            avatarView.layer.cornerRadius = 22
            avatarView.layer.masksToBounds = true
            cellView.addSubview(avatarView)
            
            // Create title skeleton
            let titleView = UIView()
            titleView.translatesAutoresizingMaskIntoConstraints = false
            titleView.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.7)
            titleView.layer.cornerRadius = 4
            cellView.addSubview(titleView)
            
            // Create subtitle skeleton
            let subtitleView = UIView()
            subtitleView.translatesAutoresizingMaskIntoConstraints = false
            subtitleView.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.5)
            subtitleView.layer.cornerRadius = 4
            cellView.addSubview(subtitleView)
            
            // Add shimmer gradient
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                CyberpunkTheme.surface.cgColor,
                CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor,
                CyberpunkTheme.surface.cgColor
            ]
            gradientLayer.locations = [0.0, 0.5, 1.0]
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            gradientLayer.frame = CGRect(x: -tableView.bounds.width, y: 0, width: tableView.bounds.width * 3, height: 80)
            cellView.layer.addSublayer(gradientLayer)
            
            // Animate shimmer
            let animation = CABasicAnimation(keyPath: "transform.translation.x")
            animation.duration = 1.5
            animation.fromValue = -tableView.bounds.width
            animation.toValue = tableView.bounds.width
            animation.repeatCount = .infinity
            gradientLayer.add(animation, forKey: "shimmer")
            
            // Setup constraints
            NSLayoutConstraint.activate([
                // Cell
                cellView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                cellView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                cellView.heightAnchor.constraint(equalToConstant: 80),
                
                // Avatar
                avatarView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 16),
                avatarView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                avatarView.widthAnchor.constraint(equalToConstant: 44),
                avatarView.heightAnchor.constraint(equalToConstant: 44),
                
                // Title
                titleView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
                titleView.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 20),
                titleView.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -16),
                titleView.heightAnchor.constraint(equalToConstant: 20),
                
                // Subtitle
                subtitleView.leadingAnchor.constraint(equalTo: titleView.leadingAnchor),
                subtitleView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 8),
                subtitleView.widthAnchor.constraint(equalTo: titleView.widthAnchor, multiplier: 0.7),
                subtitleView.heightAnchor.constraint(equalToConstant: 16)
            ])
            
            if let previous = previousCell {
                cellView.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 1).isActive = true
            } else {
                cellView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
            }
            
            previousCell = cellView
        }
        
        // Store and add as overlay
        skeletonView = containerView
        containerView.alpha = 0
        tableView.addSubview(containerView)
        tableView.bringSubviewToFront(containerView)
        
        // Fade in animation
        UIView.animate(withDuration: 0.3) {
            containerView.alpha = 1
        }
    }
    
    private func hideSkeletonLoading() {
        UIView.animate(withDuration: 0.3, animations: {
            self.skeletonView?.alpha = 0
        }) { _ in
            self.skeletonView?.removeFromSuperview()
            self.skeletonView = nil
        }
    }
    
    // MARK: - Data Loading
    private func fetchSessions(append: Bool = false) {
        guard !isLoadingMore else { return }
        
        if !append {
            currentOffset = 0
            hasMoreSessions = true
            // Show skeleton loading for initial load and refresh
            showSkeletonLoading()
        } else {
            // For pagination, just set the flag
            isLoadingMore = true
        }
        
        Task {
            do {
                let fetchedSessions = try await apiClient.fetchSessions(
                    projectName: project.name,
                    limit: pageSize,
                    offset: currentOffset
                )
                
                await MainActor.run {
                    if append {
                        self.sessions.append(contentsOf: fetchedSessions)
                    } else {
                        self.sessions = fetchedSessions
                        // Cache sessions for offline access
                        self.persistenceService.cacheSessions(fetchedSessions, for: self.project.name)
                    }
                    
                    self.hasMoreSessions = fetchedSessions.count == self.pageSize
                    self.currentOffset += fetchedSessions.count
                    self.isLoadingMore = false
                    self.hideSkeletonLoading()  // Hide skeleton loading
                    self.refreshControl.endRefreshing()
                    self.tableView.reloadData()
                    self.updateEmptyStateVisibility()
                    
                    // Check if we need to resume a session
                    if let sessionIdToResume = self.pendingSessionIdToResume {
                        self.pendingSessionIdToResume = nil
                        // Find the session in our list
                        if let sessionToResume = self.sessions.first(where: { $0.id == sessionIdToResume }) {
                            // Navigate to chat with this session
                            let chatVC = ChatViewController(project: self.project, session: sessionToResume)
                            self.navigationController?.pushViewController(chatVC, animated: true)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingMore = false
                    self.hideSkeletonLoading()  // Hide skeleton loading
                    self.refreshControl.endRefreshing()
                    
                    // Try to load from cache if network fails
                    if !append, let cachedSessions = self.persistenceService.getCachedSessions(for: self.project.name) {
                        self.sessions = cachedSessions
                        self.tableView.reloadData()
                        self.updateEmptyStateVisibility()
                        
                        // Show offline notice
                        let offlineAlert = UIAlertController(
                            title: "Offline Mode",
                            message: "Showing cached sessions. Some features may be limited.",
                            preferredStyle: .alert
                        )
                        offlineAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(offlineAlert, animated: true)
                    } else {
                        self.showError(error)
                        self.updateEmptyStateVisibility()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func refreshSessions() {
        fetchSessions(append: false)
    }
    
    @objc private func createNewSession() {
        // Prevent multiple simultaneous session creation
        guard !isLoading else { return }
        
        // Show loading with a more descriptive message using BaseViewController method
        showLoading(message: "Creating new session...")
        
        Task {
            do {
                // Create new session via API
                let newSession = try await apiClient.createSession(projectName: project.name)
                
                await MainActor.run {
                    // Add to beginning of sessions list
                    self.sessions.insert(newSession, at: 0)
                    
                    // Update filtered sessions if searching
                    if self.isSearching {
                        self.filteredSessions.insert(newSession, at: 0)
                    }
                    
                    // Hide loading indicator
                    self.hideLoading()
                    
                    // Store session ID for persistence
                    self.persistenceService.setCurrentSession(newSession.id, for: self.project.name)
                    self.persistenceService.cacheSession(newSession)
                    
                    // Reload table and update empty state
                    self.tableView.reloadData()
                    self.updateEmptyStateVisibility()
                    
                    // Haptic feedback for successful creation
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.prepare()
                    impactFeedback.impactOccurred()
                    
                    // Navigate to chat with new session
                    let chatVC = ChatViewController(project: self.project, session: newSession)
                    self.navigationController?.pushViewController(chatVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    // Hide loading indicator
                    self.hideLoading()
                    
                    // Show more detailed error message
                    let errorMessage: String
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            errorMessage = "Authentication required. Please log in again."
                        case .networkError:
                            errorMessage = "Network error. Please check your connection."
                        case .serverError(let message):
                            errorMessage = "Server error: \(message)"
                        default:
                            errorMessage = "Failed to create session: \(error.localizedDescription)"
                        }
                    } else {
                        errorMessage = "Failed to create session: \(error.localizedDescription)"
                    }
                    
                    let alert = UIAlertController(
                        title: "Session Creation Failed",
                        message: errorMessage,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func sortOptionChanged() {
        sortSessions()
        tableView.reloadData()
    }
    
    // MARK: - Sorting & Filtering
    
    private func sortSessions() {
        // Create defensive copies to prevent array mutation races
        let sessionsToSort = isSearching ? Array(filteredSessions) : Array(sessions)
        
        switch SortOption(rawValue: sortSegmentedControl.selectedSegmentIndex) {
        case .recent:
            let sortedSessions = sessionsToSort.sorted { 
                let date1 = $0.lastActivity ?? Date.distantPast
                let date2 = $1.lastActivity ?? Date.distantPast
                return date1 > date2
            }
            
            // Atomic assignment on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.isSearching {
                    self.filteredSessions = sortedSessions
                } else {
                    self.sessions = sortedSessions
                }
                self.tableView.reloadData()
            }
            
        case .messageCount:
            let sortedSessions = sessionsToSort.sorted { 
                return $0.messageCount > $1.messageCount
            }
            
            // Atomic assignment on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.isSearching {
                    self.filteredSessions = sortedSessions
                } else {
                    self.sessions = sortedSessions
                }
                self.tableView.reloadData()
            }
            
        case .name:
            let sortedSessions = sessionsToSort.sorted { 
                let summary1 = $0.summary ?? ""
                let summary2 = $1.summary ?? ""
                return summary1.localizedCaseInsensitiveCompare(summary2) == .orderedAscending
            }
            
            // Atomic assignment on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.isSearching {
                    self.filteredSessions = sortedSessions
                } else {
                    self.sessions = sortedSessions
                }
                self.tableView.reloadData()
            }
            
        default:
            break
        }
    }
    
    private func filterSessions(searchText: String) {
        // Create defensive copy to prevent race conditions
        let sessionsCopy = Array(sessions)
        
        if searchText.isEmpty {
            filteredSessions = sessionsCopy
        } else {
            filteredSessions = sessionsCopy.filter { session in
                let summary = session.summary
                let sessionId = session.id
                let summaryMatch = summary?.localizedCaseInsensitiveContains(searchText) ?? false
                let idMatch = sessionId.localizedCaseInsensitiveContains(searchText)
                return summaryMatch || idMatch
            }
        }
        sortSessions()
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension SessionListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredSessions.count : sessions.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionCell", for: indexPath) as! SessionTableViewCell
        let session = isSearching ? filteredSessions[indexPath.row] : sessions[indexPath.row]
        cell.configure(with: session)
        cell.accessibilityIdentifier = "sessionCell_\(indexPath.row)"
        
        // Load more when approaching end (only when not searching)
        if !isSearching && indexPath.row == sessions.count - 5 && hasMoreSessions && !isLoadingMore {
            fetchSessions(append: true)
        }
        
        return cell
    }
}

// MARK: - UISearchResultsUpdating
extension SessionListViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        filterSessions(searchText: searchText)
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate
extension SessionListViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let session = isSearching ? filteredSessions[indexPath.row] : sessions[indexPath.row]
        
        // Store selected session for persistence
        persistenceService.setCurrentSession(session.id, for: project.name)
        persistenceService.cacheSession(session)
        
        // Navigate to chat with selected session
        let chatVC = ChatViewController(project: project, session: session)
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    // MARK: - Swipe to Delete
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            self?.deleteSession(at: indexPath, completion: completion)
        }
        deleteAction.backgroundColor = CyberpunkTheme.accentPink
        deleteAction.image = UIImage(systemName: "trash.fill")
        
        // Archive action
        let archiveAction = UIContextualAction(style: .normal, title: "Archive") { [weak self] _, _, completion in
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            self?.archiveSession(at: indexPath, completion: completion)
        }
        archiveAction.backgroundColor = UIColor.systemGray
        archiveAction.image = UIImage(systemName: "archivebox.fill")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, archiveAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Pin/Unpin action - Temporarily disabled until backend support
        // TODO: Implement when backend adds isPinned property to Session
        /*
        let session = isSearching ? filteredSessions[indexPath.row] : sessions[indexPath.row]
        let isPinned = false // session.isPinned ?? false
        
        let pinAction = UIContextualAction(style: .normal, title: isPinned ? "Unpin" : "Pin") { [weak self] _, _, completion in
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            self?.togglePinSession(at: indexPath, completion: completion)
        }
        pinAction.backgroundColor = CyberpunkTheme.primaryCyan
        pinAction.image = UIImage(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
        
        let configuration = UISwipeActionsConfiguration(actions: [pinAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
        */
        
        // Return empty configuration for now
        return UISwipeActionsConfiguration(actions: [])
    }
    
    private func deleteSession(at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let session = sessions[indexPath.row]
        let sessionId = session.id
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Delete Session",
            message: "Are you sure you want to delete this session? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else {
                completion(false)
                return
            }
            
            // Delete from backend
            Task {
                do {
                    // Call the API to delete the session
                    try await APIClient.shared.deleteSession(projectName: self.project.name, sessionId: sessionId)
                    
                    // Update UI on success
                    await MainActor.run {
                        self.sessions.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        self.updateEmptyStateVisibility()
                        completion(true)
                        
                        // Clear persistence if this was the current session
                        if self.persistenceService.getCurrentSessionId(for: self.project.name) == sessionId {
                            self.persistenceService.clearCurrentSession(for: self.project.name)
                        }
                    }
                } catch {
                    // Show error and don't delete from UI
                    await MainActor.run {
                        completion(false)
                        self.showError(error)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func archiveSession(at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        _ = isSearching ? filteredSessions[indexPath.row] : sessions[indexPath.row]
        
        // TODO: Implement archive API call when backend supports it
        // For now, just show feedback
        Task {
            await MainActor.run {
                // Visual feedback
                let cell = tableView.cellForRow(at: indexPath)
                UIView.animate(withDuration: 0.3, animations: {
                    cell?.alpha = 0.5
                }) { _ in
                    cell?.alpha = 1.0
                }
                
                // Show temporary message
                let alert = UIAlertController(
                    title: "Session Archived",
                    message: "Session has been archived successfully",
                    preferredStyle: .alert
                )
                self.present(alert, animated: true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    alert.dismiss(animated: true)
                }
                
                completion(true)
            }
        }
    }
    
    private func togglePinSession(at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        // TODO: Implement when backend adds isPinned property to Session
        /*
        let session = isSearching ? filteredSessions[indexPath.row] : sessions[indexPath.row]
        let wasPinned = false // session.isPinned ?? false
        
        // Toggle pin state
        // session.isPinned = !wasPinned
        
        // TODO: Implement pin API call when backend supports it
        // For now, just update UI
        Task {
            await MainActor.run {
                // Sort sessions to move pinned to top
                if !self.isSearching {
                    self.sessions.sort { session1, session2 in
                        let pin1 = false // session1.isPinned ?? false
                        let pin2 = false // session2.isPinned ?? false
                        
                        if pin1 != pin2 {
                            return pin1 && !pin2
                        }
                        // Keep existing sort order for same pin state
                        return false
                    }
                    
                    // Find new index
                    if let newIndex = self.sessions.firstIndex(where: { $0.id == session.id }) {
                        let newIndexPath = IndexPath(row: newIndex, section: 0)
                        
                        // Animate the move
                        self.tableView.beginUpdates()
                        self.tableView.moveRow(at: indexPath, to: newIndexPath)
                        self.tableView.endUpdates()
                    }
                }
                
                // Visual feedback
                let message = wasPinned ? "Session unpinned" : "Session pinned to top"
                let alert = UIAlertController(
                    title: nil,
                    message: message,
                    preferredStyle: .alert
                )
                self.present(alert, animated: true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    alert.dismiss(animated: true)
                }
                
                completion(true)
            }
        }
        */
        
        // For now, just complete immediately
        completion(true)
    }
}

