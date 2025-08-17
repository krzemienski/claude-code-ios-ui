//
//  ViewControllers.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit
import SwiftData

// Import required components
struct CyberpunkTheme {
    static let background = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
    static let surface = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
    static let primaryCyan = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1.0)
    static let primaryPink = UIColor(red: 1, green: 0, blue: 0.43, alpha: 1.0)
    static let primaryText = UIColor.white
    static let secondaryText = UIColor(white: 0.7, alpha: 1.0)
    static let border = UIColor(white: 0.3, alpha: 1.0)
    static let surfaceSecondary = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
    static let textPrimary = UIColor.white
    static let textTertiary = UIColor(white: 0.5, alpha: 1.0)
    
    static let headingFont = UIFont.systemFont(ofSize: 18, weight: .bold)
    static let bodyFont = UIFont.systemFont(ofSize: 16, weight: .regular)
    static let codeFont = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    static let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
}

// Simple implementations for missing components
class GridBackgroundView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0).withAlphaComponent(0.3)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BaseViewController: UIViewController {
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

// Model classes
class Project: Codable {
    let id: String
    let name: String
    let path: String
    let updatedAt: Date
    var displayName: String { return name }
    
    init(name: String, path: String) {
        self.id = UUID().uuidString
        self.name = name
        self.path = path
        self.updatedAt = Date()
    }
}

// Simple DIContainer
class DIContainer {
    static let shared = DIContainer()
    let apiClient = APIClient()
    let errorHandler = ErrorHandlingService()
}

// Real API Client with Backend Connectivity
class APIClient {
    var baseURL = "http://localhost:3004"
    private var authToken: String?
    
    init(baseURL: String = "http://localhost:3004") {
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
class ErrorHandlingService {
    static let shared = ErrorHandlingService()
    
    func handle(_ error: Error, context: String, retryAction: (() -> Void)? = nil) {
        print("Error in \(context): \(error)")
    }
}

// Simple Logger
class Logger {
    static let shared = Logger()
    
    func error(_ message: String) {
        print("ERROR: \(message)")
    }
}

// Simple AppConfig
struct AppConfig {
    static let backendURL = "http://localhost:3004"
}

// Simple SwiftDataContainer
class SwiftDataContainer {
    static let shared = SwiftDataContainer()
    
    func fetchProjects() async throws -> [Project] {
        return []
    }
    
    func fetchSettings() async throws -> Settings {
        return Settings()
    }
    
    func saveProject(_ project: Project) async throws {
        // No-op
    }
    
    func deleteProject(_ project: Project) async throws {
        // No-op
    }
}

class Settings {
    var apiBaseURL = "http://localhost:3004"
}

// Simple ProjectCard component
class ProjectCard: UIView {
    func configure(with project: Project) {
        // Basic configuration
    }
}

// These are simple references to the real view controllers in Features folder
// They act as bridges to ensure the app compiles

// Projects View Controller - Now with basic functionality
public class ProjectsViewController: BaseViewController {
    private var projects: [Project] = []
    private let tableView = UITableView()
    
    // Callback for project selection to avoid circular dependencies
    public var onProjectSelected: ((Project) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Projects"
        setupUI()
        loadProjects()
    }
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Setup table view
        tableView.backgroundColor = CyberpunkTheme.background
        tableView.separatorColor = CyberpunkTheme.border
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProjectCell")
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add create button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(createProject)
        )
        navigationItem.rightBarButtonItem?.tintColor = CyberpunkTheme.primaryCyan
    }
    
