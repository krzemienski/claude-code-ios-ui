//
//  SettingsViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

public class SettingsViewController: BaseTableViewController {
    
    // MARK: - Properties
    private var sections: [SettingsSection] = []
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        navigationItem.largeTitleDisplayMode = .always
        setupSections()
        setupUI()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
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
                        action: { [weak self] in
                            self?.toggleHapticFeedback()
                        }
                    ),
                    SettingsItem(
                        title: "Code Font Size",
                        value: "\(Int(AppConfig.codeFontSize))pt",
                        action: { [weak self] in
                            self?.showFontSizeSelector()
                        }
                    )
                ]
            ),
            SettingsSection(
                title: "Data & Storage",
                items: [
                    SettingsItem(
                        title: "Clear Cache",
                        value: nil,
                        action: { [weak self] in
                            self?.clearCache()
                        }
                    ),
                    SettingsItem(
                        title: "Export Settings",
                        value: nil,
                        action: { [weak self] in
                            self?.exportSettings()
                        }
                    ),
                    SettingsItem(
                        title: "Import Settings",
                        value: nil,
                        action: { [weak self] in
                            self?.importSettings()
                        }
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
            if let urlString = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), 
               !urlString.isEmpty {
                // Validate URL format
                if self?.validateURL(urlString) == true {
                    AppConfig.updateBackendURL(urlString)
                    self?.updateBackendURLDisplay()
                    self?.tableView.reloadData()
                    
                    // Show success with haptic feedback
                    if AppConfig.enableHapticFeedback {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                    
                    // Brief success notification
                    let successView = UIView(frame: CGRect(x: 0, y: -60, width: self?.view.bounds.width ?? 0, height: 60))
                    successView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.9)
                    
                    let label = UILabel(frame: successView.bounds)
                    label.text = "✅ Backend URL Updated"
                    label.textColor = .black
                    label.textAlignment = .center
                    label.font = .systemFont(ofSize: 16, weight: .semibold)
                    successView.addSubview(label)
                    
                    self?.view.addSubview(successView)
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        successView.frame.origin.y = 0
                    }) { _ in
                        UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: {
                            successView.frame.origin.y = -60
                        }) { _ in
                            successView.removeFromSuperview()
                        }
                    }
                } else {
                    // Show validation error using ErrorAlertView
                    self?.showValidationError(message: "Invalid URL format. Please enter a valid URL starting with http:// or https://")
                }
            } else {
                // Show empty field error
                self?.showValidationError(message: "URL cannot be empty. Please enter a valid backend URL.")
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
    
    private func validateURL(_ urlString: String) -> Bool {
        // Check if URL starts with http:// or https://
        guard urlString.lowercased().hasPrefix("http://") || urlString.lowercased().hasPrefix("https://") else {
            return false
        }
        
        // Check if URL can be parsed
        guard let url = URL(string: urlString) else {
            return false
        }
        
        // Check if URL has a host
        guard url.host != nil else {
            return false
        }
        
        return true
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
        if success {
            // Show success notification with animation
            let successView = UIView(frame: CGRect(x: 0, y: -100, width: view.bounds.width, height: 100))
            successView.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.95)
            
            let iconLabel = UILabel(frame: CGRect(x: 0, y: 20, width: view.bounds.width, height: 30))
            iconLabel.text = "✅"
            iconLabel.textAlignment = .center
            iconLabel.font = .systemFont(ofSize: 28)
            successView.addSubview(iconLabel)
            
            let messageLabel = UILabel(frame: CGRect(x: 20, y: 50, width: view.bounds.width - 40, height: 40))
            messageLabel.text = message
            messageLabel.textColor = .black
            messageLabel.textAlignment = .center
            messageLabel.font = .systemFont(ofSize: 14, weight: .medium)
            messageLabel.numberOfLines = 2
            successView.addSubview(messageLabel)
            
            view.addSubview(successView)
            
            // Animate in
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                successView.frame.origin.y = 0
            }) { _ in
                // Animate out after delay
                UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseIn, animations: {
                    successView.frame.origin.y = -100
                }) { _ in
                    successView.removeFromSuperview()
                }
            }
            
            // Haptic feedback
            if AppConfig.enableHapticFeedback {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } else {
            // Show error using ErrorAlertView with retry option
            showNetworkError(
                message: message,
                retryAction: { [weak self] in
                    self?.testBackendConnection()
                }
            )
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
    
    // MARK: - Display Settings
    private func toggleHapticFeedback() {
        AppConfig.enableHapticFeedback.toggle()
        UserDefaults.standard.set(AppConfig.enableHapticFeedback, forKey: "enableHapticFeedback")
        
        // Update the display
        if let displaySection = sections.first(where: { $0.title == "Display" }),
           let hapticItem = displaySection.items.first(where: { $0.title == "Haptic Feedback" }) {
            hapticItem.value = AppConfig.enableHapticFeedback ? "On" : "Off"
        }
        tableView.reloadData()
        
        // Give feedback for the change
        if AppConfig.enableHapticFeedback {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func showFontSizeSelector() {
        let alert = UIAlertController(
            title: "Code Font Size",
            message: "Select the font size for code display",
            preferredStyle: .actionSheet
        )
        
        let sizes: [CGFloat] = [10, 12, 14, 16, 18, 20]
        for size in sizes {
            let action = UIAlertAction(title: "\(Int(size))pt", style: .default) { [weak self] _ in
                AppConfig.codeFontSize = size
                UserDefaults.standard.set(size, forKey: "codeFontSize")
                
                // Update display
                if let displaySection = self?.sections.first(where: { $0.title == "Display" }),
                   let fontItem = displaySection.items.first(where: { $0.title == "Code Font Size" }) {
                    fontItem.value = "\(Int(size))pt"
                }
                self?.tableView.reloadData()
            }
            
            if size == AppConfig.codeFontSize {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Data & Storage
    private func clearCache() {
        let alert = UIAlertController(
            title: "Clear Cache",
            message: "This will clear all cached data. Are you sure?",
            preferredStyle: .alert
        )
        
        let clearAction = UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            // Clear URLCache
            URLCache.shared.removeAllCachedResponses()
            
            // Clear image cache if using one
            // Clear any other app-specific caches
            
            // Show loading indicator
            self?.showLoading(message: "Clearing cache...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.hideLoading()
                
                let successAlert = UIAlertController(
                    title: "Success",
                    message: "Cache cleared successfully",
                    preferredStyle: .alert
                )
                successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(successAlert, animated: true)
                
                // Haptic feedback
                if AppConfig.enableHapticFeedback {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
        
        alert.addAction(clearAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func exportSettings() {
        // Create settings dictionary
        let settings: [String: Any] = [
            "backendURL": AppConfig.backendURL,
            "enableHapticFeedback": AppConfig.enableHapticFeedback,
            "codeFontSize": AppConfig.codeFontSize,
            "isDebugMode": AppConfig.isDebugMode,
            "exportDate": Date().timeIntervalSince1970,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
            
            // Create activity controller
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsPath.appendingPathComponent("claude-code-settings.json")
            try jsonData.write(to: fileURL)
            
            let activityController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // For iPad
            if let popover = activityController.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            present(activityController, animated: true)
        } catch {
            showError("Failed to export settings: \(error.localizedDescription)")
        }
    }
    
    private func importSettings() {
        let alert = UIAlertController(
            title: "Import Settings",
            message: "This feature will import settings from a JSON file. Coming soon!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // TODO: Implement document picker for importing settings
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
}

// MARK: - UITableViewDataSource
extension SettingsViewController {
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title.uppercased()
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController {
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = sections[indexPath.section].items[indexPath.row]
        item.action?()
        
        // Haptic feedback for taps
        if AppConfig.enableHapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    public override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = CyberpunkTheme.textSecondary
            header.textLabel?.font = .systemFont(ofSize: 13, weight: .bold)
            header.contentView.backgroundColor = CyberpunkTheme.background
        }
    }
    
    public override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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