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
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = CyberpunkTheme.secondaryText
        
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .thin)
        imageView.image = UIImage(systemName: "folder", withConfiguration: config)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No files in this project"
        label.font = CyberpunkTheme.headlineFont
        label.textColor = CyberpunkTheme.secondaryText
        label.textAlignment = .center
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
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
        loadFileTree()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
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
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
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
    
    // MARK: - Data Loading
    
    private func loadFileTree() {
        Task {
            await fetchFileTree()
        }
    }
    
    @MainActor
    private func fetchFileTree() async {
        do {
            // Call backend API to get file tree
            let endpoint = APIEndpoint(
                path: "/api/projects/\(project.id)/files",
                method: .get
            )
            
            // The backend returns an array of file tree nodes
            let treeNodes: [FileTreeNodeDTO] = try await apiClient.request(endpoint)
            
            // Convert DTOs to our internal model
            rootNode = FileTreeNode(name: project.name, path: project.path, isDirectory: true, children: treeNodes.map { convertToFileTreeNode($0) })
            
            tableView.reloadData()
            emptyStateView.isHidden = rootNode != nil && !(rootNode?.children?.isEmpty ?? true)
        } catch {
            Logger.shared.error("Failed to load file tree: \(error)")
            
            // Fall back to mock data on error
            rootNode = createMockFileTree()
            tableView.reloadData()
            emptyStateView.isHidden = rootNode != nil
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
    
    private func createMockFileTree() -> FileTreeNode {
        // Add mock files
        let srcFolder = FileTreeNode(name: "src", path: "/src", isDirectory: true, children: [
            FileTreeNode(name: "main.swift", path: "/src/main.swift", isDirectory: false, children: nil),
            FileTreeNode(name: "utils.swift", path: "/src/utils.swift", isDirectory: false, children: nil),
            FileTreeNode(name: "models", path: "/src/models", isDirectory: true, children: [
                FileTreeNode(name: "User.swift", path: "/src/models/User.swift", isDirectory: false, children: nil),
                FileTreeNode(name: "Project.swift", path: "/src/models/Project.swift", isDirectory: false, children: nil)
            ])
        ])
        
        let testsFolder = FileTreeNode(name: "tests", path: "/tests", isDirectory: true, children: [
            FileTreeNode(name: "MainTests.swift", path: "/tests/MainTests.swift", isDirectory: false, children: nil)
        ])
        
        let configFiles = [
            FileTreeNode(name: "Package.swift", path: "/Package.swift", isDirectory: false, children: nil),
            FileTreeNode(name: "README.md", path: "/README.md", isDirectory: false, children: nil),
            FileTreeNode(name: ".gitignore", path: "/.gitignore", isDirectory: false, children: nil)
        ]
        
        let rootChildren = [srcFolder, testsFolder] + configFiles
        let root = FileTreeNode(name: project.name, path: "/", isDirectory: true, children: rootChildren)
        
        return root
    }
    
    // MARK: - Actions
    
    @objc private func closeFileExplorer() {
        dismiss(animated: true)
    }
    
    @objc private func createNewFile() {
        showCreateDialog(isDirectory: false)
    }
    
    @objc private func createNewFolder() {
        showCreateDialog(isDirectory: true)
    }
    
    @objc private func refreshFileTree() {
        loadFileTree()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
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
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
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
        // TODO: Implement actual file/folder creation via API
        Logger.shared.info("Creating \(isDirectory ? "folder" : "file"): \(name)")
        
        // For now, just refresh
        loadFileTree()
    }
    
    private func deleteNode(_ node: FileTreeNode) {
        let alert = UIAlertController(
            title: "Delete \(node.isDirectory ? "Folder" : "File")",
            message: "Are you sure you want to delete '\(node.name)'?",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            // TODO: Implement actual deletion via API
            Logger.shared.info("Deleting: \(node.path)")
            self?.loadFileTree()
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
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            // TODO: Implement actual renaming via API
            Logger.shared.info("Renaming \(node.name) to \(newName)")
            self?.loadFileTree()
        }
        renameAction.setValue(CyberpunkTheme.primaryCyan, forKey: "titleTextColor")
        
        alert.addAction(renameAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func openFile(_ node: FileTreeNode) {
        // TODO: Implement file preview
        Logger.shared.info("Opening file: \(node.path)")
        
        let previewVC = FilePreviewViewController(fileNode: node, project: project)
        navigationController?.pushViewController(previewVC, animated: true)
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
            let isExpanded = expandedNodes.contains(node.path)
            let isSelected = selectedNode?.path == node.path
            cell.configure(with: node, isExpanded: isExpanded, isSelected: isSelected)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FileExplorerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let nodes = getAllNodes(from: rootNode ?? FileTreeNode(name: "", path: "", isDirectory: false, children: nil))
        guard indexPath.row < nodes.count else { return }
        
        let node = nodes[indexPath.row]
        
        if node.isDirectory {
            // Toggle expansion
            if expandedNodes.contains(node.path) {
                expandedNodes.remove(node.path)
            } else {
                expandedNodes.insert(node.path)
            }
            tableView.reloadData()
        } else {
            // Open file
            selectedNode = node
            tableView.reloadData()
            openFile(node)
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let nodes = getAllNodes(from: rootNode ?? FileTreeNode(name: "", path: "", isDirectory: false, children: nil))
        guard indexPath.row < nodes.count else { return nil }
        
        let node = nodes[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteNode(node)
            completion(true)
        }
        deleteAction.backgroundColor = CyberpunkTheme.accentPink
        
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] _, _, completion in
            self?.renameNode(node)
            completion(true)
        }
        renameAction.backgroundColor = CyberpunkTheme.primaryCyan
        
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

// MARK: - File Tree Cell

class FileTreeCell: UITableViewCell {
    static let identifier = "FileTreeCell"
    
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let chevronImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        let selectedBackground = UIView()
        selectedBackground.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.1)
        selectedBackgroundView = selectedBackground
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = CyberpunkTheme.primaryCyan
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = CyberpunkTheme.codeFont
        nameLabel.textColor = CyberpunkTheme.primaryText
        
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.tintColor = CyberpunkTheme.secondaryText
        chevronImageView.image = UIImage(systemName: "chevron.right")
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    func configure(with node: FileTreeNode, isExpanded: Bool, isSelected: Bool) {
        // Indentation based on level
        let indentation = CGFloat(node.level * 20)
        iconImageView.transform = CGAffineTransform(translationX: indentation, y: 0)
        nameLabel.transform = CGAffineTransform(translationX: indentation, y: 0)
        
        iconImageView.image = node.icon
        nameLabel.text = node.name
        
        if node.isDirectory {
            chevronImageView.isHidden = false
            chevronImageView.transform = isExpanded ? 
                CGAffineTransform(rotationAngle: .pi / 2) : .identity
            iconImageView.tintColor = CyberpunkTheme.primaryCyan
        } else {
            chevronImageView.isHidden = true
            iconImageView.tintColor = CyberpunkTheme.secondaryText
        }
        
        if isSelected {
            nameLabel.textColor = CyberpunkTheme.primaryCyan
            backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.05)
        } else {
            nameLabel.textColor = CyberpunkTheme.primaryText
            backgroundColor = .clear
        }
    }
}