    private func loadProjects() {
        // Load real projects from backend
        Task {
            do {
                let apiClient = APIClient(baseURL: "http://localhost:3004")
                let fetchedProjects = try await apiClient.fetchProjects()
                await MainActor.run {
                    self.projects = fetchedProjects
                    self.tableView.reloadData()
                }
            } catch {
                print("Failed to load projects from backend: \(error)")
                // Show error to user
                await MainActor.run {
                    let alert = UIAlertController(title: "Connection Error", 
                                                 message: "Could not connect to backend at localhost:3004. Please ensure the server is running.", 
                                                 preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func createProject() {
        let alert = UIAlertController(title: "New Project", message: "Enter project details", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Project Name"
        }
        alert.addTextField { textField in
            textField.placeholder = "Project Path"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let path = alert.textFields?[1].text, !path.isEmpty else { return }
            
            // Create project via backend API
            Task {
                do {
                    let apiClient = APIClient(baseURL: "http://localhost:3004")
                    let newProject = try await apiClient.createProject(name: name, path: path)
                    await MainActor.run {
                        self?.projects.append(newProject)
                        self?.tableView.reloadData()
                    }
                } catch {
                    print("Failed to create project: \(error)")
                    await MainActor.run {
                        let errorAlert = UIAlertController(title: "Error", 
                                                          message: "Failed to create project. Please check backend connection.", 
                                                          preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(errorAlert, animated: true)
                    }
                }
            }
        }
        
        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension ProjectsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath)
        let project = projects[indexPath.row]
        cell.textLabel?.text = project.name
        cell.textLabel?.textColor = CyberpunkTheme.primaryText
        cell.backgroundColor = CyberpunkTheme.surface
        cell.selectionStyle = .blue
        return cell
    }
}

extension ProjectsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let project = projects[indexPath.row]
        // Use the callback if available, otherwise navigate directly
        if let onProjectSelected = onProjectSelected {
            onProjectSelected(project)
        } else {
            // Fallback: Navigate to sessions list directly
            let sessionsVC = SessionsViewController(project: project)
            navigationController?.pushViewController(sessionsVC, animated: true)
        }
    }
}

// SessionsViewController is defined in Features/Sessions/SessionsViewController.swift
// No need for a stub here

// Chat View Controller with Real WebSocket Connection
public class ChatViewController: UIViewController {
    var project: Any?
    private let textView = UITextView()
    private let inputField = UITextField()
    private var webSocketTask: URLSessionWebSocketTask?
    
    init(project: Any?) {
        self.project = project
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        title = "Chat"
        setupUI()
        connectWebSocket()
    }
    
    private func setupUI() {
        // Setup text view for chat
        textView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.isEditable = false
        textView.text = "Connecting to backend at localhost:3004...\n\n"
        
        // Setup input field
        inputField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        inputField.textColor = .white
        inputField.placeholder = "Type a message..."
        inputField.borderStyle = .roundedRect
        inputField.addTarget(self, action: #selector(sendMessage), for: .editingDidEndOnExit)
        
        view.addSubview(textView)
        view.addSubview(inputField)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        inputField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: inputField.topAnchor, constant: -16),
            
            inputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inputField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            inputField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            inputField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func connectWebSocket() {
        guard let url = URL(string: "ws://localhost:3004/ws") else { return }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        textView.text += "Connected to WebSocket!\n\n"
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    // Parse JSON response from backend
                    if let data = text.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        
                        let type = json["type"] as? String ?? ""
                        
                        DispatchQueue.main.async {
                            switch type {
                            case "claude-output":
                                // Streaming output from Claude
                                if let content = json["content"] as? String {
                                    self?.textView.text += content
                                }
                            case "claude-response":
                                // Complete response from Claude
                                if let content = json["content"] as? String {
                                    self?.textView.text += "\nClaude: \(content)\n\n"
                                }
                            case "session-created":
                                // Store session ID when created
                                if let sessionId = json["sessionId"] as? String,
                                   let projectPath = json["projectPath"] as? String {
                                    UserDefaults.standard.set(sessionId, forKey: "currentSessionId_\(projectPath)")
                                    self?.textView.text += "✅ Session created: \(sessionId)\n"
                                }
                            case "session-aborted":
                                self?.textView.text += "❌ Session aborted\n"
                                if let projectPath = json["projectPath"] as? String {
                                    UserDefaults.standard.removeObject(forKey: "currentSessionId_\(projectPath)")
                                }
                            case "error":
                                if let error = json["error"] as? String {
                                    self?.textView.text += "⚠️ Error: \(error)\n\n"
                                }
                            case "projects-update":
                                self?.textView.text += "📁 Projects updated\n"
                            default:
                                // Raw text fallback
                                self?.textView.text += "Server: \(text)\n"
                            }
                        }
                    } else {
                        // Fallback for non-JSON messages
                        DispatchQueue.main.async {
                            self?.textView.text += "Server: \(text)\n"
                        }
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self?.textView.text += "Server: \(text)\n"
                        }
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage() // Continue listening
            case .failure(let error):
                print("WebSocket error: \(error)")
                DispatchQueue.main.async {
                    self?.textView.text += "WebSocket disconnected. Error: \(error.localizedDescription)\n\n"
                }
            }
        }
    }
    
    @objc private func sendMessage() {
        guard let text = inputField.text, !text.isEmpty else { return }
        
        textView.text += "You: \(text)\n"
        
        // Get project path and existing session ID
        let projectPath = (project as? Project)?.path ?? "/Users/nick"
        let sessionId = UserDefaults.standard.string(forKey: "currentSessionId_\(projectPath)")
        
        // Send via WebSocket using the correct protocol
        let messageData: [String: Any] = [
            "type": "claude-command",
            "command": text,
            "projectPath": projectPath,
            "sessionId": sessionId as Any,
            "resume": sessionId != nil,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask?.send(message) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.textView.text += "Failed to send: \(error.localizedDescription)\n\n"
                    }
                }
            }
        }
        
        inputField.text = ""
    }
    
    deinit {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}

// File Explorer View Controller
public class FileExplorerViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        title = "Files"
        
        // Add a table view for files
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        view.addSubview(tableView)
    }
}

// Terminal View Controller
public class TerminalViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        title = "Terminal"
        
        // Add a text view for terminal output
        let textView = UITextView(frame: view.bounds)
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.backgroundColor = .black
        textView.textColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1.0) // Green terminal text
        textView.font = UIFont(name: "Menlo", size: 12) ?? UIFont.systemFont(ofSize: 12)
        textView.isEditable = false
        textView.text = "$ Claude Code Terminal v1.0\n$ Ready for commands...\n$ "
        view.addSubview(textView)
    }
}

// Settings View Controller
public class SettingsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        title = "Settings"
        
        // Add a table view for settings
        let tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        view.addSubview(tableView)
    }
}

// Authentication View Controller
class AuthenticationViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        title = "Authentication"
    }
}

// Launch View Controller
class LaunchViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        
        // Add logo
        let label = UILabel()
        label.text = "Claude Code"
        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        label.textColor = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1.0) // Cyan
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}