//
//  ViewControllers.swift
//  ClaudeCodeUI
//
//  Temporary wrapper to include view controllers that aren't in the project file
//

// Include the actual view controller files
#if swift(>=5.0)

// Include ProjectsViewController
#sourceLocation(file: "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Features/Projects/ProjectsViewController.swift", line: 1)
// Note: In a proper setup, these files would be added to the Xcode project
// For now, we'll create simplified versions inline

import UIKit
import SwiftData

// Simplified ProjectsViewController for testing
class ProjectsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CyberpunkTheme.background
        title = "Projects"
        
        // Create a simple test UI
        let label = UILabel()
        label.text = "Projects Screen (Test)"
        label.textColor = CyberpunkTheme.primaryCyan
        label.font = CyberpunkTheme.titleFont
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Test API connection
        testAPIConnection()
    }
    
    private func testAPIConnection() {
        Task {
            do {
                let apiClient = APIClient(baseURL: AppConfig.backendURL)
                print("🔧 Testing API connection to: \(AppConfig.backendURL)")
                
                let projects = try await apiClient.fetchProjects()
                print("✅ Successfully fetched \(projects.count) projects")
                
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "API Test",
                        message: "Fetched \(projects.count) projects successfully!",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            } catch {
                print("❌ API test failed: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "API Error",
                        message: "Failed: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// Simplified SettingsViewController for testing  
class SettingsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CyberpunkTheme.background
        title = "Settings"
        
        let label = UILabel()
        label.text = "Settings Screen (Test)"
        label.textColor = CyberpunkTheme.primaryCyan
        label.font = CyberpunkTheme.titleFont
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// Simplified ChatViewController for testing
class ChatViewController: UIViewController {
    private let project: Project?
    
    init(project: Project? = nil) {
        self.project = project
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CyberpunkTheme.background
        title = project?.displayName ?? "Chat"
        
        let label = UILabel()
        label.text = "Chat Screen (Test)"
        label.textColor = CyberpunkTheme.primaryCyan
        label.font = CyberpunkTheme.titleFont
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

#endif