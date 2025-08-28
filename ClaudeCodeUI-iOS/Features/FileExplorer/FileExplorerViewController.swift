//
//  FileExplorerViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

class FileExplorerViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let project: Project
    private var rootNode: FileTreeNode?
    private var expandedNodes: Set<String> = []
    private var selectedNode: FileTreeNode?
    private let apiClient: APIClient
    private var animatedCells = Set<IndexPath>()
    private var isSearching = false
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FileTreeCell.self, forCellReuseIdentifier: FileTreeCell.identifier)
        tableView.rowHeight = 44
        return tableView
    }()
    
    private let refreshControl = UIRefreshControl()
    
    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.barStyle = .black
        toolbar.isTranslucent = true
        toolbar.backgroundColor = CyberpunkTheme.surface
        
        let newFileButton = UIBarButtonItem(
            image: UIImage(systemName: "doc.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(createNewFile)
        )
        newFileButton.tintColor = CyberpunkTheme.primaryCyan
        
        let newFolderButton = UIBarButtonItem(
            image: UIImage(systemName: "folder.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(createNewFolder)
        )
        newFolderButton.tintColor = CyberpunkTheme.primaryCyan
        
        let refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshFileTree)
        )
        refreshButton.tintColor = CyberpunkTheme.primaryCyan
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [newFileButton, newFolderButton, flexSpace, refreshButton]
        
        return toolbar
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search files..."
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.tintColor = CyberpunkTheme.primaryCyan
        searchBar.searchTextField.textColor = CyberpunkTheme.primaryText
        searchBar.searchTextField.font = CyberpunkTheme.bodyFont
        return searchBar
    }()
    
    private lazy var emptyStateView = NoDataView(type: .noFiles, action: { [weak self] in
        self?.createNewFile()
    })
    
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
        loadFileTree()
        
        // Add initial entrance animation
        AnimationManager.shared.slideIn(view, from: .bottom, duration: 0.3)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Animate table view cells on appear
        if !tableView.visibleCells.isEmpty {
            AnimationManager.shared.animateTableView(tableView)
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Setup refresh control with custom cyberpunk styling
        setupRefreshControl()
        tableView.refreshControl = refreshControl
        
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(toolbar)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),
            
            emptyStateView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: toolbar.topAnchor)
        ])
        
        setupEmptyState()
    }
    
    private func setupEmptyState() {
        // NoDataView is configured during initialization
        // It shows the appropriate empty state for .noFiles type
        emptyStateView.isHidden = true
    }
    
    // MARK: - Refresh Control Setup
    private func setupRefreshControl() {
        refreshControl.tintColor = CyberpunkTheme.primaryCyan
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        
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
        loadingLabel.text = "⟲ SYNCING FILES"
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
    
    private func setupNavigationBar() {
        title = "Files"
        navigationItem.largeTitleDisplayMode = .never
        
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeFileExplorer)
        )
        closeButton.tintColor = CyberpunkTheme.primaryCyan
        navigationItem.rightBarButtonItem = closeButton
    }
    
    // MARK: - Skeleton Loading
    
    private func showFileExplorerSkeleton() {
        // Hide real content
        tableView.alpha = 0
        
        // Create skeleton cells for file explorer
        let skeletonCount = 8
        
        for i in 0..<skeletonCount {
            let skeletonRow = UIView()
            skeletonRow.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(skeletonRow)
            
            // Indentation for nested items
            let indentLevel = i > 2 && i < 6 ? 1 : 0
            let indentWidth: CGFloat = CGFloat(indentLevel * 24)
            
            // File/folder icon skeleton
            let iconView = UIView()
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.backgroundColor = CyberpunkTheme.surface
            iconView.layer.cornerRadius = 4
            skeletonRow.addSubview(iconView)
            
            // File name skeleton
            let nameView = UIView()
            nameView.translatesAutoresizingMaskIntoConstraints = false
            nameView.backgroundColor = CyberpunkTheme.surface
            nameView.layer.cornerRadius = 4
            skeletonRow.addSubview(nameView)
            
            // Add shimmer gradient
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor.clear.cgColor,
                CyberpunkTheme.primaryCyan.withAlphaComponent(0.1).cgColor,
                UIColor.clear.cgColor
            ]
            gradientLayer.locations = [0, 0.5, 1]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
            gradientLayer.frame = CGRect(x: -view.bounds.width, y: 0, width: view.bounds.width * 3, height: 44)
            skeletonRow.layer.addSublayer(gradientLayer)
            
            // Animate shimmer
            let animation = CABasicAnimation(keyPath: "position.x")
            animation.fromValue = -view.bounds.width
            animation.toValue = view.bounds.width * 2
            animation.duration = 1.5
            animation.repeatCount = .infinity
            gradientLayer.add(animation, forKey: "shimmer")
            
            // Layout constraints
            NSLayoutConstraint.activate([
                skeletonRow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                skeletonRow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                skeletonRow.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: CGFloat(i * 44 + 16)),
                skeletonRow.heightAnchor.constraint(equalToConstant: 44),
                
                iconView.leadingAnchor.constraint(equalTo: skeletonRow.leadingAnchor, constant: 16 + indentWidth),
                iconView.centerYAnchor.constraint(equalTo: skeletonRow.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 20),
                iconView.heightAnchor.constraint(equalToConstant: 20),
                
                nameView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
                nameView.centerYAnchor.constraint(equalTo: skeletonRow.centerYAnchor),
                nameView.widthAnchor.constraint(equalToConstant: CGFloat.random(in: 80...150)),
                nameView.heightAnchor.constraint(equalToConstant: 16)
            ])
            
            skeletonRow.tag = 89999 + i // Use tags to identify skeleton views
        }
    }
    
    private func hideFileExplorerSkeleton() {
        // Remove all skeleton views with staggered animation
        view.subviews.forEach { subview in
            if subview.tag >= 89999 && subview.tag < 90007 {
                let index = subview.tag - 89999
                let delay = Double(index) * 0.05
                
                UIView.animate(withDuration: 0.3, delay: delay, options: .curveEaseOut, animations: {
                    subview.alpha = 0
                    subview.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                }) { _ in
                    subview.removeFromSuperview()
                }
            }
        }
        
        // Show real content with fade and scale animation
        tableView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.tableView.alpha = 1
            self.tableView.transform = .identity
        })
        
        // Animate table cells entrance
        animatedCells.removeAll()
        AnimationManager.shared.animateTableView(tableView)
    }
    
    // MARK: - Data Loading
    
    private func loadFileTree() {
        showFileExplorerSkeleton()
        Task {
            await fetchFileTree()
        }
    }
    
    @MainActor
    private func fetchFileTree() async {
        print("🔍 FileExplorer: fetchFileTree called")
        print("📁 Project name: '\(project.name)'")
        print("📂 Project path: '\(project.path)'")
        print("🏷️ Project display name: '\(project.displayName ?? "nil")'")
        
        do {
            // Call backend API to get file tree
            let apiPath = "/api/projects/\(project.name)/files"
            print("🌐 API Path: \(apiPath)")
            
            let endpoint = APIEndpoint(
                path: apiPath,
                method: .get
            )
            
            // The backend returns an array of file tree nodes
            let treeNodes: [FileTreeNodeDTO] = try await apiClient.request(endpoint)
            
            // Convert DTOs to our internal model
            rootNode = FileTreeNode(name: project.name, path: project.path, isDirectory: true, children: treeNodes.map { convertToFileTreeNode($0) })
            
            hideFileExplorerSkeleton()
            tableView.reloadData()
            
            // Update empty state visibility
            if rootNode == nil || rootNode?.children?.isEmpty ?? true {
                tableView.isHidden = true
                emptyStateView.isHidden = false
            } else {
                emptyStateView.isHidden = true
                tableView.isHidden = false
            }
        } catch {
            print("❌ FileExplorer API Error: \(error)")
            print("📍 Error type: \(type(of: error))")
            print("📝 Error description: \(error.localizedDescription)")
            Logger.shared.error("Failed to load file tree: \(error)")
            hideFileExplorerSkeleton()
            
            // Show error to user instead of fake data
            await MainActor.run {
                self.showError("Failed to load file tree: \(error.localizedDescription)")
                self.tableView.isHidden = true
                self.emptyStateView.isHidden = false
                self.tableView.reloadData()
            }
        }
    }
    
    private func convertToFileTreeNode(_ dto: FileTreeNodeDTO) -> FileTreeNode {
        let children = dto.children?.map { convertToFileTreeNode($0) }
        return FileTreeNode(
            name: dto.name,
            path: dto.path,
            isDirectory: dto.type == "directory",
            children: children
        )
    }
    
    
    // MARK: - Actions
    
    @objc private func closeFileExplorer() {
        // Add slide out animation
        AnimationManager.shared.slideOut(view, to: .bottom, duration: 0.3) { [weak self] in
            self?.dismiss(animated: false)
        }
    }
    
    @objc private func createNewFile() {
        // Add haptic feedback and pulse animation on button
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if let button = toolbar.items?.first {
            if let view = button.value(forKey: "view") as? UIView {
                AnimationManager.shared.pulse(view, scale: 1.2, duration: 0.2)
            }
        }
        
        showCreateDialog(isDirectory: false)
    }
    
    @objc private func createNewFolder() {
        // Add haptic feedback and pulse animation on button
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if let button = toolbar.items?[1] {
            if let view = button.value(forKey: "view") as? UIView {
                AnimationManager.shared.pulse(view, scale: 1.2, duration: 0.2)
            }
        }
        
        showCreateDialog(isDirectory: true)
    }
    
    @objc private func refreshFileTree() {
        // Clear animation tracking for fresh animations
        animatedCells.removeAll()
        
        // Animate refresh button
        if let refreshButton = toolbar.items?.last {
            if let view = refreshButton.value(forKey: "view") as? UIView {
                AnimationManager.shared.rotate(view, angle: .pi * 2, duration: 0.5)
            }
        }
        
        loadFileTree()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func handlePullToRefresh() {
        // Add haptic feedback when refresh starts
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Log refresh action
        print("🔄 Pull-to-refresh triggered for file explorer")
        
        Task {
            await refreshFileTreeWithFeedback()
        }
    }
    
    @MainActor
    private func refreshFileTreeWithFeedback() async {
        // Show loading indicator while scanning files
        showLoading(message: "Scanning file tree...")
        
        do {
            // Call backend API to get file tree
            let endpoint = APIEndpoint(
                path: "/api/projects/\(project.name)/files",
                method: .get
            )
            
            // The backend returns an array of file tree nodes
            let treeNodes: [FileTreeNodeDTO] = try await apiClient.request(endpoint)
            
            // Convert DTOs to our internal model
            rootNode = FileTreeNode(name: project.name, path: project.path, isDirectory: true, children: treeNodes.map { convertToFileTreeNode($0) })
            
            tableView.reloadData()
            
            // Update empty state visibility
            if rootNode == nil || rootNode?.children?.isEmpty ?? true {
                tableView.isHidden = true
                emptyStateView.isHidden = false
            } else {
                emptyStateView.isHidden = true
                tableView.isHidden = false
            }
            
            // Haptic feedback on successful refresh
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.prepare()
            successFeedback.notificationOccurred(.success)
            
            print("✅ File tree refreshed successfully")
            
            // Hide loading indicator on success
            hideLoading()
            refreshControl.endRefreshing()
        } catch {
            Logger.shared.error("Failed to refresh file tree: \(error)")
            
            // Error haptic feedback
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.prepare()
            errorFeedback.notificationOccurred(.error)
            
            print("❌ File tree refresh failed: \(error.localizedDescription)")
            
            // Hide loading indicator on error
            hideLoading()
            refreshControl.endRefreshing()
            
            // Show error alert
            let alert = UIAlertController(
                title: "Refresh Failed",
                message: "Could not refresh file tree: \(error.localizedDescription)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func showCreateDialog(isDirectory: Bool) {
        let title = isDirectory ? "New Folder" : "New File"
        let placeholder = isDirectory ? "Folder name" : "File name"
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.font = CyberpunkTheme.bodyFont
            textField.textColor = CyberpunkTheme.primaryText
            textField.tintColor = CyberpunkTheme.primaryCyan
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            // Validate name is not empty
            if name.isEmpty {
                self?.showValidationError(message: "\(isDirectory ? "Folder" : "File") name cannot be empty. Please enter a valid name.")
                return
            }
            
            // Validate filename/folder name for invalid characters
            let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
            if name.rangeOfCharacter(from: invalidCharacters) != nil {
                self?.showValidationError(message: "\(isDirectory ? "Folder" : "File") name contains invalid characters. Please use only letters, numbers, dots, dashes, and underscores.")
                return
            }
            
            // Validate that name doesn't start with a dot (unless it's a dotfile)
            if name.hasPrefix(".") && name.count == 1 {
                self?.showValidationError(message: "Invalid name. A \(isDirectory ? "folder" : "file") cannot be named just a dot.")
                return
            }
            
            // Validate file extension for files
            if !isDirectory && !name.contains(".") {
                // Warning for files without extension
                let warningAlert = UIAlertController(
                    title: "No File Extension",
                    message: "The file '\(name)' has no extension. Do you want to continue?",
                    preferredStyle: .alert
                )
                
                let continueAction = UIAlertAction(title: "Continue", style: .default) { _ in
                    self?.createFileOrFolder(name: name, isDirectory: false)
                }
                continueAction.setValue(CyberpunkTheme.primaryCyan, forKey: "titleTextColor")
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                cancelAction.setValue(CyberpunkTheme.secondaryText, forKey: "titleTextColor")
                
                warningAlert.addAction(continueAction)
                warningAlert.addAction(cancelAction)
                
                self?.present(warningAlert, animated: true)
                return
            }
            
            self?.createFileOrFolder(name: name, isDirectory: isDirectory)
        }
        createAction.setValue(CyberpunkTheme.primaryCyan, forKey: "titleTextColor")
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(CyberpunkTheme.secondaryText, forKey: "titleTextColor")
        
        alert.addAction(createAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func createFileOrFolder(name: String, isDirectory: Bool) {
        Task {
            // Show loading indicator while creating
            await MainActor.run {
                showLoading(message: "Creating \(isDirectory ? "folder" : "file")...")
            }
            
            do {
                // Get current selected path or use root
                let basePath = selectedNode?.isDirectory == true ? selectedNode?.path : ""
                let fullPath = basePath?.isEmpty == false ? "\(basePath!)/\(name)" : name
                
                if isDirectory {
                    // For directories, create via the file API with special marker
                    try await apiClient.saveFile(
                        projectName: project.name,
                        filePath: "\(fullPath)/.gitkeep",  // Create a placeholder file in the directory
                        content: ""
                    )
                } else {
                    // For files, create with initial content
                    let initialContent = name.hasSuffix(".swift") ? 
                        "//\n//  \(name)\n//  \(project.name)\n//\n//  Created on \(Date())\n//\n\nimport Foundation\n\n" : ""
                    
                    try await apiClient.saveFile(
                        projectName: project.name,
                        filePath: fullPath,
                        content: initialContent
                    )
                }
                
                await MainActor.run {
                    Logger.shared.info("Successfully created \(isDirectory ? "folder" : "file"): \(name)")
                    
                    // Hide loading indicator
                    self.hideLoading()
                    
                    // Refresh the file tree
                    self.loadFileTree()
                    
                    // Show success feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    // Hide loading indicator on error
                    self.hideLoading()
                    
                    Logger.shared.error("Failed to create \(isDirectory ? "folder" : "file"): \(error)")
                    
                    // Determine error type and show appropriate alert
                    let errorMessage: String
                    let showRetry: Bool
                    
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .networkError:
                            errorMessage = "Network error while creating \(isDirectory ? "folder" : "file"). Please check your connection."
                            showRetry = true
                        case .serverError(let message):
                            if message.contains("409") {
                                errorMessage = "A \(isDirectory ? "folder" : "file") with this name already exists in this location."
                                showRetry = false
                            } else if message.contains("403") {
                                errorMessage = "Permission denied. You don't have write access to this location."
                                showRetry = false
                            } else if message.contains("507") {
                                errorMessage = "Insufficient storage space to create the \(isDirectory ? "folder" : "file")."
                                showRetry = false
                            } else {
                                errorMessage = "Server error: \(message)"
                                showRetry = true
                            }
                        case .invalidResponse:
                            errorMessage = "Invalid response from server. Please try again."
                            showRetry = true
                        default:
                            errorMessage = "Failed to create \(isDirectory ? "folder" : "file"): \(error.localizedDescription)"
                            showRetry = true
                        }
                    } else {
                        errorMessage = "Failed to create \(isDirectory ? "folder" : "file"): \(error.localizedDescription)"
                        showRetry = true
                    }
                    
                    if showRetry {
                        self.showErrorAlert(
                            severity: .error,
                            title: "Creation Failed",
                            message: errorMessage,
                            showRetry: true,
                            retryAction: { [weak self] in
                                self?.createFileOrFolder(name: name, isDirectory: isDirectory)
                            }
                        )
                    } else {
                        self.showErrorAlert(
                            severity: .warning,
                            title: "Cannot Create",
                            message: errorMessage,
                            showRetry: false
                        )
                    }
                }
            }
        }
    }
    
    private func deleteNode(_ node: FileTreeNode) {
        let alert = UIAlertController(
            title: "Delete \(node.isDirectory ? "Folder" : "File")",
            message: "Are you sure you want to delete '\(node.name)'?",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                do {
                    // Call the delete file API endpoint
                    try await self.apiClient.deleteFile(path: node.path)
                    
                    await MainActor.run {
                        Logger.shared.info("Successfully deleted: \(node.path)")
                        self.loadFileTree()
                        
                        // Show success feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                } catch {
                    await MainActor.run {
                        Logger.shared.error("Failed to delete: \(error)")
                        self.showError("Failed to delete '\(node.name)': \(error.localizedDescription)")
                    }
                }
            }
        }
        
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func renameNode(_ node: FileTreeNode) {
        let alert = UIAlertController(
            title: "Rename",
            message: nil,
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.text = node.name
            textField.font = CyberpunkTheme.bodyFont
            textField.textColor = CyberpunkTheme.primaryText
            textField.tintColor = CyberpunkTheme.primaryCyan
        }
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text, 
                  !newName.isEmpty,
                  newName != node.name else { return }
            
            Task {
                do {
                    // Get the directory path and construct new path
                    let components = node.path.components(separatedBy: "/")
                    let directory = components.dropLast().joined(separator: "/")
                    let newPath = directory.isEmpty ? newName : "\(directory)/\(newName)"
                    
                    // Read the file content first
                    let content = try await self.apiClient.readFile(
                        projectName: self.project.name,
                        filePath: node.path
                    )
                    
                    // Write to new location
                    try await self.apiClient.saveFile(
                        projectName: self.project.name,
                        filePath: newPath,
                        content: content
                    )
                    
                    // Delete old file
                    try await self.apiClient.deleteFile(path: node.path)
                    
                    await MainActor.run {
                        Logger.shared.info("Successfully renamed \(node.name) to \(newName)")
                        self.loadFileTree()
                        
                        // Show success feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                } catch {
                    await MainActor.run {
                        Logger.shared.error("Failed to rename: \(error)")
                        self.showError("Failed to rename '\(node.name)': \(error.localizedDescription)")
                    }
                }
            }
        }
        renameAction.setValue(CyberpunkTheme.primaryCyan, forKey: "titleTextColor")
        
        alert.addAction(renameAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func duplicateFile(_ node: FileTreeNode) {
        Task {
            do {
                // Read the file content first
                let content = try await self.apiClient.readFile(
                    projectName: self.project.name,
                    filePath: node.path
                )
                
                // Generate new name
                let nameWithoutExt = (node.name as NSString).deletingPathExtension
                let ext = (node.name as NSString).pathExtension
                let newName = ext.isEmpty ? "\(nameWithoutExt)_copy" : "\(nameWithoutExt)_copy.\(ext)"
                
                // Get the directory path and construct new path
                let components = node.path.components(separatedBy: "/")
                let directory = components.dropLast().joined(separator: "/")
                let newPath = directory.isEmpty ? newName : "\(directory)/\(newName)"
                
                // Write to new location
                try await self.apiClient.saveFile(
                    projectName: self.project.name,
                    filePath: newPath,
                    content: content
                )
                
                await MainActor.run {
                    Logger.shared.info("Successfully duplicated \(node.name)")
                    self.loadFileTree()
                    
                    // Show success feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    Logger.shared.error("Failed to duplicate: \(error)")
                    self.showError("Failed to duplicate '\(node.name)': \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func openFile(_ node: FileTreeNode) {
        // TODO: Implement file preview
        Logger.shared.info("Opening file: \(node.path)")
        
        let previewVC = FilePreviewViewController(fileNode: node, project: project)
        navigationController?.pushViewController(previewVC, animated: true)
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
    
    // MARK: - Helper Methods
    
    private func getAllNodes(from node: FileTreeNode) -> [FileTreeNode] {
        var nodes: [FileTreeNode] = []
        
        func addNodes(_ node: FileTreeNode, level: Int) {
            var nodeWithLevel = node
            nodeWithLevel.level = level
            nodes.append(nodeWithLevel)
            
            if node.isDirectory && expandedNodes.contains(node.path) {
                node.children?.forEach { child in
                    addNodes(child, level: level + 1)
                }
            }
        }
        
        rootNode?.children?.forEach { child in
            addNodes(child, level: 0)
        }
        
        return nodes
    }
}

// MARK: - UITableViewDataSource

extension FileExplorerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getAllNodes(from: rootNode ?? FileTreeNode(name: "", path: "", isDirectory: false, children: nil)).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FileTreeCell.identifier, for: indexPath) as! FileTreeCell
        let nodes = getAllNodes(from: rootNode ?? FileTreeNode(name: "", path: "", isDirectory: false, children: nil))
        
        if indexPath.row < nodes.count {
            let node = nodes[indexPath.row]
            // FileTreeCell expects FileNodeUI, but we have FileTreeNode
            // We'll just configure the cell manually
            if node.isDirectory {
                cell.textLabel?.text = "📁 \(node.name)"
            } else {
                cell.textLabel?.text = "📄 \(node.name)"
            }
            cell.textLabel?.font = CyberpunkTheme.bodyFont
            cell.textLabel?.textColor = CyberpunkTheme.primaryText
            cell.contentView.layoutMargins.left = CGFloat(20 * node.level)
        }
        
        cell.accessibilityIdentifier = "fileCell_\(indexPath.row)"
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FileExplorerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Only animate if not already animated and not searching
        guard !animatedCells.contains(indexPath) && !isSearching else { return }
        animatedCells.insert(indexPath)
        
        // Staggered entrance animation
        let delay = Double(indexPath.row) * 0.03
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: -30, y: 0)
        
        UIView.animate(
            withDuration: 0.4,
            delay: delay,
            options: .curveEaseOut,
            animations: {
                cell.alpha = 1
                cell.transform = .identity
            }
        )
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let nodes = getAllNodes(from: rootNode ?? FileTreeNode(name: "", path: "", isDirectory: false, children: nil))
        guard indexPath.row < nodes.count else { return }
        
        let node = nodes[indexPath.row]
        
        // Animate the selected cell
        if let cell = tableView.cellForRow(at: indexPath) {
            AnimationManager.shared.pulse(cell, scale: 1.02, duration: 0.2)
        }
        
        if node.isDirectory {
            // Toggle expansion with animation
            let isExpanding = !expandedNodes.contains(node.path)
            
            if isExpanding {
                expandedNodes.insert(node.path)
                
                // Animate expansion
                tableView.performBatchUpdates({
                    // Clear animation cache for new cells
                    self.animatedCells.removeAll()
                    tableView.reloadData()
                }, completion: nil)
                
                // Add expand sound effect (haptic)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } else {
                expandedNodes.remove(node.path)
                
                // Animate collapse
                tableView.performBatchUpdates({
                    tableView.reloadData()
                }, completion: nil)
                
                // Add collapse sound effect (haptic)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        } else {
            // Open file with animation
            selectedNode = node
            
            // Pulse the cell before opening
            if let cell = tableView.cellForRow(at: indexPath) {
                AnimationManager.shared.scaleSpring(cell, scale: 1.05, duration: 0.3)
            }
            
            // Delay file opening slightly for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.openFile(node)
            }
            
            // Success haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let nodes = getAllNodes(from: rootNode ?? FileTreeNode(name: "", path: "", isDirectory: false, children: nil))
        guard indexPath.row < nodes.count else { return nil }
        
        let node = nodes[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, view, completion in
            // Add haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            
            // Animate the cell before deletion
            if let cell = tableView.cellForRow(at: indexPath) {
                AnimationManager.shared.shake(cell, intensity: 10)
            }
            
            self?.deleteNode(node)
            completion(true)
        }
        deleteAction.backgroundColor = CyberpunkTheme.accentPink
        deleteAction.image = UIImage(systemName: "trash.fill")
        
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] _, view, completion in
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Pulse the cell
            if let cell = tableView.cellForRow(at: indexPath) {
                AnimationManager.shared.pulse(cell, scale: 1.05, duration: 0.2)
            }
            
            self?.renameNode(node)
            completion(true)
        }
        renameAction.backgroundColor = CyberpunkTheme.primaryCyan
        renameAction.image = UIImage(systemName: "pencil.circle.fill")
        
        // Add duplicate action for files
        if !node.isDirectory {
            let duplicateAction = UIContextualAction(style: .normal, title: "Duplicate") { [weak self] _, view, completion in
                // Add haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // Animate the cell
                if let cell = tableView.cellForRow(at: indexPath) {
                    AnimationManager.shared.bounce(cell, height: 10)
                }
                
                self?.duplicateFile(node)
                completion(true)
            }
            duplicateAction.backgroundColor = UIColor.systemGreen
            duplicateAction.image = UIImage(systemName: "doc.on.doc.fill")
            
            return UISwipeActionsConfiguration(actions: [deleteAction, duplicateAction, renameAction])
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
    }
}

// MARK: - UISearchBarDelegate

extension FileExplorerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // TODO: Implement file search
        if !searchText.isEmpty {
            Logger.shared.info("Searching for: \(searchText)")
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - File Tree Node Model

struct FileTreeNode {
    let name: String
    let path: String
    let isDirectory: Bool
    var children: [FileTreeNode]?
    var level: Int = 0
    
    var icon: UIImage? {
        if isDirectory {
            return UIImage(systemName: "folder.fill")
        } else {
            // Return icon based on file extension
            let ext = (name as NSString).pathExtension.lowercased()
            switch ext {
            case "swift":
                return UIImage(systemName: "swift")
            case "js", "ts", "jsx", "tsx":
                return UIImage(systemName: "curlybraces")
            case "json":
                return UIImage(systemName: "doc.text")
            case "md":
                return UIImage(systemName: "doc.richtext")
            case "yml", "yaml":
                return UIImage(systemName: "doc.badge.gearshape")
            case "png", "jpg", "jpeg", "gif":
                return UIImage(systemName: "photo")
            default:
                return UIImage(systemName: "doc")
            }
        }
    }
}

// DTO for decoding file tree from backend
struct FileTreeNodeDTO: Codable {
    let name: String
    let path: String
    let type: String
    let children: [FileTreeNodeDTO]?
}

