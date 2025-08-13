//
//  SessionsViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

class SessionsViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let project: Project
    private var sessions: [Session] = []
    private let apiClient: APIClient
    private var isLoading = false
    private let refreshControl = UIRefreshControl()
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SessionTableViewCell.self, forCellReuseIdentifier: SessionTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        return tableView
    }()
    
    private lazy var createSessionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start New Session", for: .normal)
        button.titleLabel?.font = CyberpunkTheme.headingFont
        button.setTitleColor(CyberpunkTheme.background, for: .normal)
        button.backgroundColor = CyberpunkTheme.primaryCyan
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(createNewSession), for: .touchUpInside)
        
        // Add glow effect
        button.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.shadowRadius = 10
        button.layer.shadowOpacity = 0.5
        
        return button
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = CyberpunkTheme.secondaryText
        
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .thin)
        imageView.image = UIImage(systemName: "bubble.left.and.bubble.right", withConfiguration: config)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Sessions Yet"
        titleLabel.font = CyberpunkTheme.headingFont
        titleLabel.textColor = CyberpunkTheme.primaryText
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Start a new session to begin working with Claude"
        subtitleLabel.font = CyberpunkTheme.bodyFont
        subtitleLabel.textColor = CyberpunkTheme.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }()
    
    // MARK: - Initialization
    
    init(project: Project) {
        self.project = project
        self.apiClient = DIContainer.shared.apiClient
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadSessions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshSessions()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Setup refresh control
        refreshControl.tintColor = CyberpunkTheme.primaryCyan
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        view.addSubview(tableView)
        view.addSubview(createSessionButton)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: createSessionButton.topAnchor, constant: -16),
            
            createSessionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            createSessionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createSessionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createSessionButton.heightAnchor.constraint(equalToConstant: 56),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func setupNavigationBar() {
        title = "\(project.displayName ?? project.name) Sessions"
        navigationItem.largeTitleDisplayMode = .never
    }
    
    // MARK: - Data Loading
    
    private func loadSessions() {
        guard !isLoading else { return }
        isLoading = true
        
        print("📱 Loading sessions for project: \(project.id)")
        
        Task {
            do {
                let sessions = try await apiClient.fetchSessions(projectId: project.id, limit: 50, offset: 0)
                print("✅ Successfully fetched \(sessions.count) sessions from API")
                
                await MainActor.run {
                    self.sessions = sessions
                    self.updateUI()
                    self.isLoading = false
                }
            } catch {
                print("❌ Failed to fetch sessions: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    self.showError("Failed to load sessions: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func refreshSessions() {
        guard !isLoading else { return }
        
        Task {
            do {
                let sessions = try await apiClient.fetchSessions(projectId: project.id, limit: 50, offset: 0)
                
                await MainActor.run {
                    self.sessions = sessions
                    self.updateUI()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                await MainActor.run {
                    self.refreshControl.endRefreshing()
                    Logger.shared.error("Failed to refresh sessions: \(error)")
                }
            }
        }
    }
    
    private func updateUI() {
        emptyStateView.isHidden = !sessions.isEmpty
        tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func handleRefresh() {
        refreshSessions()
    }
    
    @objc private func createNewSession() {
        Task {
            do {
                // Create new session via API
                let endpoint = APIEndpoint.createSession(projectId: project.id)
                let response: [String: Any] = try await apiClient.request(endpoint)
                
                if let sessionId = response["id"] as? String {
                    print("✅ Created new session: \(sessionId)")
                    
                    await MainActor.run {
                        // Navigate to chat with new session
                        let chatVC = ChatViewController(project: project)
                        // Store the new session ID
                        UserDefaults.standard.set(sessionId, forKey: "currentSessionId_\(project.id)")
                        navigationController?.pushViewController(chatVC, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.showError("Failed to create session: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func openSession(_ session: Session) {
        print("📂 Opening session: \(session.id)")
        
        // Store session ID for chat to use
        UserDefaults.standard.set(session.id, forKey: "currentSessionId_\(project.id)")
        
        // Navigate to chat
        let chatVC = ChatViewController(project: project)
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    private func deleteSession(_ session: Session) {
        let alert = UIAlertController(
            title: "Delete Session?",
            message: "Are you sure you want to delete this session? All messages will be permanently deleted.",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                do {
                    try await self.apiClient.requestVoid(.deleteSession(projectId: self.project.id, sessionId: session.id))
                    
                    await MainActor.run {
                        // Remove from local array
                        if let index = self.sessions.firstIndex(where: { $0.id == session.id }) {
                            self.sessions.remove(at: index)
                            self.updateUI()
                            
                            // Show success feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.showError("Failed to delete session: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SessionsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SessionTableViewCell.identifier, for: indexPath) as! SessionTableViewCell
        let session = sessions[indexPath.row]
        cell.configure(with: session)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SessionsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let session = sessions[indexPath.row]
        openSession(session)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let session = sessions[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteSession(session)
            completion(true)
        }
        deleteAction.backgroundColor = CyberpunkTheme.accentPink
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - Session Table View Cell

class SessionTableViewCell: UITableViewCell {
    static let identifier = "SessionTableViewCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = CyberpunkTheme.surface
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = CyberpunkTheme.border.cgColor
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CyberpunkTheme.captionFont
        label.textColor = CyberpunkTheme.secondaryText
        return label
    }()
    
    private let messageCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CyberpunkTheme.bodyFont
        label.textColor = CyberpunkTheme.primaryText
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = CyberpunkTheme.captionFont
        label.textColor = CyberpunkTheme.primaryCyan
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = CyberpunkTheme.secondaryText
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(dateLabel)
        containerView.addSubview(messageCountLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            dateLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            
            messageCountLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            messageCountLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageCountLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            
            statusLabel.topAnchor.constraint(equalTo: messageCountLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            statusLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    func configure(with session: Session) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: session.lastActiveAt)
        
        messageCountLabel.text = "\(session.messageCount) messages"
        
        switch session.status {
        case .active:
            statusLabel.text = "Active"
            statusLabel.textColor = CyberpunkTheme.primaryCyan
        case .completed:
            statusLabel.text = "Completed"
            statusLabel.textColor = CyberpunkTheme.secondaryText
        case .aborted:
            statusLabel.text = "Aborted"
            statusLabel.textColor = CyberpunkTheme.accentPink
        }
    }
}