//
//  ProjectsViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

public class ProjectsViewController: BaseViewController {
    
    // MARK: - UI Components
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ProjectCollectionViewCell.self, forCellWithReuseIdentifier: ProjectCollectionViewCell.identifier)
        collectionView.register(AddProjectCollectionViewCell.self, forCellWithReuseIdentifier: AddProjectCollectionViewCell.identifier)
        collectionView.register(SkeletonCollectionViewCell.self, forCellWithReuseIdentifier: SkeletonCollectionViewCell.identifier)
        return collectionView
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
        imageView.image = UIImage(systemName: "folder.badge.plus", withConfiguration: config)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Projects Yet"
        titleLabel.font = CyberpunkTheme.headingFont
        titleLabel.textColor = CyberpunkTheme.primaryText
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Create your first project to get started"
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
    
    // MARK: - Properties
    
    private var projects: [Project] = []
    private let dataContainer: SwiftDataContainer?
    private let errorHandler: ErrorHandlingService
    private let refreshControl = UIRefreshControl()
    
    // Track if initial load has been performed
    private var hasPerformedInitialLoad = false
    
    // Track if we're showing skeleton loading
    private var isShowingSkeletons = false
    
    // Callback for project selection
    public var onProjectSelected: ((Project) -> Void)?
    
    // MARK: - Initialization
    
    init(dataContainer: SwiftDataContainer? = try? SwiftDataContainer(),
         errorHandler: ErrorHandlingService = DIContainer.shared.errorHandler) {
        self.dataContainer = dataContainer
        self.errorHandler = errorHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        performInitialLoad()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Only refresh if we've already done initial load and not currently loading
        if hasPerformedInitialLoad && !isLoading {
            refreshProjectsIfNeeded()
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Setup refresh control
        refreshControl.tintColor = CyberpunkTheme.primaryCyan
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        // Add long press gesture for deletion
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        collectionView.addGestureRecognizer(longPressGesture)
        
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func setupNavigationBar() {
        title = "Projects"
        
        // Style navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = CyberpunkTheme.background
        appearance.titleTextAttributes = [
            .foregroundColor: CyberpunkTheme.primaryText,
            .font: CyberpunkTheme.headingFont
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: CyberpunkTheme.primaryText,
            .font: CyberpunkTheme.titleFont
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Add settings button
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        settingsButton.tintColor = CyberpunkTheme.primaryCyan
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .estimated(200)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    // MARK: - Data Loading
    
    private func performInitialLoad() {
        print("🚨🚨🚨 CRITICAL: performInitialLoad() ENTERED!")
        guard !hasPerformedInitialLoad else { 
            print("⚠️ DEBUG: performInitialLoad() skipped - already performed")
            return 
        }
        
        print("🚀 DEBUG: performInitialLoad() called on thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Mark that we're performing initial load
        hasPerformedInitialLoad = true
        
        // Show skeleton loading instead of regular loading indicator
        DispatchQueue.main.async { [weak self] in
            self?.showSkeletonLoading()
        }
        
        print("📱 Starting initial project load...")
        print("🚀 DEBUG: isLoading = \(isLoading)")
        
        Task { @MainActor in
            do {
                // Use the shared APIClient instance which already has auth configured
                print("🔧 Using backend URL: \(AppConfig.backendURL)")
                print("📱 Attempting to fetch projects from API...")
                print("🔑 Auth token present: \(UserDefaults.standard.string(forKey: "authToken") != nil)")
                
                // Add a minimum delay to see the skeleton animation
                let startTime = Date()
                
                // The shared APIClient already has the development token configured
                let remoteProjects = try await APIClient.shared.fetchProjects()
                print("✅ Successfully fetched \(remoteProjects.count) projects from API")
                
                // Ensure skeleton shows for at least 0.5 seconds for smooth transition
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed < 0.5 {
                    try await Task.sleep(nanoseconds: UInt64((0.5 - elapsed) * 1_000_000_000))
                }
                
                // Already on main thread due to @MainActor
                self.projects = remoteProjects
                self.hideSkeletonLoading()
                self.updateUI()
                print("🎨 UI updated with \(self.projects.count) projects")
                
                // Log success message
                if !remoteProjects.isEmpty {
                    print("✅ Successfully loaded \(remoteProjects.count) projects in UI")
                } else {
                    print("ℹ️ No projects found - showing empty state")
                }
            } catch {
                print("❌ Failed to fetch from API: \(error)")
                print("❌ Error details: \(String(describing: error))")
                print("❌ Error type: \(type(of: error))")
                
                // Print more detailed error information
                if let apiError = error as? APIError {
                    print("❌ API Error: \(apiError.errorDescription ?? "Unknown")")
                    if case .httpError(let statusCode, let data) = apiError {
                        print("❌ HTTP Status: \(statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("❌ Response: \(responseString)")
                        }
                    }
                }
                
                // Hide skeleton loading on error
                self.hideSkeletonLoading()
                
                // Fall back to local data if available
                if let dataContainer = dataContainer {
                    do {
                        let localProjects = try await dataContainer.fetchProjects()
                        print("📦 Loaded \(localProjects.count) projects from local storage")
                        // Already on main thread
                        self.projects = localProjects
                        self.updateUI()
                    } catch localError {
                        print("❌ Failed to load from local storage: \(localError)")
                        self.showError("Failed to load projects: \(error.localizedDescription)")
                    }
                } else {
                    self.showError("Failed to load projects: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func refreshProjectsIfNeeded() {
        guard !isLoading else { 
            print("⚠️ DEBUG: refreshProjectsIfNeeded() skipped - already loading")
            return 
        }
        
        print("🔄 DEBUG: refreshProjectsIfNeeded() called")
        // Don't show loading indicator for background refresh
        refreshProjectsInBackground()
    }
    
    private func refreshProjects() {
        guard !isLoading && !isShowingSkeletons else { 
            print("⚠️ DEBUG: refreshProjects() skipped - already loading")
            refreshControl.endRefreshing()
            return 
        }
        
        print("🔄 DEBUG: refreshProjects() called - manual refresh")
        
        // Don't show skeleton for pull-to-refresh, just use the refresh control indicator
        
        Task { @MainActor in
            do {
                print("🔧 Refreshing projects from backend...")
                
                // Fetch from API using the shared instance
                let remoteProjects = try await APIClient.shared.fetchProjects()
                print("✅ Refresh successful: \(remoteProjects.count) projects")
                
                // Already on main thread
                self.projects = remoteProjects
                self.updateUI()
                self.refreshControl.endRefreshing()
                
                // Update local cache in background
                if let dataContainer = dataContainer {
                    Task.detached {
                        for project in remoteProjects {
                            try? await dataContainer.saveProject(project)
                        }
                    }
                }
            } catch {
                print("⚠️ Refresh failed: \(error)")
                self.refreshControl.endRefreshing()
                // Don't show error on refresh, just keep existing data
                Logger.shared.error("Failed to refresh projects: \(error)")
            }
        }
    }
    
    private func refreshProjectsInBackground() {
        Task { @MainActor in
            do {
                print("🔄 Background refresh starting...")
                let remoteProjects = try await APIClient.shared.fetchProjects()
                print("✅ Background refresh successful: \(remoteProjects.count) projects")
                
                self.projects = remoteProjects
                self.updateUI()
                
                // Update local cache
                if let dataContainer = dataContainer {
                    Task.detached {
                        for project in remoteProjects {
                            try? await dataContainer.saveProject(project)
                        }
                    }
                }
            } catch {
                print("⚠️ Background refresh failed: \(error)")
                // Silent failure for background refresh
            }
        }
    }
    
    private func updateUI() {
        emptyStateView.isHidden = !projects.isEmpty
        collectionView.reloadData()
    }
    
    // MARK: - Skeleton Loading
    
    private func showSkeletonLoading() {
        print("🦴 Showing skeleton loading...")
        isShowingSkeletons = true
        emptyStateView.isHidden = true
        collectionView.reloadData()
    }
    
    private func hideSkeletonLoading() {
        print("🦴 Hiding skeleton loading...")
        isShowingSkeletons = false
        // updateUI will be called after this to reload with actual data
    }
    
    // MARK: - Actions
    
    @objc private func showSettings() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    @objc private func handleRefresh() {
        refreshProjects()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        
        // Don't delete the "Add" button
        guard indexPath.item < projects.count else { return }
        
        let project = projects[indexPath.item]
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Show delete confirmation
        let alert = UIAlertController(
            title: "Delete Project?",
            message: "Are you sure you want to delete '\(project.displayName)'?",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteProject(project)
        }
        
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        print("❌ DEBUG: showError called with message: \(message)")
        print("❌ DEBUG: Current isLoading state: \(isLoading)")
        
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showError(message)
            }
            return
        }
        
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        
        // Add a "Try Again" action that properly triggers loading
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
            print("🔁 DEBUG: Try Again tapped from alert")
            self?.refreshProjects()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func createNewProject() {
        let alert = UIAlertController(title: "New Project", message: "Enter project details", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Project Name"
            textField.font = CyberpunkTheme.bodyFont
            textField.textColor = CyberpunkTheme.primaryText
            textField.tintColor = CyberpunkTheme.primaryCyan
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Project Path (e.g., ~/Projects/MyApp)"
            textField.font = CyberpunkTheme.codeFont
            textField.textColor = CyberpunkTheme.primaryText
            textField.tintColor = CyberpunkTheme.primaryCyan
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let path = alert.textFields?[1].text, !path.isEmpty else {
                return
            }
            
            self?.createProject(name: name, path: path)
        }
        createAction.setValue(CyberpunkTheme.primaryCyan, forKey: "titleTextColor")
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(CyberpunkTheme.secondaryText, forKey: "titleTextColor")
        
        alert.addAction(createAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func createProject(name: String, path: String) {
        Task {
            do {
                // Create via API
                let project = try await APIClient.shared.createProject(name: name, path: path)
                
                await MainActor.run {
                    self.projects.append(project)
                    self.updateUI()
                    
                    // Show success feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
                
                // Save to local cache if available
                if let dataContainer = dataContainer {
                    try? await dataContainer.saveProject(project)
                }
            } catch {
                await MainActor.run {
                    self.showError("Failed to create project: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteProject(_ project: Project) {
        Task {
            do {
                // Delete from backend
                try await APIClient.shared.deleteProject(id: project.id)
                
                // Remove from local array
                await MainActor.run {
                    if let index = self.projects.firstIndex(where: { $0.id == project.id }) {
                        self.projects.remove(at: index)
                        self.updateUI()
                        
                        // Show success feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
                
                // Delete from local cache if available
                if let dataContainer = dataContainer {
                    try? await dataContainer.deleteProject(project)
                }
            } catch {
                await MainActor.run {
                    self.showError("Failed to delete project: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func openProject(_ project: Project) {
        // Use callback if available (for tab-based navigation)
        // Otherwise push directly (for standalone usage)
        if let onProjectSelected = onProjectSelected {
            onProjectSelected(project)
        } else if let navigationController = navigationController {
            // Navigate to sessions list for the project
            let sessionsVC = SessionsViewController(project: project)
            navigationController.pushViewController(sessionsVC, animated: true)
        } else {
            print("⚠️ Warning: No navigation controller available and no project selection callback set")
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ProjectsViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isShowingSkeletons {
            return 6 // Show 6 skeleton cells while loading
        }
        return projects.count + 1 // +1 for add button
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isShowingSkeletons {
            // Return skeleton cell while loading
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SkeletonCollectionViewCell.identifier, for: indexPath) as! SkeletonCollectionViewCell
            cell.startAnimating()
            return cell
        }
        
        if indexPath.item == projects.count {
            // Add project cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddProjectCollectionViewCell.identifier, for: indexPath) as! AddProjectCollectionViewCell
            return cell
        } else {
            // Project cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProjectCollectionViewCell.identifier, for: indexPath) as! ProjectCollectionViewCell
            let project = projects[indexPath.item]
            cell.configure(with: project)
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate

extension ProjectsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Don't handle taps while showing skeletons
        guard !isShowingSkeletons else { return }
        
        if indexPath.item == projects.count {
            createNewProject()
        } else {
            let project = projects[indexPath.item]
            openProject(project)
        }
    }
}

// MARK: - Collection View Cells

class ProjectCollectionViewCell: UICollectionViewCell {
    static let identifier = "ProjectCollectionViewCell"
    
    private let projectCard = ProjectCard()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(projectCard)
        projectCard.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            projectCard.topAnchor.constraint(equalTo: contentView.topAnchor),
            projectCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            projectCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            projectCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with project: Project) {
        projectCard.configure(with: project)
    }
}

class AddProjectCollectionViewCell: UICollectionViewCell {
    static let identifier = "AddProjectCollectionViewCell"
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = CyberpunkTheme.surface
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 2
        view.layer.borderColor = CyberpunkTheme.border.cgColor
        
        // Dashed border
        let dashLayer = CAShapeLayer()
        dashLayer.strokeColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.5).cgColor
        dashLayer.lineWidth = 2
        dashLayer.lineDashPattern = [6, 6]
        dashLayer.fillColor = nil
        dashLayer.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: 12).cgPath
        view.layer.addSublayer(dashLayer)
        self.dashLayer = dashLayer
        
        return view
    }()
    
    private var dashLayer: CAShapeLayer?
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = CyberpunkTheme.primaryCyan
        
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .thin)
        imageView.image = UIImage(systemName: "plus.circle", withConfiguration: config)
        
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "New Project"
        label.font = CyberpunkTheme.headingFont
        label.textColor = CyberpunkTheme.primaryCyan
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dashLayer?.path = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 12).cgPath
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 180),
            
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -20),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }
}

// MARK: - Skeleton Cell

class SkeletonCollectionViewCell: UICollectionViewCell {
    static let identifier = "SkeletonCollectionViewCell"
    
    private let skeletonContainer = SkeletonContainerView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = CyberpunkTheme.surface
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = CyberpunkTheme.border.cgColor
        
        skeletonContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(skeletonContainer)
        
        NSLayoutConstraint.activate([
            skeletonContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            skeletonContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            skeletonContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            skeletonContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            skeletonContainer.heightAnchor.constraint(equalToConstant: 180)
        ])
        
        // Setup card skeleton layout
        skeletonContainer.setupCardSkeleton()
    }
    
    func startAnimating() {
        skeletonContainer.startAnimating()
    }
    
    func stopAnimating() {
        skeletonContainer.stopAnimating()
    }
}