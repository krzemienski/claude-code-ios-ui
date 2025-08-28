//
//  SearchViewController.swift
//  ClaudeCodeUI
//
//  Created for Priority 1: Search Functionality
//

import UIKit

class SearchViewController: UIViewController {
    
    // MARK: - UI Components
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Properties
    private var searchResults: [SearchResult] = []
    private var searchTimer: Timer?
    private var isSearching = false
    
    // MARK: - Models
    struct SearchResult {
        let fileName: String
        let filePath: String
        let lineNumber: Int
        let lineContent: String
        let projectName: String
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        applyTheme()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Search"
        view.backgroundColor = CyberpunkTheme.background
        
        // Search Bar
        searchBar.delegate = self
        searchBar.placeholder = "Search in projects..."
        searchBar.searchBarStyle = .minimal
        searchBar.returnKeyType = .search
        
        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: "SearchResultCell")
        
        // Activity Indicator
        activityIndicator.color = CyberpunkTheme.primaryCyan
        activityIndicator.hidesWhenStopped = true
        
        // Add subviews
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
    }
    
    private func setupConstraints() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Search Bar
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func applyTheme() {
        // Apply cyberpunk theme to search bar
        searchBar.barTintColor = CyberpunkTheme.surface
        searchBar.tintColor = CyberpunkTheme.primaryCyan
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = CyberpunkTheme.textPrimary
            textField.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.3)
            
            // Style placeholder
            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: CyberpunkTheme.textTertiary
            ]
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search in projects...",
                attributes: placeholderAttributes
            )
        }
    }
    
    // MARK: - Search Methods
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            tableView.reloadData()
            return
        }
        
        // Cancel previous timer
        searchTimer?.invalidate()
        
        // Debounce search
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.executeSearch(query: query)
        }
    }
    
    private func executeSearch(query: String) {
        isSearching = true
        activityIndicator.startAnimating()
        
        // For now, we'll use mock data since backend doesn't have search yet
        // TODO: Replace with actual API call when backend implements search endpoint
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.searchResults = self?.generateMockResults(for: query) ?? []
            self?.isSearching = false
            self?.activityIndicator.stopAnimating()
            self?.tableView.reloadData()
        }
    }
    
    private func generateMockResults(for query: String) -> [SearchResult] {
        // Generate some mock search results for testing
        return [
            SearchResult(
                fileName: "AppDelegate.swift",
                filePath: "/MyProject/AppDelegate.swift",
                lineNumber: 42,
                lineContent: "func application(_ application: UIApplication, didFinishLaunchingWithOptions...",
                projectName: "MyProject"
            ),
            SearchResult(
                fileName: "ViewController.swift",
                filePath: "/MyProject/ViewController.swift",
                lineNumber: 15,
                lineContent: "class ViewController: UIViewController {",
                projectName: "MyProject"
            ),
            SearchResult(
                fileName: "NetworkManager.swift",
                filePath: "/MyProject/Managers/NetworkManager.swift",
                lineNumber: 78,
                lineContent: "func fetchData(from url: URL) async throws -> Data {",
                projectName: "MyProject"
            )
        ]
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(query: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource
extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        let result = searchResults[indexPath.row]
        cell.configure(with: result)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let result = searchResults[indexPath.row]
        // TODO: Navigate to file at specific line
        print("Selected: \(result.fileName) at line \(result.lineNumber)")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - SearchResultCell
class SearchResultCell: UITableViewCell {
    
    private let fileNameLabel = UILabel()
    private let lineContentLabel = UILabel()
    private let metadataLabel = UILabel()
    private let containerView = UIView()
    
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
        
        // Container
        containerView.backgroundColor = CyberpunkTheme.surface.withAlphaComponent(0.3)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.2).cgColor
        
        // Labels
        fileNameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        fileNameLabel.textColor = CyberpunkTheme.primaryCyan
        
        lineContentLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        lineContentLabel.textColor = CyberpunkTheme.textPrimary
        lineContentLabel.numberOfLines = 1
        
        metadataLabel.font = .systemFont(ofSize: 11, weight: .regular)
        metadataLabel.textColor = CyberpunkTheme.textTertiary
        
        // Add subviews
        contentView.addSubview(containerView)
        containerView.addSubview(fileNameLabel)
        containerView.addSubview(lineContentLabel)
        containerView.addSubview(metadataLabel)
        
        // Constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        lineContentLabel.translatesAutoresizingMaskIntoConstraints = false
        metadataLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            fileNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            fileNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            fileNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            lineContentLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 4),
            lineContentLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
            lineContentLabel.trailingAnchor.constraint(equalTo: fileNameLabel.trailingAnchor),
            
            metadataLabel.topAnchor.constraint(equalTo: lineContentLabel.bottomAnchor, constant: 4),
            metadataLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
            metadataLabel.trailingAnchor.constraint(equalTo: fileNameLabel.trailingAnchor)
        ])
    }
    
    func configure(with result: SearchViewController.SearchResult) {
        fileNameLabel.text = result.fileName
        lineContentLabel.text = result.lineContent
        metadataLabel.text = "Line \(result.lineNumber) • \(result.projectName)"
    }
}