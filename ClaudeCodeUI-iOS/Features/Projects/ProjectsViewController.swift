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
    
    private let emptyStateView = NoDataView(type: .noProjects)
    
    // MARK: - Properties
    
    private var projects: [Project] = []
    private let dataContainer: SwiftDataContainer?
    private let errorHandler: ErrorHandlingService
    private let refreshControl = UIRefreshControl()
    
    // Track if initial load has been performed
    private var hasPerformedInitialLoad = false
    
    // Track if we're showing skeleton loading
    private var isShowingSkeletons = false
    
    // Track if a load is currently in progress
    private var isLoadingProjects = false
    
    // Track animated cells to prevent re-animation
    private var animatedCells = Set<IndexPath>()
    
    // Callback for project selection
    var onProjectSelected: ((Project) -> Void)?
    
    // MARK: - Initialization
    
    @MainActor
    init(dataContainer: SwiftDataContainer? = nil,
         errorHandler: ErrorHandlingService? = nil) {
        print("🚨🚨🚨 ProjectsViewController.init() CALLED!")
        self.dataContainer = dataContainer ?? DIContainer.shared.dataContainer
        self.errorHandler = errorHandler ?? DIContainer.shared.errorHandler
        super.init(nibName: nil, bundle: nil)
        print("🚨🚨🚨 ProjectsViewController.init() COMPLETED!")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        print("🔴🔴🔴 DEBUG: ProjectsViewController.viewDidLoad() STARTED!")
        print("🔴 DEBUG: Thread is main: \(Thread.isMainThread)")
        setupUI()
        print("🔴 DEBUG: setupUI() completed")
        setupNavigationBar()
        print("🔴 DEBUG: setupNavigationBar() completed")
        print("🔴 DEBUG: About to call performInitialLoad()")
        performInitialLoad()
        print("🔴 DEBUG: performInitialLoad() call completed")
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
        
        // Setup refresh control with custom cyberpunk styling
        setupRefreshControl()
        collectionView.refreshControl = refreshControl
        
        // Add long press gesture for deletion
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 1.5  // Increased to 1.5 seconds to prevent accidental triggers
        longPressGesture.delaysTouchesBegan = false  // Prevent tap delay
        longPressGesture.cancelsTouchesInView = false  // Allow normal taps to work
        collectionView.addGestureRecognizer(longPressGesture)
        
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupEmptyState()
    }
    
    // MARK: - Refresh Control Setup
    private func setupRefreshControl() {
        refreshControl.tintColor = CyberpunkTheme.primaryCyan
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
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
        loadingLabel.text = "⟲ SYNCING PROJECTS"
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
    
    private func setupEmptyState() {
        // Empty state is already configured with type: .noProjects in initialization
        emptyStateView.isHidden = true
    }
    
    private func setupNavigationBar() {
        title = "Projects"
        
        // Style navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = CyberpunkTheme.background
        appearance.titleTextAttributes = [
            .foregroundColor: CyberpunkTheme.primaryText,
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
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
    
    // Public method to force a refresh from outside
    public func forceRefresh() {
        print("🔴🔴🔴 FORCE REFRESH CALLED FROM MAINTABBARCONTROLLER")
        // Reset the flag to force a fresh load
        hasPerformedInitialLoad = false
        performInitialLoad()
    }
    
    private func performInitialLoad() {
        print("🚨🚨🚨 CRITICAL: performInitialLoad() ENTERED!")
        guard !hasPerformedInitialLoad else { 
            print("⚠️ DEBUG: performInitialLoad() skipped - already performed")
            return 
        }
        
        guard !isLoadingProjects else {
            print("⚠️ DEBUG: performInitialLoad() skipped - already loading")
            return
        }
        
        print("🚀 DEBUG: performInitialLoad() called on thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Mark that we're performing initial load
        hasPerformedInitialLoad = true
        isLoadingProjects = true
        
        // Show both skeleton loading and cyberpunk loading indicator
        DispatchQueue.main.async { [weak self] in
            self?.showSkeletonLoading()
            self?.showLoading(message: "Initializing project database...")
        }
        
        print("📱 Starting initial project load...")
        print("🚀 DEBUG: isLoading = \(isLoading)")
        
        Task { @MainActor in
            do {
                // Use the shared APIClient instance which already has auth configured
                print("🔧 Using backend URL: \(AppConfig.backendURL)")
                print("📱 Attempting to fetch projects from API...")
                print("🔑 Auth token present: \(UserDefaults.standard.string(forKey: "authToken") != nil)")
                
                // Debug: Check what URL is actually being used
                print("🔍 DEBUG: AppConfig.backendURL = \(AppConfig.backendURL)")
                print("🔍 DEBUG: Expected URL = http://192.168.0.43:3004")
                
                // Add a minimum delay to see the skeleton animation
                let startTime = Date()
                print("⏱️ API REQUEST START: \(startTime)")
                
                // The shared APIClient already has the development token configured
                let remoteProjects = try await APIClient.shared.fetchProjects()
                
                let endTime = Date()
                let elapsed = endTime.timeIntervalSince(startTime)
                print("⏱️ API REQUEST END: \(endTime)")
                print("⏱️ API REQUEST DURATION: \(String(format: "%.2f", elapsed)) seconds")
                print("✅ Successfully fetched \(remoteProjects.count) projects from API")
                
                // Ensure skeleton shows for at least 0.5 seconds for smooth transition
                if elapsed < 0.5 {
                    let sleepTime = 0.5 - elapsed
                    print("⏳ Adding \(String(format: "%.2f", sleepTime)) second delay to show skeleton animation")
                    try await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
                }
                
                // Already on main thread due to @MainActor
                self.projects = remoteProjects
                self.hideSkeletonLoading()
                self.hideLoading()  // Hide the loading indicator
                self.updateUI()
                self.isLoadingProjects = false  // Reset loading flag
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
                
                // Hide skeleton loading and loading indicator on error
                self.hideSkeletonLoading()
                self.hideLoading()
                self.isLoadingProjects = false  // Reset loading flag on error
                
                // Fall back to local data if available
                if let dataContainer = dataContainer {
                    do {
                        let localProjects = try await dataContainer.fetchProjects()
                        print("📦 Loaded \(localProjects.count) projects from local storage")
                        // Already on main thread
                        self.projects = localProjects
                        self.updateUI()
                    } catch let localErr {
                        print("❌ Failed to load from local storage: \(localErr)")
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
        
        // Add haptic feedback when refresh starts
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Log refresh action
        print("🔄 Pull-to-refresh triggered for projects")
        
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
                
                // Haptic feedback on successful refresh
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.prepare()
                successFeedback.notificationOccurred(.success)
                
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
                
                // Error haptic feedback
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.prepare()
                errorFeedback.notificationOccurred(.error)
                
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
        print("🔴 DEBUG: updateUI() called")
        print("🔴 DEBUG: projects.count = \(projects.count)")
        print("🔴 DEBUG: projects = \(projects)")
        
        // Clear animated cells when reloading to allow fresh animations
        animatedCells.removeAll()
        
        if projects.isEmpty && !isShowingSkeletons {
            collectionView.isHidden = true
            emptyStateView.isHidden = false
        } else {
            emptyStateView.isHidden = true
            collectionView.isHidden = false
        }
        
        collectionView.reloadData()
        print("🔴 DEBUG: collectionView reloaded")
        
        // Add a subtle animation to the collection view itself
        if !projects.isEmpty {
            AnimationManager.shared.fadeIn(collectionView, duration: 0.3)
        }
    }
    
    // MARK: - Skeleton Loading
    
    private func showSkeletonLoading() {
        print("🦴🦴🦴 SKELETON LOADING STATE: SHOWING at \(Date())")
        print("🦴 Number of skeleton cells to show: 6")
        isShowingSkeletons = true
        emptyStateView.isHidden = true
        collectionView.reloadData()
        print("🦴 Collection view reloaded with skeleton cells")
    }
    
    private func hideSkeletonLoading() {
        print("🦴🦴🦴 SKELETON LOADING STATE: HIDING at \(Date())")
        print("🦴 Skeleton cells will be replaced with actual data")
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
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .words
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Project Path (e.g., ~/Projects/MyApp)"
            textField.font = CyberpunkTheme.codeFont
            textField.textColor = CyberpunkTheme.primaryText
            textField.tintColor = CyberpunkTheme.primaryCyan
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            let name = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let path = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            // Validate inputs
            if name.isEmpty {
                self?.displayValidationError(message: "Project name cannot be empty. Please enter a valid name.")
                return
            }
            
            if path.isEmpty {
                self?.displayValidationError(message: "Project path cannot be empty. Please enter a valid path.")
                return
            }
            
            // Validate project name (no special characters that could cause issues)
            let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
            if name.rangeOfCharacter(from: invalidCharacters) != nil {
                self?.displayValidationError(message: "Project name contains invalid characters. Please use only letters, numbers, spaces, and basic punctuation.")
                return
            }
            
            // Validate path format
            if !(self?.isValidPath(path) ?? false) {
                self?.displayValidationError(message: "Invalid project path format. Use absolute paths (e.g., /Users/name/Projects) or tilde paths (e.g., ~/Projects).")
                return
            }
            
            // Check for duplicate project names
            if self?.projects.contains(where: { $0.name.lowercased() == name.lowercased() }) ?? false {
                self?.displayValidationError(message: "A project with this name already exists. Please choose a different name.")
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
    
    private func isValidPath(_ path: String) -> Bool {
        // Accept absolute paths starting with /
        if path.hasPrefix("/") {
            return true
        }
        
        // Accept tilde paths starting with ~
        if path.hasPrefix("~") {
            return true
        }
        
        // Accept relative paths with ./ or ../
        if path.hasPrefix("./") || path.hasPrefix("../") {
            return true
        }
        
        return false
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
        print("🚀 openProject called for: \(project.name)")
        
        // Use callback if available (for tab-based navigation)
        // Otherwise push directly (for standalone usage)
        if let onProjectSelected = onProjectSelected {
            print("📱 Using onProjectSelected callback")
            onProjectSelected(project)
        } else if let navigationController = navigationController {
            print("🔀 Pushing SessionListViewController to navigation stack")
            // Navigate to sessions list for the project
            let sessionsVC = SessionListViewController(project: project)
            navigationController.pushViewController(sessionsVC, animated: true)
        } else {
            print("⚠️ Warning: No navigation controller available and no project selection callback set")
        }
    }
    
    private func duplicateProject(_ project: Project) {
        // Add animation to show duplication in progress
        let alert = UIAlertController(title: "Duplicate Project", message: "Enter a name for the duplicate", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Project Name"
            textField.text = "Copy of \(project.name)"
            textField.font = CyberpunkTheme.bodyFont
            textField.textColor = CyberpunkTheme.primaryText
            textField.tintColor = CyberpunkTheme.primaryCyan
        }
        
        let duplicateAction = UIAlertAction(title: "Duplicate", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            
            Task {
                do {
                    // Create duplicate via API
                    let duplicatedProject = try await APIClient.shared.createProject(
                        name: name,
                        path: project.fullPath ?? project.path
                    )
                    
                    await MainActor.run {
                        self?.projects.append(duplicatedProject)
                        self?.updateUI()
                        
                        // Find the new cell and animate it
                        if let newIndex = self?.projects.firstIndex(where: { $0.id == duplicatedProject.id }),
                           let cell = self?.collectionView.cellForItem(at: IndexPath(item: newIndex, section: 0)) {
                            // Pulse animation to highlight new project
                            AnimationManager.shared.popIn(cell)
                            AnimationManager.shared.neonPulse(cell, color: CyberpunkTheme.success)
                        }
                        
                        // Success feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                } catch {
                    await MainActor.run {
                        self?.showError("Failed to duplicate project: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        alert.addAction(duplicateAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func renameProject(_ project: Project) {
        let alert = UIAlertController(title: "Rename Project", message: "Enter a new name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Project Name"
            textField.text = project.name
            textField.font = CyberpunkTheme.bodyFont
            textField.textColor = CyberpunkTheme.primaryText
            textField.tintColor = CyberpunkTheme.primaryCyan
        }
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            
            Task {
                do {
                    // Rename via API
                    let renamedProject = try await APIClient.shared.renameProject(id: project.id, name: name)
                    
                    await MainActor.run {
                        // Update project in list
                        if let index = self?.projects.firstIndex(where: { $0.id == project.id }) {
                            self?.projects[index] = renamedProject
                            self?.updateUI()
                            
                            // Animate the renamed cell
                            if let cell = self?.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) {
                                AnimationManager.shared.shake(cell, intensity: 5)
                                AnimationManager.shared.neonPulse(cell, color: CyberpunkTheme.primaryCyan)
                            }
                        }
                        
                        // Success feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                } catch {
                    await MainActor.run {
                        self?.showError("Failed to rename project: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        alert.addAction(renameAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func archiveProject(_ project: Project) {
        // Confirm archive action
        let alert = UIAlertController(
            title: "Archive Project?",
            message: "This will move '\(project.displayName)' to the archive.",
            preferredStyle: .alert
        )
        
        let archiveAction = UIAlertAction(title: "Archive", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Find the project index
            guard let index = self.projects.firstIndex(where: { $0.id == project.id }) else { return }
            let indexPath = IndexPath(item: index, section: 0)
            
            // Animate the cell out
            if let cell = self.collectionView.cellForItem(at: indexPath) {
                AnimationManager.shared.slideOut(cell, to: .bottom) {
                    // Remove from array after animation
                    self.projects.remove(at: index)
                    self.updateUI()
                    
                    // Show confirmation
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Show temporary confirmation message
                    self.showTemporaryMessage("Project archived successfully")
                }
            }
        }
        
        alert.addAction(archiveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func displayValidationError(message: String) {
        let alert = UIAlertController(title: "Validation Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Error feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        present(alert, animated: true)
    }
    
    private func showTemporaryMessage(_ message: String) {
        let messageView = UIView()
        messageView.backgroundColor = CyberpunkTheme.surface
        messageView.layer.cornerRadius = 12
        messageView.layer.borderWidth = 1
        messageView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
        
        let label = UILabel()
        label.text = message
        label.textColor = CyberpunkTheme.primaryCyan
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        
        messageView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: messageView.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: messageView.bottomAnchor, constant: -12)
        ])
        
        view.addSubview(messageView)
        messageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        // Animate in
        messageView.alpha = 0
        messageView.transform = CGAffineTransform(translationX: 0, y: -20)
        
        UIView.animate(withDuration: 0.3, animations: {
            messageView.alpha = 1
            messageView.transform = .identity
        }) { _ in
            // Animate out after delay
            UIView.animate(withDuration: 0.3, delay: 2.0, options: [], animations: {
                messageView.alpha = 0
                messageView.transform = CGAffineTransform(translationX: 0, y: -20)
            }) { _ in
                messageView.removeFromSuperview()
            }
        }
        
        // Add glow effect
        AnimationManager.shared.neonPulse(messageView, color: CyberpunkTheme.primaryCyan)
    }
}

// MARK: - UICollectionViewDataSource

extension ProjectsViewController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isShowingSkeletons {
            print("🔵 DEBUG: numberOfItemsInSection - showing skeletons, returning 6")
            return 6 // Show 6 skeleton cells while loading
        }
        let count = projects.count + 1 // +1 for add button
        print("🔵 DEBUG: numberOfItemsInSection - projects.count = \(projects.count), returning \(count)")
        return count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("🎯 didSelectItemAt called - indexPath: \(indexPath.item)")
        
        // Don't handle taps while showing skeletons
        guard !isShowingSkeletons else { 
            print("⚠️ Tap ignored - showing skeletons")
            return 
        }
        
        // Haptic feedback on selection
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Animate the cell selection
        if let cell = collectionView.cellForItem(at: indexPath) {
            AnimationManager.shared.pulse(cell, scale: 0.95, duration: 0.2)
        }
        
        if indexPath.item == projects.count {
            print("➕ Creating new project")
            // Add animation to the add button
            if let cell = collectionView.cellForItem(at: indexPath) {
                AnimationManager.shared.neonPulse(cell, color: CyberpunkTheme.primaryCyan)
            }
            createNewProject()
        } else {
            let project = projects[indexPath.item]
            print("📂 Opening project: \(project.name) at index \(indexPath.item)")
            openProject(project)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Don't animate skeleton cells
        guard !isShowingSkeletons else { return }
        
        // Only animate cells that haven't been animated yet
        guard !animatedCells.contains(indexPath) else { return }
        animatedCells.insert(indexPath)
        
        // Entrance animation based on position
        let delay = Double(indexPath.row) * 0.05
        
        // Start with cell scaled down and invisible
        cell.alpha = 0
        cell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Animate to full size with spring effect
        UIView.animate(
            withDuration: 0.6,
            delay: delay,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                cell.alpha = 1
                cell.transform = .identity
            }
        )
        
        // Add a subtle neon glow for project cells
        if indexPath.item < projects.count {
            AnimationManager.shared.neonPulse(cell, color: CyberpunkTheme.primaryCyan.withAlphaComponent(0.3))
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        // Don't show context menu for skeleton cells or add button
        guard !isShowingSkeletons, indexPath.item < projects.count else { return nil }
        
        let project = projects[indexPath.item]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            // Open action
            let openAction = UIAction(title: "Open", image: UIImage(systemName: "folder.open")) { [weak self] _ in
                self?.openProject(project)
            }
            
            // Duplicate action
            let duplicateAction = UIAction(title: "Duplicate", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
                self?.duplicateProject(project)
            }
            
            // Rename action
            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.renameProject(project)
            }
            
            // Archive action
            let archiveAction = UIAction(title: "Archive", image: UIImage(systemName: "archivebox")) { [weak self] _ in
                self?.archiveProject(project)
            }
            
            // Delete action
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteProject(project)
            }
            
            return UIMenu(title: project.displayName ?? project.name, children: [openAction, duplicateAction, renameAction, archiveAction, deleteAction])
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        // Add haptic feedback when context menu is about to appear
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
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
        
        // Disable user interaction on projectCard to let collection view handle taps
        projectCard.isUserInteractionEnabled = false
        
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
        label.font = .systemFont(ofSize: 28, weight: .bold)
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
// SkeletonCollectionViewCell is defined in Views/SkeletonCollectionViewCell.swift