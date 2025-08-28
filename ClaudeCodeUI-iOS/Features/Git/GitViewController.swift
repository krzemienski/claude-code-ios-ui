//
//  GitViewController.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import UIKit

class GitViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: GitViewModel
    private let project: Project?
    private var refreshControl: UIRefreshControl?
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = CyberpunkTheme.background
        table.separatorStyle = .none
        table.delegate = self
        table.dataSource = self
        table.register(GitStatusCell.self, forCellReuseIdentifier: "GitStatusCell")
        table.register(GitBranchCell.self, forCellReuseIdentifier: "GitBranchCell")
        table.register(GitCommitCell.self, forCellReuseIdentifier: "GitCommitCell")
        return table
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Status", "Branches", "History"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.tintColor = CyberpunkTheme.primaryCyan
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return control
    }()
    
    private lazy var commitButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Commit", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = CyberpunkTheme.primaryCyan
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(commitTapped), for: .touchUpInside)
        
        // Add glow effect
        button.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.6
        button.layer.shadowOffset = .zero
        
        return button
    }()
    
    private lazy var loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = CyberpunkTheme.primaryCyan
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Initialization
    
    init(project: Project? = nil) {
        self.project = project
        self.viewModel = GitViewModel(project: project)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.project = nil
        self.viewModel = GitViewModel(project: nil)
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupRefreshControl()
        bindViewModel()
        loadInitialData()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(commitButton)
        view.addSubview(loadingView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: commitButton.topAnchor, constant: -16),
            
            commitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            commitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            commitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            commitButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = "Git"
        navigationItem.titleView = segmentedControl
        
        // Add action buttons
        let pullButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.down.circle"),
            style: .plain,
            target: self,
            action: #selector(pullTapped)
        )
        pullButton.tintColor = CyberpunkTheme.primaryCyan
        
        let pushButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.circle"),
            style: .plain,
            target: self,
            action: #selector(pushTapped)
        )
        pushButton.tintColor = CyberpunkTheme.primaryCyan
        
        navigationItem.rightBarButtonItems = [pushButton, pullButton]
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = CyberpunkTheme.primaryCyan
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    // MARK: - View Model Binding
    
    private func bindViewModel() {
        viewModel.onStatusUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.hideSkeletonLoading()
                self?.tableView.reloadData()
                self?.updateCommitButton()
            }
        }
        
        viewModel.onBranchesUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.hideSkeletonLoading()
                self?.tableView.reloadData()
            }
        }
        
        viewModel.onCommitsUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.hideSkeletonLoading()
                self?.tableView.reloadData()
            }
        }
        
        viewModel.onLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    // Show skeleton loading instead of just spinner
                    self?.tableView.showSkeletonLoading(count: 8, cellHeight: 70)
                    self?.loadingView.startAnimating()
                } else {
                    self?.tableView.hideSkeletonLoading()
                    self?.loadingView.stopAnimating()
                    self?.refreshControl?.endRefreshing()
                }
            }
        }
        
        viewModel.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.showError(error)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            viewModel.loadStatus()
        case 1:
            viewModel.loadBranches()
        case 2:
            viewModel.loadCommits()
        default:
            break
        }
    }
    
    @objc private func refreshData() {
        loadInitialData()
    }
    
    // MARK: - Actions
    
    @objc private func segmentChanged() {
        loadInitialData()
    }
    
    @objc private func commitTapped() {
        showCommitDialog()
    }
    
    @objc private func pullTapped() {
        viewModel.pull { [weak self] success in
            if success {
                self?.showSuccess("Pull completed successfully")
                self?.loadInitialData()
            }
        }
    }
    
    @objc private func pushTapped() {
        viewModel.push { [weak self] success in
            if success {
                self?.showSuccess("Push completed successfully")
            }
        }
    }
    
    // MARK: - UI Updates
    
    private func updateCommitButton() {
        let hasChanges = viewModel.hasChangesToCommit()
        commitButton.isEnabled = hasChanges
        commitButton.alpha = hasChanges ? 1.0 : 0.5
    }
    
    private func showCommitDialog() {
        let alert = UIAlertController(title: "Commit Changes", message: "Enter commit message", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Commit message"
            textField.autocapitalizationType = .sentences
        }
        
        let commitAction = UIAlertAction(title: "Commit", style: .default) { [weak self] _ in
            guard let message = alert.textFields?.first?.text, !message.isEmpty else {
                self?.showError("Commit message cannot be empty")
                return
            }
            
            self?.viewModel.commit(message: message) { success in
                if success {
                    self?.showSuccess("Changes committed successfully")
                    self?.loadInitialData()
                }
            }
        }
        commitAction.setValue(CyberpunkTheme.primaryCyan, forKey: "titleTextColor")
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(CyberpunkTheme.secondaryText, forKey: "titleTextColor")
        
        alert.addAction(commitAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension GitViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // Status
            return viewModel.statusSections.count
        case 1: // Branches
            return 1
        case 2: // History
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // Status
            return viewModel.statusSections[section].files.count
        case 1: // Branches
            return viewModel.branches.count
        case 2: // History
            return viewModel.commits.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // Status
            return viewModel.statusSections[section].title
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // Status
            let cell = tableView.dequeueReusableCell(withIdentifier: "GitStatusCell", for: indexPath) as! GitStatusCell
            let file = viewModel.statusSections[indexPath.section].files[indexPath.row]
            cell.configure(with: file)
            return cell
            
        case 1: // Branches
            let cell = tableView.dequeueReusableCell(withIdentifier: "GitBranchCell", for: indexPath) as! GitBranchCell
            let branch = viewModel.branches[indexPath.row]
            cell.configure(with: branch, isCurrent: branch.name == viewModel.currentBranch)
            return cell
            
        case 2: // History
            let cell = tableView.dequeueReusableCell(withIdentifier: "GitCommitCell", for: indexPath) as! GitCommitCell
            let commit = viewModel.commits[indexPath.row]
            cell.configure(with: commit)
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate

extension GitViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch segmentedControl.selectedSegmentIndex {
        case 0: // Status - Stage/unstage file
            let file = viewModel.statusSections[indexPath.section].files[indexPath.row]
            if file.isStaged {
                viewModel.unstageFile(file.path)
            } else {
                viewModel.stageFile(file.path)
            }
            
        case 1: // Branches - Switch branch
            let branch = viewModel.branches[indexPath.row]
            if branch.name != viewModel.currentBranch {
                viewModel.checkoutBranch(branch.name) { [weak self] success in
                    if success {
                        self?.showSuccess("Switched to branch \(branch.name)")
                        self?.loadInitialData()
                    }
                }
            }
            
        case 2: // History - Show commit details
            let commit = viewModel.commits[indexPath.row]
            showCommitDetails(commit)
            
        default:
            break
        }
    }
    
    private func showCommitDetails(_ commit: GitCommit) {
        let alert = UIAlertController(
            title: commit.sha.prefix(7).description,
            message: """
            \(commit.message)
            
            Author: \(commit.author)
            Date: \(commit.date)
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Custom Cell Classes

class GitStatusCell: UITableViewCell {
    
    private let fileLabel = UILabel()
    private let statusLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = CyberpunkTheme.surface
        
        fileLabel.translatesAutoresizingMaskIntoConstraints = false
        fileLabel.font = .systemFont(ofSize: 14)
        fileLabel.textColor = CyberpunkTheme.primaryText
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 12)
        
        contentView.addSubview(fileLabel)
        contentView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            fileLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fileLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            fileLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),
            
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with file: GitFile) {
        fileLabel.text = file.path
        statusLabel.text = file.status
        
        switch file.status {
        case "modified":
            statusLabel.textColor = CyberpunkTheme.warning
        case "added":
            statusLabel.textColor = CyberpunkTheme.success
        case "deleted":
            statusLabel.textColor = CyberpunkTheme.accentPink
        default:
            statusLabel.textColor = CyberpunkTheme.secondaryText
        }
    }
}

class GitBranchCell: UITableViewCell {
    
    private let branchLabel = UILabel()
    private let checkmark = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = CyberpunkTheme.surface
        
        branchLabel.translatesAutoresizingMaskIntoConstraints = false
        branchLabel.font = .systemFont(ofSize: 14)
        branchLabel.textColor = CyberpunkTheme.primaryText
        
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        checkmark.image = UIImage(systemName: "checkmark.circle.fill")
        checkmark.tintColor = CyberpunkTheme.primaryCyan
        
        contentView.addSubview(branchLabel)
        contentView.addSubview(checkmark)
        
        NSLayoutConstraint.activate([
            branchLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            branchLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            branchLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkmark.leadingAnchor, constant: -8),
            
            checkmark.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmark.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 20),
            checkmark.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with branch: GitBranch, isCurrent: Bool) {
        branchLabel.text = branch.name
        checkmark.isHidden = !isCurrent
        
        if isCurrent {
            branchLabel.font = .systemFont(ofSize: 14, weight: .semibold)
            branchLabel.textColor = CyberpunkTheme.primaryCyan
        } else {
            branchLabel.font = .systemFont(ofSize: 14)
            branchLabel.textColor = CyberpunkTheme.primaryText
        }
    }
}

class GitCommitCell: UITableViewCell {
    
    private let messageLabel = UILabel()
    private let authorLabel = UILabel()
    private let shaLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = CyberpunkTheme.surface
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = CyberpunkTheme.primaryText
        messageLabel.numberOfLines = 2
        
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        authorLabel.font = .systemFont(ofSize: 12)
        authorLabel.textColor = CyberpunkTheme.secondaryText
        
        shaLabel.translatesAutoresizingMaskIntoConstraints = false
        shaLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        shaLabel.textColor = CyberpunkTheme.primaryCyan
        
        contentView.addSubview(messageLabel)
        contentView.addSubview(authorLabel)
        contentView.addSubview(shaLabel)
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            authorLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            authorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            authorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            shaLabel.centerYAnchor.constraint(equalTo: authorLabel.centerYAnchor),
            shaLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with commit: GitCommit) {
        messageLabel.text = commit.message
        authorLabel.text = commit.author
        shaLabel.text = String(commit.sha.prefix(7))
    }
}