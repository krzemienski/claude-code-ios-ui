//
//  SessionListViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-13.
//

import UIKit

public class SessionListViewController: UIViewController {
    // MARK: - Properties
    private let project: Project
    private var sessions: [Session] = []
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private let apiClient = APIClient.shared
    
    // Pagination
    private var isLoadingMore = false
    private var hasMoreSessions = true
    private let pageSize = 20
    private var currentOffset = 0
    
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
        fetchSessions()
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
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Data Loading
    private func fetchSessions(append: Bool = false) {
        guard !isLoadingMore else { return }
        
        if !append {
            currentOffset = 0
            hasMoreSessions = true
        }
        
        isLoadingMore = true
        
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
                    }
                    
                    self.hasMoreSessions = fetchedSessions.count == self.pageSize
                    self.currentOffset += fetchedSessions.count
                    self.isLoadingMore = false
                    self.refreshControl.endRefreshing()
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.isLoadingMore = false
                    self.refreshControl.endRefreshing()
                    self.showError(error)
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func refreshSessions() {
        fetchSessions(append: false)
    }
    
    @objc private func createNewSession() {
        // Navigate to chat with new session
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = scene.delegate as? SceneDelegate,
           let appCoordinator = sceneDelegate.appCoordinator {
            // TODO: Implement showChat in AppCoordinator
            // For now, navigate to ChatViewController directly
            let chatVC = ChatViewController(project: project)
            let navController = UINavigationController(rootViewController: chatVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
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
        return sessions.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionCell", for: indexPath) as! SessionTableViewCell
        let session = sessions[indexPath.row]
        cell.configure(with: session)
        
        // Load more when approaching end
        if indexPath.row == sessions.count - 5 && hasMoreSessions && !isLoadingMore {
            fetchSessions(append: true)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SessionListViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let session = sessions[indexPath.row]
        
        // Navigate to chat with selected session
        // Navigate to chat with selected session
        // TODO: Pass session to ChatViewController
        let chatVC = ChatViewController(project: project)
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
                    // TODO: Add deleteSession method to APIClient
                    // For now, just remove from local array
                    await MainActor.run {
                        self.sessions.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        completion(true)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
}