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
        
        // Setup refresh control
        refreshControl.tintColor = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1.0) // Cyan
        refreshControl.addTarget(self, action: #selector(refreshSessions), for: .valueChanged)
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
    
    // MARK: - Empty State
    private func setupEmptyState() {
        emptyStateView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        emptyStateView.isHidden = true
        
        // Container for empty state content
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(containerView)
        
        // Icon
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "bubble.left.and.bubble.right")
        iconImageView.tintColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.5)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "No Sessions Yet"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = CyberpunkTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Start a new session to begin chatting"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = CyberpunkTheme.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create Session Button
        let createButton = UIButton(type: .system)
        createButton.setTitle("Create New Session", for: .normal)
        createButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        createButton.setTitleColor(UIColor.black, for: .normal)
        createButton.backgroundColor = CyberpunkTheme.primaryCyan
        createButton.layer.cornerRadius = 12
        createButton.addTarget(self, action: #selector(createNewSession), for: .touchUpInside)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add glow effect to button
        createButton.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        createButton.layer.shadowRadius = 8
        createButton.layer.shadowOpacity = 0.5
        createButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        // Add subviews
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(createButton)
        
        // Add empty state to view
        view.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Empty state view
            emptyStateView.topAnchor.constraint(equalTo: sortSegmentedControl.superview!.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container
            containerView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -50),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor, constant: -40),
            
            // Icon
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Button
            createButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            createButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            createButton.widthAnchor.constraint(equalToConstant: 200),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            createButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func updateEmptyStateVisibility() {
        let shouldShowEmpty = sessions.isEmpty && !isLoading
        emptyStateView.isHidden = !shouldShowEmpty
        tableView.isHidden = shouldShowEmpty
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
    
    // MARK: - Data Loading
    private func fetchSessions(append: Bool = false) {
        guard !isLoadingMore else { return }
        
        if !append {
            currentOffset = 0
            hasMoreSessions = true
        }
        
        isLoading = true  // Fixed: Use isLoading to show the loading overlay
        
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
                    self.isLoading = false  // Fixed: Use isLoading
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
                    self.isLoading = false  // Fixed: Use isLoading
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
        
        // Show loading with a more descriptive message
        isLoading = true
        showLoadingOverlay(message: "Creating new session...")
        
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
                    
                    self.isLoading = false
                    self.hideLoadingOverlay()
                    
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
                    self.isLoading = false
                    self.hideLoadingOverlay()
                    
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
    
    // MARK: - Loading Overlay
    
    private func showLoadingOverlay(message: String = "Loading...") {
        // Create loading overlay if needed
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.tag = 999 // Tag for easy removal
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        overlayView.addSubview(activityIndicator)
        overlayView.addSubview(label)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor, constant: -20),
            label.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            label.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 10)
        ])
        
        view.addSubview(overlayView)
    }
    
    private func hideLoadingOverlay() {
        // Remove loading overlay
        view.subviews.first { $0.tag == 999 }?.removeFromSuperview()
    }
    
    // MARK: - Sorting & Filtering
    
    private func sortSessions() {
        let sessionsToSort = isSearching ? filteredSessions : sessions
        
        switch SortOption(rawValue: sortSegmentedControl.selectedSegmentIndex) {
        case .recent:
            if isSearching {
                filteredSessions = sessionsToSort.sorted { 
                    let date1 = $0.lastActivity ?? Date.distantPast
                    let date2 = $1.lastActivity ?? Date.distantPast
                    return date1 > date2
                }
            } else {
                sessions = sessionsToSort.sorted { 
                    let date1 = $0.lastActivity ?? Date.distantPast
                    let date2 = $1.lastActivity ?? Date.distantPast
                    return date1 > date2
                }
            }
        case .messageCount:
            if isSearching {
                filteredSessions = sessionsToSort.sorted { 
                    return $0.messageCount > $1.messageCount
                }
            } else {
                sessions = sessionsToSort.sorted { 
                    return $0.messageCount > $1.messageCount
                }
            }
        case .name:
            if isSearching {
                filteredSessions = sessionsToSort.sorted { 
                    let summary1 = $0.summary ?? ""
                    let summary2 = $1.summary ?? ""
                    return summary1.localizedCaseInsensitiveCompare(summary2) == .orderedAscending
                }
            } else {
                sessions = sessionsToSort.sorted { 
                    let summary1 = $0.summary ?? ""
                    let summary2 = $1.summary ?? ""
                    return summary1.localizedCaseInsensitiveCompare(summary2) == .orderedAscending
                }
            }
        default:
            break
        }
    }
    
    private func filterSessions(searchText: String) {
        if searchText.isEmpty {
            filteredSessions = sessions
        } else {
            filteredSessions = sessions.filter { session in
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
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteSession(at: indexPath, completion: completion)
        }
        deleteAction.backgroundColor = UIColor(red: 1, green: 0, blue: 0.43, alpha: 1.0) // Pink
        deleteAction.image = UIImage(systemName: "trash")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
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
}