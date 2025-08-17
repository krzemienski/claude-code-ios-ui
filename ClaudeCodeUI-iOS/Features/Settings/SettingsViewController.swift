//
//  SettingsViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

class SettingsViewController: BaseTableViewController {
    
    // MARK: - Properties
    private var sections: [SettingsSection] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        navigationItem.largeTitleDisplayMode = .always
        setupSections()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBackendURLDisplay()
        tableView.reloadData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        tableView.backgroundColor = CyberpunkTheme.background
        tableView.separatorColor = CyberpunkTheme.border
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    private func setupSections() {
        sections = [
            SettingsSection(
                title: "Connection",
                items: [
                    SettingsItem(
                        title: "Backend URL",
                        value: AppConfig.backendURL,
                        action: { [weak self] in
                            self?.showBackendURLEditor()
                        }
                    ),
                    SettingsItem(
                        title: "Test Connection",
                        value: nil,
                        action: { [weak self] in
                            self?.testBackendConnection()
                        }
                    )
                ]
            ),
            SettingsSection(
                title: "MCP Servers",
                items: [
                    SettingsItem(
                        title: "Manage MCP Servers",
                        value: nil,
                        action: { [weak self] in
                            let mcpVC = MCPServerListViewController()
                            self?.navigationController?.pushViewController(mcpVC, animated: true)
                        }
                    )
                ]
            ),
            SettingsSection(
                title: "Display",
                items: [
                    SettingsItem(
                        title: "Theme",
                        value: "Cyberpunk",
                        action: nil
                    ),
                    SettingsItem(
                        title: "Haptic Feedback",
                        value: AppConfig.enableHapticFeedback ? "On" : "Off",
                        action: nil
                    )
                ]
            ),
            SettingsSection(
                title: "Developer",
                items: [
                    SettingsItem(
                        title: "Integration Tests",
                        value: "Run Tests",
                        action: { [weak self] in
                            self?.showTestRunner()
                        }
                    ),
                    SettingsItem(
                        title: "Debug Mode",
                        value: AppConfig.isDebugMode ? "On" : "Off",
                        action: nil
                    )
                ]
            ),
            SettingsSection(
                title: "About",
                items: [
                    SettingsItem(
                        title: "Version",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                        action: nil
                    ),
                    SettingsItem(
                        title: "Build",
                        value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
                        action: nil
                    )
                ]
            )
        ]
    }
    
    // MARK: - Actions
    private func showBackendURLEditor() {
        let alert = UIAlertController(
            title: "Backend URL",
            message: "Enter the URL of your Claude Code backend server\n\nFor simulator: http://localhost:3002\nFor device: http://YOUR_IP:3002",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.text = AppConfig.backendURL
            textField.placeholder = "http://localhost:3002"
            textField.keyboardType = .URL
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let url = alert.textFields?.first?.text, !url.isEmpty {
                AppConfig.updateBackendURL(url)
                self?.updateBackendURLDisplay()
                self?.tableView.reloadData()
                
                // Show success message
                let successAlert = UIAlertController(
                    title: "Success",
                    message: "Backend URL updated",
                    preferredStyle: .alert
                )
                successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(successAlert, animated: true)
            }
        }
        
        let resetAction = UIAlertAction(title: "Reset to Default", style: .destructive) { [weak self] _ in
            AppConfig.resetBackendURL()
            self?.updateBackendURLDisplay()
            self?.tableView.reloadData()
        }
        
        alert.addAction(saveAction)
        alert.addAction(resetAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func testBackendConnection() {
        let url = URL(string: "\(AppConfig.backendURL)/api/projects")!
        
        // Show loading indicator
        let alert = UIAlertController(
            title: "Testing Connection",
            message: "\n\nConnecting to:\n\(AppConfig.backendURL)",
            preferredStyle: .alert
        )
        
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingIndicator.color = CyberpunkTheme.primaryCyan
        alert.view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 65)
        ])
        
        present(alert, animated: true)
        
        // Test connection
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                alert.dismiss(animated: true) {
                    if let error = error {
                        self?.showConnectionResult(
                            success: false,
                            message: "Connection failed:\n\(error.localizedDescription)\n\nMake sure the backend server is running."
                        )
                    } else if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            // Try to parse projects
                            var projectCount = 0
                            if let data = data,
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let projects = json["projects"] as? [[String: Any]] {
                                projectCount = projects.count
                            }
                            
                            self?.showConnectionResult(
                                success: true,
                                message: "Successfully connected!\n\nFound \(projectCount) project(s)"
                            )
                        } else {
                            self?.showConnectionResult(
                                success: false,
                                message: "Server returned status: \(httpResponse.statusCode)\n\nCheck if the correct backend is running."
                            )
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    private func showConnectionResult(success: Bool, message: String) {
        let alert = UIAlertController(
            title: success ? "✅ Connection Successful" : "❌ Connection Failed",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Generate haptic feedback
        if AppConfig.enableHapticFeedback {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(success ? .success : .error)
        }
    }
    
    private func updateBackendURLDisplay() {
        if let connectionSection = sections.first(where: { $0.title == "Connection" }),
           let urlItem = connectionSection.items.first(where: { $0.title == "Backend URL" }) {
            urlItem.value = AppConfig.backendURL
        }
    }
    
    // MARK: - Test Runner
    private func showTestRunner() {
        TestRunnerViewController.present(from: self)
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = CyberpunkTheme.cardBackground
        cell.textLabel?.text = item.title
        cell.textLabel?.textColor = CyberpunkTheme.textPrimary
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        
        if let value = item.value {
            cell.detailTextLabel?.text = value
            cell.detailTextLabel?.textColor = CyberpunkTheme.primaryCyan
            cell.detailTextLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        }
        
        if item.action != nil {
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        } else {
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }
        
        // Add subtle glow for actionable items
        if item.action != nil {
            let selectedBackground = UIView()
            selectedBackground.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.1)
            cell.selectedBackgroundView = selectedBackground
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title.uppercased()
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = sections[indexPath.section].items[indexPath.row]
        item.action?()
        
        // Haptic feedback for taps
        if AppConfig.enableHapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = CyberpunkTheme.textSecondary
            header.textLabel?.font = .systemFont(ofSize: 13, weight: .bold)
            header.contentView.backgroundColor = CyberpunkTheme.background
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

// MARK: - Settings Models
private class SettingsSection {
    let title: String
    var items: [SettingsItem]
    
    init(title: String, items: [SettingsItem]) {
        self.title = title
        self.items = items
    }
}

private class SettingsItem {
    let title: String
    var value: String?
    let action: (() -> Void)?
    
    init(title: String, value: String?, action: (() -> Void)?) {
        self.title = title
        self.value = value
        self.action = action
    }
}