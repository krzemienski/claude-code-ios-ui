//
//  SearchViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-20.
//

import UIKit

class SearchViewController: UIViewController {
    
    // MARK: - Properties
    private let project: Project?
    private let viewModel = SearchViewModel()
    
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let segmentedControl = UISegmentedControl(items: ["Files", "Code", "All"])
    private let emptyStateView = NoDataView()
    
    private var searchResults: [SearchResult] = []
    private var hasSearched = false
    
    // MARK: - Initialization
    init(project: Project? = nil) {
        self.project = project
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.project = nil
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        applyTheme()
        
        if let project = project {
            viewModel.setProject(project)
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Configure search bar
        searchBar.delegate = self
        searchBar.placeholder = "Search in \(project?.name ?? "project")..."
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure segmented control
        segmentedControl.selectedSegmentIndex = 2 // "All" by default
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchResultCell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = CyberpunkTheme.border
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        view.addSubview(searchBar)
        view.addSubview(segmentedControl)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        
        // Configure empty state
        setupEmptyState()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Search bar
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Segmented control
            segmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Empty state view
            emptyStateView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupEmptyState() {
        emptyStateView.configure(
            artStyle: .noResults,
            title: "No Results Found",
            message: "Try adjusting your search terms or filters",
            buttonTitle: nil,
            buttonAction: nil
        )
        emptyStateView.isHidden = true
    }
    
    private func updateEmptyStateVisibility() {
        let shouldShowEmpty = hasSearched && searchResults.isEmpty
        
        if shouldShowEmpty {
            tableView.isHidden = true
            emptyStateView.show(animated: true)
        } else {
            emptyStateView.hide(animated: true) { [weak self] in
                self?.tableView.isHidden = false
            }
        }
    }
    
    private func applyTheme() {
        // Apply cyberpunk theme to search bar
        searchBar.tintColor = CyberpunkTheme.primaryCyan
        searchBar.barTintColor = CyberpunkTheme.surface
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = CyberpunkTheme.textPrimary
            textField.backgroundColor = CyberpunkTheme.surface
            
            if let placeholderLabel = textField.value(forKey: "placeholderLabel") as? UILabel {
                placeholderLabel.textColor = CyberpunkTheme.textTertiary
            }
        }
        
        // Apply theme to segmented control
        segmentedControl.backgroundColor = CyberpunkTheme.surface
        segmentedControl.selectedSegmentTintColor = CyberpunkTheme.primaryCyan
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: CyberpunkTheme.textTertiary
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: CyberpunkTheme.background
        ]
        
        segmentedControl.setTitleTextAttributes(normalAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedAttributes, for: .selected)
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        let scope: SearchScope
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            scope = .files
        case 1:
            scope = .code
        default:
            scope = .all
        }
        
        viewModel.setScope(scope)
        if let searchText = searchBar.text, !searchText.isEmpty {
            performSearch(searchText)
        }
    }
    
    private func performSearch(_ query: String) {
        hasSearched = true
        viewModel.search(query: query) { [weak self] results in
            DispatchQueue.main.async {
                self?.searchResults = results
                self?.tableView.reloadData()
                self?.updateEmptyStateVisibility()
            }
        }
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults = []
            tableView.reloadData()
        } else {
            performSearch(searchText)
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath)
        let result = searchResults[indexPath.row]
        
        cell.textLabel?.text = result.fileName
        cell.detailTextLabel?.text = result.matchedLine
        
        // Apply theme
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = CyberpunkTheme.textPrimary
        cell.detailTextLabel?.textColor = CyberpunkTheme.textTertiary
        
        let selectedView = UIView()
        selectedView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.2)
        cell.selectedBackgroundView = selectedView
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let result = searchResults[indexPath.row]
        // TODO: Navigate to file at specific line
        print("Selected search result: \(result.fileName) at line \(result.lineNumber)")
    }
}

// MARK: - Search Scope
enum SearchScope {
    case files
    case code
    case all
}

// MARK: - Search Result Model
struct SearchResult {
    let fileName: String
    let filePath: String
    let lineNumber: Int
    let matchedLine: String
    let matchRange: NSRange
}