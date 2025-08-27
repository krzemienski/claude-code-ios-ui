//
//  ViewControllers.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit
import SwiftData

// CyberpunkTheme is now imported from Design/Theme/CyberpunkTheme.swift

// Simple implementations for missing components
// GridBackgroundView is defined in Design/Components/GridBackgroundView.swift

class SimpleBaseViewController: UIViewController {
    lazy var gridBackgroundView = GridBackgroundView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CyberpunkTheme.background
        view.insertSubview(gridBackgroundView, at: 0)
        gridBackgroundView.frame = view.bounds
        gridBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// Project model is now imported from Core/Data/Models/Project.swift
// DIContainer is now imported from Core/Services/DIContainer.swift

// Simple API Client stub - renamed to avoid conflict with the real APIClient in Core/Network/APIClient.swift
class SimpleAPIClient {
    var baseURL = "http://192.168.0.43:3004"  // Fixed for iOS simulator
    private var authToken: String?
    
    init(baseURL: String = "http://192.168.0.43:3004") {
        self.baseURL = baseURL
        // Retrieve saved token from UserDefaults
        self.authToken = UserDefaults.standard.string(forKey: "authToken")
    }
    
    func authenticate(username: String, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/auth/login") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["username": username, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["token"] as? String {
            self.authToken = token
            // Store token in UserDefaults for WebSocket connection
            UserDefaults.standard.set(token, forKey: "authToken")
        } else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get authentication token"])
        }
    }
    
    func fetchProjects() async throws -> [Project] {
        guard let url = URL(string: "\(baseURL)/api/projects") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let projects = try JSONDecoder().decode([Project].self, from: data)
        return projects
    }
    
    func createProject(name: String, path: String) async throws -> Project {
        guard let url = URL(string: "\(baseURL)/api/projects") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["name": name, "path": path]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let project = try JSONDecoder().decode(Project.self, from: data)
        return project
    }
    
    func deleteProject(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/projects/\(id)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        _ = try await URLSession.shared.data(for: request)
    }
}

// Simple Error Handler
// ErrorHandlingService is now imported from Core/Services/ErrorHandlingService.swift

// Logger is now imported from Core/Services/Logger.swift

// Simple AppConfig - Commented out to avoid conflict with the real AppConfig in Core/Config/AppConfig.swift
// struct AppConfig {
//     static let backendURL = "http://localhost:3004"
// }

// SwiftDataContainer is now imported from Core/Data/SwiftDataContainer.swift
// Settings model is now imported from Models/Settings.swift

// ProjectCard is defined in UI/Components/ProjectCard.swift

// These are simple references to the real view controllers in Features folder
// They act as bridges to ensure the app compiles

// Projects View Controller - Now with basic functionality
// ProjectsViewController is defined in Features/Projects/ProjectsViewController.swift
// Removed duplicate stub implementation to use the proper one with skeleton loading

// Chat View Controller - Using the real implementation from Features/Chat/ChatViewController.swift

// File Explorer View Controller
// FileExplorerViewController is defined in Features/FileExplorer/FileExplorerViewController.swift

// Terminal View Controller
// TerminalViewController is defined in Features/Terminal/TerminalViewController.swift

// SettingsViewController is defined in Features/Settings/SettingsViewController.swift

// Authentication View Controller
// AuthenticationViewController is defined in Features/Authentication/AuthenticationViewController.swift

// Launch View Controller
// LaunchViewController is defined in Features/Launch/LaunchViewController.swift

// MainTabBarController - Using the real implementation from Core/Navigation/MainTabBarController.swift