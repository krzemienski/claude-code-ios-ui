//
//  FileTreeViewController.swift
//  ClaudeCodeUI
//
//  File explorer with hierarchical tree view and cyberpunk theme
//

import UIKit

// MARK: - File Node UI Wrapper
// This wraps the FileNode model from Core/Data/Models/FileNode.swift
// to add UI-specific properties without duplicating the model
struct FileNodeUI {
    let fileNode: FileNode  // Using FileNode from Core/Data/Models/FileNode.swift
    var isExpanded: Bool
    var level: Int
    
    // Proxy properties to access FileNode properties
    var name: String { fileNode.name }
    var path: String { fileNode.path }
    var isDirectory: Bool { fileNode.isDirectory }
    var children: [FileNode]? { fileNode.children.isEmpty ? nil : fileNode.children }
    
    init(fileNode: FileNode, isExpanded: Bool = false, level: Int = 0) {
        self.fileNode = fileNode
        self.isExpanded = isExpanded
        self.level = level
    }
    
    var icon: String {
        if isDirectory {
            return isExpanded ? "📂" : "📁"
        } else {
            // Return icon based on file extension
            let ext = (name as NSString).pathExtension.lowercased()
            switch ext {
            case "swift": return "🔶"
            case "js", "jsx", "ts", "tsx": return "📜"
            case "py": return "🐍"
            case "json": return "📋"
            case "md": return "📝"
            case "html", "css": return "🌐"
            case "png", "jpg", "jpeg", "gif": return "🖼"
            case "mp3", "wav", "aac": return "🎵"
            case "mp4", "mov", "avi": return "🎥"
            case "zip", "tar", "gz": return "📦"
            case "pdf": return "📄"
            case "txt": return "📃"
            default: return "📄"
            }
        }
    }
}

// MARK: - File Tree Cell
class FileTreeCell: UITableViewCell {
    static let identifier = "FileTreeCell"
    
    private let iconLabel = UILabel()
    private let nameLabel = UILabel()
    private let sizeLabel = UILabel()
    private let expandButton = UIButton(type: .system)
    private var indentConstraint: NSLayoutConstraint?
    
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
        
        // Icon label
        iconLabel.font = .systemFont(ofSize: 20)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconLabel)
        
        // Expand button
        expandButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        expandButton.tintColor = CyberpunkTheme.primaryCyan
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(expandButton)
        
        // Name label
        nameLabel.font = CyberpunkTheme.bodyFont
        nameLabel.textColor = CyberpunkTheme.primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Size label
        sizeLabel.font = .systemFont(ofSize: 11)
        sizeLabel.textColor = CyberpunkTheme.secondaryText
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sizeLabel)
        
        // Constraints
        indentConstraint = iconLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        
        NSLayoutConstraint.activate([
            expandButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            expandButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            expandButton.widthAnchor.constraint(equalToConstant: 24),
            expandButton.heightAnchor.constraint(equalToConstant: 24),
            
            indentConstraint!,
            iconLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: sizeLabel.leadingAnchor, constant: -8),
            
            sizeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sizeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sizeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
    }
    
    func configure(with node: FileNodeUI, isExpanded: Bool, onExpand: (() -> Void)?) {
        iconLabel.text = node.icon
        nameLabel.text = node.name
        
        // Indent based on level
        indentConstraint?.constant = CGFloat(16 + (node.level * 20))
        
        // Configure expand button
        if node.isDirectory && node.children != nil {
            expandButton.isHidden = false
            expandButton.transform = isExpanded ? CGAffineTransform(rotationAngle: .pi / 2) : .identity
            
            // Remove old targets and add new one
            expandButton.removeTarget(nil, action: nil, for: .allEvents)
            if let onExpand = onExpand {
                expandButton.addAction(UIAction { _ in onExpand() }, for: .touchUpInside)
            }
        } else {
            expandButton.isHidden = true
        }
        
        // Size label (mock for now)
        if !node.isDirectory {
            sizeLabel.text = "2.3 KB"
            sizeLabel.isHidden = false
        } else {
            sizeLabel.isHidden = true
        }
        
        // Add hover effect
        let hoverView = UIView()
        hoverView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.1)
        selectedBackgroundView = hoverView
    }
}

// MARK: - File Tree View Controller
public class FileTreeViewController: BaseViewController {
    
    // MARK: - Properties
    private let project: Project
    private var rootNode: FileNode?
    private var flattenedNodes: [FileNodeUI] = []
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private let toolbarView = UIView()
    private let refreshControl = UIRefreshControl()
    
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
        loadFileTree()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        title = "Files"
        
