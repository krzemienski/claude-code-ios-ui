//
//  SessionListViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-13.
//  Updated for enhanced UI/UX polish
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
    
    // Enhanced empty state with proper NoDataView
    private lazy var emptyStateView: NoDataView = {
        let view = NoDataView(type: .noSessions) { [weak self] in
            self?.createNewSession()
        }
        return view
    }()
    
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
        view.addSubview(emptyStateView)
        
        // Setup constraints
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: sortSegmentedControl.superview!.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateEmptyStateVisibility() {
        // Use the isLoading property from BaseViewController
        let shouldShowEmpty = sessions.isEmpty && !isLoading
        
        if shouldShowEmpty {
            tableView.isHidden = true
            emptyStateView.isHidden = false
        } else {
            emptyStateView.isHidden = true
            tableView.isHidden = false
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
        // Use the improved skeleton extension from SkeletonView
        tableView.showSkeletonLoading(count: 6, cellHeight: 80)
    }
    
    private func hideSkeletonLoading() {
        tableView.hideSkeletonLoading()
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
                        
                        // Log successful refresh
                        print("✅ Sessions refreshed successfully: \(fetchedSessions.count) sessions loaded")
                        
                        // Haptic feedback on successful refresh
                        if self.refreshControl.isRefreshing {
                            let successFeedback = UINotificationFeedbackGenerator()
                            successFeedback.prepare()
                            successFeedback.notificationOccurred(.success)
                        }
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
                    
                    // Error haptic feedback if refreshing
                    if self.refreshControl.isRefreshing {
                        let errorFeedback = UINotificationFeedbackGenerator()
                        errorFeedback.prepare()
                        errorFeedback.notificationOccurred(.error)
                        
                        print("❌ Session refresh failed: \(error.localizedDescription)")
                    }
                    
                    self.refreshControl.endRefreshing()
                    
                    // Try to load from cache if network fails
                    if !append, let cachedSessions = self.persistenceService.getCachedSessions(for: self.project.name) {
                        self.sessions = cachedSessions
                        self.tableView.reloadData()
                        self.updateEmptyStateVisibility()
                        
                        // Show offline notice with warning severity
                        self.showErrorAlert(
                            severity: .warning,
                            title: "Offline Mode",
                            message: "Showing cached sessions. Pull down to retry when online.",
                            showRetry: false
                        )
                    } else {
                        // Show network error alert with retry option
                        self.showNetworkError(
                            message: "Unable to load sessions. Please check your connection.",
                            retryAction: { [weak self] in
                                self?.fetchSessions(append: append)
                            }
                        )
                        self.updateEmptyStateVisibility()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func refreshSessions() {
        // Add haptic feedback when refresh starts
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Log refresh action
        print("🔄 Pull-to-refresh triggered for sessions in project: \(project.name)")
        
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
                    
                    // Update empty state
                    self.updateEmptyStateVisibility()
                    
                    // Update table view with animation
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    
                    // Navigate to the new session
                    let chatVC = ChatViewController(project: self.project, session: newSession)
                    self.navigationController?.pushViewController(chatVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.hideLoading()
                    self.showErrorAlert(
                        severity: .error,
                        title: "Session Creation Failed",
                        message: error.localizedDescription,
                        showRetry: true,
                        retryAction: { [weak self] in
                            self?.createNewSession()
                        }
                    )
                }
            }
        }
    }
    
    @objc private func sortOptionChanged(_ sender: UISegmentedControl) {
        guard let sortOption = SortOption(rawValue: sender.selectedSegmentIndex) else { return }
        
        let sessionsToSort = isSearching ? filteredSessions : sessions
        
        switch sortOption {
        case .recent:
            sessions = sessionsToSort.sorted { $0.updatedAt > $1.updatedAt }
        case .messageCount:
            sessions = sessionsToSort.sorted { $0.messageCount > $1.messageCount }
        case .name:
            sessions = sessionsToSort.sorted { ($0.summary ?? "") < ($1.summary ?? "") }
        }
        
        if isSearching {
            filteredSessions = sessions
        }
        
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension SessionListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredSessions.count : sessions.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SessionCell", for: indexPath) as? SessionTableViewCell else {
            return UITableViewCell()
        }
        
        let session = isSearching ? filteredSessions[indexPath.row] : sessions[indexPath.row]
        cell.configure(with: session)
        
        // Check if we need to load more (pagination)
        let displayedSessions = isSearching ? filteredSessions : sessions
        if !isSearching && indexPath.row == displayedSessions.count - 3 && hasMoreSessions && !isLoadingMore {
            fetchSessions(append: true)
        }
        
        return cell
    }
    
    // Swipe actions for sessions
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let session = isSearching ? filteredSessions[indexPath.row] : sessions[indexPath.row]
        
        // Delete action with cyberpunk styling
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            self?.deleteSession(at: indexPath, session: session, completion: completion)
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = CyberpunkTheme.error
        
        // Archive action with cyberpunk styling
        let archiveAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            self?.archiveSession(at: indexPath, session: session, completion: completion)
        }
        archiveAction.image = UIImage(systemName: "archivebox")
        archiveAction.backgroundColor = CyberpunkTheme.warning
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, archiveAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    // Leading swipe actions
    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let session = isSearching ? filteredSessions[indexPath.row] : sessions[indexPath.row]
        
        // Duplicate action
        let duplicateAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            self?.duplicateSession(session, completion: completion)
        }
        duplicateAction.image = UIImage(systemName: "doc.on.doc")
        duplicateAction.backgroundColor = CyberpunkTheme.primaryCyan
        
        let configuration = UISwipeActionsConfiguration(actions: [duplicateAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

// MARK: - UITableViewDelegate
extension SessionListViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let session = isSearching ? filteredSessions[indexPath.row] : sessions[indexPath.row]
        let chatVC = ChatViewController(project: project, session: session)
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - UISearchResultsUpdating
extension SessionListViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredSessions = []
            tableView.reloadData()
            return
        }
        
        filteredSessions = sessions.filter { session in
            session.displaySummary.localizedCaseInsensitiveContains(searchText) ||
            (session.summary?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        tableView.reloadData()
    }
}

// MARK: - Session Actions
extension SessionListViewController {
    private func deleteSession(at indexPath: IndexPath, session: Session, completion: @escaping (Bool) -> Void) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        Task {
            do {
                try await apiClient.deleteSession(projectName: project.name, sessionId: session.id)
                
                await MainActor.run {
                    if self.isSearching {
                        self.filteredSessions.remove(at: indexPath.row)
                        if let originalIndex = self.sessions.firstIndex(where: { $0.id == session.id }) {
                            self.sessions.remove(at: originalIndex)
                        }
                    } else {
                        self.sessions.remove(at: indexPath.row)
                    }
                    
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.updateEmptyStateVisibility()
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.showErrorAlert(
                        severity: .error,
                        title: "Delete Failed",
                        message: error.localizedDescription
                    )
                    completion(false)
                }
            }
        }
    }
    
    private func archiveSession(at indexPath: IndexPath, session: Session, completion: @escaping (Bool) -> Void) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Archive implementation would go here
        print("Archiving session: \(session.displaySummary)")
        completion(true)
    }
    
    private func duplicateSession(_ session: Session, completion: @escaping (Bool) -> Void) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Duplicate implementation would go here
        print("Duplicating session: \(session.displaySummary)")
        completion(true)
    }
}