        // Search bar
        searchBar.placeholder = "Search files..."
        searchBar.searchBarStyle = .minimal
        searchBar.tintColor = CyberpunkTheme.primaryCyan
        searchBar.searchTextField.textColor = CyberpunkTheme.primaryText
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search files...",
            attributes: [.foregroundColor: CyberpunkTheme.secondaryText]
        )
        searchBar.delegate = self
        
        // Toolbar
        setupToolbar()
        
        // Table view
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FileTreeCell.self, forCellReuseIdentifier: FileTreeCell.identifier)
        tableView.rowHeight = 44
        
        // Refresh control
        refreshControl.tintColor = CyberpunkTheme.primaryCyan
        refreshControl.addTarget(self, action: #selector(refreshFileTree), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // Layout
        view.addSubview(searchBar)
        view.addSubview(toolbarView)
        view.addSubview(tableView)
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 44),
            
            toolbarView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupToolbar() {
        toolbarView.backgroundColor = CyberpunkTheme.surface
        toolbarView.layer.borderWidth = 1
        toolbarView.layer.borderColor = CyberpunkTheme.border.cgColor
        
        // Create file button
        let createButton = UIButton(type: .system)
        createButton.setImage(UIImage(systemName: "doc.badge.plus"), for: .normal)
        createButton.tintColor = CyberpunkTheme.primaryCyan
        createButton.addTarget(self, action: #selector(createFile), for: .touchUpInside)
        
        // Create folder button
        let createFolderButton = UIButton(type: .system)
        createFolderButton.setImage(UIImage(systemName: "folder.badge.plus"), for: .normal)
        createFolderButton.tintColor = CyberpunkTheme.primaryCyan
        createFolderButton.addTarget(self, action: #selector(createFolder), for: .touchUpInside)
        
        // Refresh button
        let refreshButton = UIButton(type: .system)
        refreshButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refreshButton.tintColor = CyberpunkTheme.primaryCyan
        refreshButton.addTarget(self, action: #selector(refreshFileTree), for: .touchUpInside)
        
        // Collapse all button
        let collapseButton = UIButton(type: .system)
        collapseButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        collapseButton.tintColor = CyberpunkTheme.primaryCyan
        collapseButton.addTarget(self, action: #selector(collapseAll), for: .touchUpInside)
        
        // Stack view
        let stackView = UIStackView(arrangedSubviews: [
            createButton,
            createFolderButton,
            UIView(), // Spacer
            collapseButton,
            refreshButton
        ])
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        toolbarView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            
            createButton.widthAnchor.constraint(equalToConstant: 30),
            createFolderButton.widthAnchor.constraint(equalToConstant: 30),
            refreshButton.widthAnchor.constraint(equalToConstant: 30),
            collapseButton.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    // MARK: - Data Loading
    private func loadFileTree() {
        // Mock data for demonstration
        rootNode = FileNode(
            name: project.name,
            path: project.path,
            type: FileNodeType.directory
        )
        
        // Create child nodes
        let srcNode = FileNode(name: "src", path: "\(project.path)/src", type: FileNodeType.directory)
        let modelsNode = FileNode(name: "models", path: "\(project.path)/src/models", type: FileNodeType.directory)
        modelsNode.children = [
            FileNode(name: "User.swift", path: "\(project.path)/src/models/User.swift", type: FileNodeType.file),
            FileNode(name: "Project.swift", path: "\(project.path)/src/models/Project.swift", type: FileNodeType.file)
        ]
        
        srcNode.children = [
            FileNode(name: "main.swift", path: "\(project.path)/src/main.swift", type: FileNodeType.file),
            FileNode(name: "utils.swift", path: "\(project.path)/src/utils.swift", type: FileNodeType.file),
            modelsNode
        ]
        
        let testsNode = FileNode(name: "tests", path: "\(project.path)/tests", type: FileNodeType.directory)
        testsNode.children = [
            FileNode(name: "MainTests.swift", path: "\(project.path)/tests/MainTests.swift", type: FileNodeType.file)
        ]
        
        rootNode?.children = [
            srcNode,
            testsNode,
            FileNode(name: "README.md", path: "\(project.path)/README.md", type: FileNodeType.file),
            FileNode(name: "Package.swift", path: "\(project.path)/Package.swift", type: FileNodeType.file),
            FileNode(name: ".gitignore", path: "\(project.path)/.gitignore", type: FileNodeType.file)
        ]
        rootNode?.isExpanded = true
        
        updateFlattenedNodes()
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    private func updateFlattenedNodes() {
        flattenedNodes = []
        if let root = rootNode {
            addNodeToFlatList(root, level: 0)
        }
    }
    
    private func addNodeToFlatList(_ node: FileNode, level: Int) {
        // Create a UI wrapper for the node
        let uiNode = FileNodeUI(fileNode: node, isExpanded: node.isExpanded, level: level)
        flattenedNodes.append(uiNode)
        
        if node.isExpanded && !node.children.isEmpty {
            for child in node.children {
                addNodeToFlatList(child, level: level + 1)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func refreshFileTree() {
        loadFileTree()
    }
    
    @objc private func createFile() {
        showCreateDialog(isDirectory: false)
    }
    
    @objc private func createFolder() {
        showCreateDialog(isDirectory: true)
    }
    
    @objc private func collapseAll() {
        if var root = rootNode {
            collapseNode(&root)
            rootNode = root
            updateFlattenedNodes()
            tableView.reloadData()
        }
    }
    
    private func collapseNode(_ node: inout FileNode) {
        node.isExpanded = false
        if !node.children.isEmpty {
            for i in 0..<node.children.count {
                collapseNode(&node.children[i])
            }
        }
    }
    
    private func showCreateDialog(isDirectory: Bool) {
        let title = isDirectory ? "Create Folder" : "Create File"
        let message = isDirectory ? "Enter folder name:" : "Enter file name:"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = isDirectory ? "NewFolder" : "newfile.swift"
            textField.autocapitalizationType = .none
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                self?.createFileOrFolder(name: name, isDirectory: isDirectory)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func createFileOrFolder(name: String, isDirectory: Bool) {
        // TODO: Implement actual file/folder creation via API
        // TODO: Show success message
        print("Created \(isDirectory ? "folder" : "file"): \(name)")
        refreshFileTree()
    }
    
    private func toggleNode(at index: Int) {
        guard index < flattenedNodes.count else { return }
        
        let uiNode = flattenedNodes[index]
        let newExpandedState = !uiNode.isExpanded
        
        // Update the node in the original tree
        updateNodeInTree(rootNode, targetPath: uiNode.path, isExpanded: newExpandedState)
        
        // Animate the expansion/collapse
        updateFlattenedNodes()
        
        if newExpandedState {
            // Calculate rows to insert
            var indexPaths: [IndexPath] = []
            let startIndex = index + 1
            var currentIndex = startIndex
            
            while currentIndex < flattenedNodes.count && flattenedNodes[currentIndex].level > uiNode.level {
                indexPaths.append(IndexPath(row: currentIndex, section: 0))
                currentIndex += 1
            }
            
            if !indexPaths.isEmpty {
                tableView.insertRows(at: indexPaths, with: .fade)
            }
        } else {
            // Calculate rows to delete
            var indexPaths: [IndexPath] = []
            let startIndex = index + 1
            var currentIndex = startIndex
            
            while currentIndex < flattenedNodes.count && flattenedNodes[currentIndex].level > uiNode.level {
                indexPaths.append(IndexPath(row: currentIndex, section: 0))
                currentIndex += 1
            }
            
            if !indexPaths.isEmpty {
                tableView.deleteRows(at: indexPaths, with: .fade)
            }
        }
        
        // Update the chevron rotation
        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FileTreeCell {
            UIView.animate(withDuration: 0.3) {
                cell.configure(with: uiNode, isExpanded: newExpandedState, onExpand: nil)
            }
        }
    }
    
    private func updateNodeInTree(_ node: FileNode?, targetPath: String, isExpanded: Bool) {
        guard let currentNode = node else { return }
        
        if currentNode.path == targetPath {
            currentNode.isExpanded = isExpanded
            return
        }
        
        for child in currentNode.children {
            updateNodeInTree(child, targetPath: targetPath, isExpanded: isExpanded)
        }
    }
}

// MARK: - UITableViewDataSource
extension FileTreeViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flattenedNodes.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FileTreeCell.identifier, for: indexPath) as! FileTreeCell
        let node = flattenedNodes[indexPath.row]
        
        cell.configure(with: node, isExpanded: node.isExpanded) { [weak self] in
            self?.toggleNode(at: indexPath.row)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FileTreeViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let node = flattenedNodes[indexPath.row]
        
        if node.isDirectory {
            toggleNode(at: indexPath.row)
        } else {
            // Open file viewer
            let fileViewer = FileViewerViewController(filePath: node.path, fileName: node.name)
            navigationController?.pushViewController(fileViewer, animated: true)
        }
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let node = flattenedNodes[indexPath.row]
        
        // Delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteNode(node.fileNode, completion: completion)
        }
        deleteAction.backgroundColor = CyberpunkTheme.accentPink
        deleteAction.image = UIImage(systemName: "trash")
        
        // Rename action
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] _, _, completion in
            self?.renameNode(node.fileNode)
            completion(true)
        }
        renameAction.backgroundColor = CyberpunkTheme.primaryCyan
        renameAction.image = UIImage(systemName: "pencil")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    private func deleteNode(_ node: FileNode, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Delete \(node.isDirectory ? "Folder" : "File")",
            message: "Are you sure you want to delete '\(node.name)'?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            // TODO: Implement actual deletion via API
            // TODO: Show success message
            print("Deleted: \(node.name)")
            self?.refreshFileTree()
            completion(true)
        })
        
        present(alert, animated: true)
    }
    
    private func renameNode(_ node: FileNode) {
        let alert = UIAlertController(
            title: "Rename \(node.isDirectory ? "Folder" : "File")",
            message: "Enter new name:",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.text = node.name
            textField.autocapitalizationType = .none
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                // TODO: Implement actual renaming via API
                // TODO: Show success message
                print("Renamed to: \(newName)")
                self?.refreshFileTree()
            }
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension FileTreeViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // TODO: Implement file search
        if searchText.isEmpty {
            updateFlattenedNodes()
        } else {
            // Filter nodes based on search text
            flattenedNodes = flattenedNodes.filter { node in
                node.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        tableView.reloadData()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}