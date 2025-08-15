//
//  TerminalViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

class TerminalViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let project: Project?
    private var commandHistory: [String] = []
    private var historyIndex = -1
    private var currentDirectory = "~"
    private let webSocketManager: WebSocketManager
    private let shellWebSocketManager: WebSocketManager
    private var isShellConnected = false
    private let maxHistorySize = 100
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    // MARK: - UI Components
    
    private lazy var terminalTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0)
        textView.textColor = CyberpunkTheme.primaryCyan
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.isEditable = false
        textView.isSelectable = true
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        // Add glow effect
        textView.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        textView.layer.shadowRadius = 2
        textView.layer.shadowOpacity = 0.3
        textView.layer.shadowOffset = .zero
        
        return textView
    }()
    
    private lazy var inputContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1.0)
        view.layer.borderWidth = 1
        view.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        return view
    }()
    
    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = CyberpunkTheme.primaryCyan
        label.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        label.text = "$ "
        return label
    }()
    
    private lazy var commandTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .clear
        textField.textColor = CyberpunkTheme.primaryText
        textField.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textField.tintColor = CyberpunkTheme.primaryCyan
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.delegate = self
        textField.returnKeyType = .send
        
        // Add custom caret
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        return textField
    }()
    
    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.barStyle = .black
        toolbar.isTranslucent = true
        toolbar.backgroundColor = CyberpunkTheme.surface
        
        let clearButton = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearTerminal)
        )
        clearButton.tintColor = CyberpunkTheme.primaryCyan
        
        let historyButton = UIBarButtonItem(
            image: UIImage(systemName: "clock.arrow.circlepath"),
            style: .plain,
            target: self,
            action: #selector(showHistory)
        )
        historyButton.tintColor = CyberpunkTheme.primaryCyan
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let upButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up"),
            style: .plain,
            target: self,
            action: #selector(previousCommand)
        )
        upButton.tintColor = CyberpunkTheme.primaryCyan
        
        let downButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.down"),
            style: .plain,
            target: self,
            action: #selector(nextCommand)
        )
        downButton.tintColor = CyberpunkTheme.primaryCyan
        
        let reconnectButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(reconnectShell)
        )
        reconnectButton.tintColor = CyberpunkTheme.primaryCyan
        
        toolbar.items = [clearButton, historyButton, reconnectButton, flexSpace, upButton, downButton]
        
        return toolbar
    }()
    
    private lazy var scanlineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.05)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private var scanlineConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    
    init(project: Project? = nil) {
        self.project = project
        self.webSocketManager = DIContainer.shared.webSocketManager
        // Create a separate WebSocket manager for shell commands
        self.shellWebSocketManager = WebSocketManager()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.project = nil
        self.webSocketManager = DIContainer.shared.webSocketManager
        self.shellWebSocketManager = WebSocketManager()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadCommandHistory()
        showWelcomeMessage()
        startScanlineAnimation()
        setupKeyboardObservers()
        connectShellWebSocket()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        commandTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Disconnect shell WebSocket when leaving the terminal
        shellWebSocketManager.disconnect()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0)
        
        view.addSubview(terminalTextView)
        view.addSubview(inputContainerView)
        view.addSubview(toolbar)
        view.addSubview(scanlineView)
        
        inputContainerView.addSubview(promptLabel)
        inputContainerView.addSubview(commandTextField)
        
        scanlineConstraint = scanlineView.topAnchor.constraint(equalTo: view.topAnchor)
        
        NSLayoutConstraint.activate([
            terminalTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            terminalTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            terminalTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            terminalTextView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),
            
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            inputContainerView.heightAnchor.constraint(equalToConstant: 50),
            
            promptLabel.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            promptLabel.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            
            commandTextField.leadingAnchor.constraint(equalTo: promptLabel.trailingAnchor, constant: 4),
            commandTextField.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            commandTextField.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),
            
            scanlineView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scanlineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scanlineView.heightAnchor.constraint(equalToConstant: 2),
            scanlineConstraint
        ])
        
        updatePrompt()
    }
    
    private func setupNavigationBar() {
        title = project?.name ?? "Terminal"
        navigationItem.largeTitleDisplayMode = .never
        
        if project != nil {
            let closeButton = UIBarButtonItem(
                image: UIImage(systemName: "xmark"),
                style: .plain,
                target: self,
                action: #selector(closeTerminal)
            )
            closeButton.tintColor = CyberpunkTheme.primaryCyan
            navigationItem.rightBarButtonItem = closeButton
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
    
    // MARK: - Terminal Output
    
    private func showWelcomeMessage() {
        let welcomeText = """
        ╔════════════════════════════════════════════╗
        ║     Claude Code Terminal v1.0              ║
        ║     Cyberpunk Edition                      ║
        ╚════════════════════════════════════════════╝
        
        System initialized...
        Neural link established...
        
        Type 'help' for available commands.
        
        """
        
        appendToTerminal(welcomeText, color: CyberpunkTheme.primaryCyan)
    }
    
    private func appendToTerminal(_ text: String, color: UIColor = CyberpunkTheme.primaryText) {
        let attributedString = NSMutableAttributedString(attributedString: terminalTextView.attributedText ?? NSAttributedString())
        
        let newText = NSAttributedString(
            string: text + "\n",
            attributes: [
                .foregroundColor: color,
                .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            ]
        )
        
        attributedString.append(newText)
        terminalTextView.attributedText = attributedString
        
        // Scroll to bottom
        if terminalTextView.text.count > 0 {
            let bottom = NSMakeRange(terminalTextView.text.count - 1, 1)
            terminalTextView.scrollRangeToVisible(bottom)
        }
    }
    
    private func executeCommand(_ command: String) {
        // Add to history
        addToCommandHistory(command)
        historyIndex = -1
        
        // Show command in terminal
        appendToTerminal("$ \(command)", color: CyberpunkTheme.primaryCyan)
        
        // Special handling for clear command (local only)
        if command.lowercased() == "clear" || command.lowercased() == "cls" {
            clearTerminal()
            return
        }
        
        // Special handling for exit command (local only)
        if command.lowercased() == "exit" || command.lowercased() == "quit" {
            if project != nil {
                closeTerminal()
            } else {
                appendToTerminal("Cannot exit main terminal", color: CyberpunkTheme.accentPink)
            }
            return
        }
        
        // Send ALL other commands to backend for real execution
        sendCommandToBackend(command)
    }
    
    private func sendCommandToBackend(_ command: String) {
        // If shell WebSocket is connected, use it for real-time communication
        if isShellConnected {
            sendCommandViaWebSocket(command)
            return
        }
        
        // Fallback to HTTP if WebSocket is not connected
        // Create the request body
        let parameters: [String: Any] = [
            "command": command,
            "projectId": project?.id ?? "",
            "cwd": currentDirectory
        ]
        
        guard let url = URL(string: "http://\(AppConfig.backendHost):\(AppConfig.backendPort)/api/terminal/execute") else {
            appendToTerminal("Error: Invalid server URL", color: CyberpunkTheme.accentPink)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            appendToTerminal("Error: Failed to prepare command", color: CyberpunkTheme.accentPink)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.appendToTerminal("Error: \(error.localizedDescription)", color: CyberpunkTheme.accentPink)
                    return
                }
                
                guard let data = data else {
                    self?.appendToTerminal("Error: No response from server", color: CyberpunkTheme.accentPink)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // Handle stdout output
                        if let output = json["output"] as? String, !output.isEmpty {
                            self?.appendToTerminal(output)
                        }
                        
                        // Handle stderr output
                        if let stderr = json["stderr"] as? String, !stderr.isEmpty {
                            self?.appendToTerminal(stderr, color: CyberpunkTheme.warning)
                        }
                        
                        // Handle error messages
                        if let errorMsg = json["error"] as? String {
                            if errorMsg.contains("Command not found") || errorMsg.contains("not found") {
                                self?.appendToTerminal("\(errorMsg)", color: CyberpunkTheme.accentPink)
                            } else {
                                self?.appendToTerminal("Error: \(errorMsg)", color: CyberpunkTheme.accentPink)
                            }
                        }
                        
                        // Store session ID if provided
                        if let sessionId = json["sessionId"] as? String {
                            // Could use this for session management if needed
                            print("Terminal session ID: \(sessionId)")
                        }
                    }
                } catch {
                    self?.appendToTerminal("Error: Failed to parse response", color: CyberpunkTheme.accentPink)
                }
            }
        }.resume()
    }
    
    // MARK: - WebSocket Methods
    
    private func connectShellWebSocket() {
        // Set self as delegate to receive messages
        shellWebSocketManager.delegate = self
        
        // Configure auto-reconnection for shell WebSocket
        shellWebSocketManager.configure(
            enableAutoReconnect: true,
            reconnectDelay: 2.0,
            maxReconnectAttempts: 5
        )
        
        // Connect to shell WebSocket endpoint
        var wsURL = "ws://\(AppConfig.backendHost):\(AppConfig.backendPort)/shell"
        
        // Add authentication token if available
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            wsURL += "?token=\(authToken)"
        }
        
        // Add project ID if available (though backend uses projectPath from init message)
        if let projectId = project?.id {
            wsURL += wsURL.contains("?") ? "&projectId=\(projectId)" : "?projectId=\(projectId)"
        }
        
        shellWebSocketManager.connect(to: wsURL)
        print("🐚 Connecting to Shell WebSocket at: \(wsURL)")
        
        // Show connection status
        appendToTerminal("⏳ Connecting to shell server...", color: CyberpunkTheme.primaryCyan)
    }
    
    private func sendShellInitMessage() {
        // Send init message to shell WebSocket
        // Backend expects: {type: "init", projectPath: path, sessionId: id, hasSession: bool, provider: "claude"}
        let projectPath = project?.path ?? project?.id ?? getCurrentWorkingDirectory()
        
        let initData: [String: Any] = [
            "type": "init",
            "projectPath": projectPath,
            "sessionId": NSNull(), // No session for standalone terminal
            "hasSession": false,
            "provider": "claude",
            "cols": 120,  // Terminal columns (wider for better display)
            "rows": 40    // Terminal rows (more lines)
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: initData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            shellWebSocketManager.sendRawText(jsonString)
            print("🐚 Sent shell init message with project path: \(projectPath)")
            appendToTerminal("📂 Working directory: \(projectPath)", color: CyberpunkTheme.primaryCyan)
        }
    }
    
    private func sendCommandViaWebSocket(_ command: String) {
        // Ensure we're connected
        guard isShellConnected else {
            appendToTerminal("⚠️ Not connected to shell. Attempting to reconnect...", color: CyberpunkTheme.warning)
            connectShellWebSocket()
            return
        }
        
        // Create message matching backend's expected format for shell input
        // Backend expects {type: "input", data: "command"}
        let messageData: [String: Any] = [
            "type": "input",
            "data": command
        ]
        
        // Send as raw JSON string since backend expects specific format
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            shellWebSocketManager.sendRawText(jsonString)
            print("🐚 Sent shell command via WebSocket: \(command)")
        } else {
            appendToTerminal("❌ Failed to send command", color: CyberpunkTheme.accentPink)
        }
    }
    
    private func showHelp() {
        let helpText = """
        Available Commands:
        ═══════════════════════════════════════
        help        - Show this help message
        clear       - Clear terminal screen
        pwd         - Print working directory
        ls          - List directory contents
        cd <dir>    - Change directory
        echo <msg>  - Display message
        date        - Show current date/time
        whoami      - Display current user
        exit        - Close terminal (if in project)
        
        Navigation:
        ↑/↓         - Browse command history
        
        Note: All commands except 'clear' and 'exit' are
        executed on the backend server.
        """
        
        appendToTerminal(helpText, color: CyberpunkTheme.primaryText)
    }
    
    private func changeDirectory(_ path: String) {
        if path == ".." {
            currentDirectory = "~"
        } else if path == "~" {
            currentDirectory = "~"
        } else if path.starts(with: "/") {
            currentDirectory = path
        } else {
            currentDirectory = "\(currentDirectory)/\(path)"
        }
        updatePrompt()
        appendToTerminal("Changed directory to: \(currentDirectory)")
    }
    
    private func updatePrompt() {
        let projectName = project?.name ?? "system"
        promptLabel.text = "[\(projectName)]:\(currentDirectory)$ "
    }
    
    private func getCurrentWorkingDirectory() -> String {
        // Get current working directory as fallback
        return FileManager.default.currentDirectoryPath
    }
    
    // MARK: - Command History Management
    
    private func loadCommandHistory() {
        // Load command history from UserDefaults
        let key = "TerminalCommandHistory_\(project?.id ?? "global")"
        if let savedHistory = UserDefaults.standard.stringArray(forKey: key) {
            commandHistory = savedHistory
            // Limit to max size
            if commandHistory.count > maxHistorySize {
                commandHistory = Array(commandHistory.suffix(maxHistorySize))
            }
        }
    }
    
    private func saveCommandHistory() {
        // Save command history to UserDefaults
        let key = "TerminalCommandHistory_\(project?.id ?? "global")"
        UserDefaults.standard.set(commandHistory, forKey: key)
    }
    
    private func addToCommandHistory(_ command: String) {
        // Don't add duplicate consecutive commands
        if commandHistory.last != command {
            commandHistory.append(command)
            
            // Limit history size
            if commandHistory.count > maxHistorySize {
                commandHistory.removeFirst()
            }
            
            saveCommandHistory()
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTerminal() {
        dismiss(animated: true)
    }
    
    @objc private func clearTerminal() {
        terminalTextView.text = ""
        terminalTextView.attributedText = NSAttributedString()
        showWelcomeMessage()
        
        // Show connection status after clear
        if isShellConnected {
            appendToTerminal("✅ Connected to shell server", color: CyberpunkTheme.success)
        } else {
            appendToTerminal("⚠️ Not connected to shell server", color: CyberpunkTheme.warning)
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func reconnectShell() {
        if isShellConnected {
            appendToTerminal("Shell is already connected", color: CyberpunkTheme.success)
        } else {
            reconnectAttempts = 0 // Reset attempts for manual reconnection
            appendToTerminal("🔄 Manually reconnecting to shell...", color: CyberpunkTheme.primaryCyan)
            connectShellWebSocket()
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func showHistory() {
        if commandHistory.isEmpty {
            appendToTerminal("No command history", color: CyberpunkTheme.secondaryText)
        } else {
            appendToTerminal("Command History:", color: CyberpunkTheme.primaryCyan)
            for (index, cmd) in commandHistory.enumerated() {
                appendToTerminal("  \(index + 1). \(cmd)", color: CyberpunkTheme.secondaryText)
            }
        }
    }
    
    @objc private func previousCommand() {
        guard !commandHistory.isEmpty else { return }
        
        if historyIndex == -1 {
            historyIndex = commandHistory.count - 1
        } else if historyIndex > 0 {
            historyIndex -= 1
        }
        
        commandTextField.text = commandHistory[historyIndex]
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    @objc private func nextCommand() {
        guard !commandHistory.isEmpty && historyIndex >= 0 else { return }
        
        if historyIndex < commandHistory.count - 1 {
            historyIndex += 1
            commandTextField.text = commandHistory[historyIndex]
        } else {
            historyIndex = -1
            commandTextField.text = ""
        }
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    @objc private func textFieldDidChange() {
        // Could add auto-completion here
    }
    
    @objc override func keyboardWillShow(_ notification: Notification) {
        // Scroll terminal to bottom when keyboard appears
        if terminalTextView.text.count > 0 {
            let bottom = NSMakeRange(terminalTextView.text.count - 1, 1)
            terminalTextView.scrollRangeToVisible(bottom)
        }
    }
    
    // MARK: - UI Updates
    
    private func updateToolbarForConnectionState() {
        // Update reconnect button appearance based on connection state
        if let reconnectButton = toolbar.items?.first(where: { $0.action == #selector(reconnectShell) }) {
            if isShellConnected {
                reconnectButton.tintColor = CyberpunkTheme.success
                reconnectButton.image = UIImage(systemName: "checkmark.circle")
            } else {
                reconnectButton.tintColor = CyberpunkTheme.warning
                reconnectButton.image = UIImage(systemName: "arrow.clockwise")
            }
        }
    }
    
    // MARK: - Animation
    
    private func startScanlineAnimation() {
        UIView.animate(withDuration: 3.0,
                      delay: 0,
                      options: [.repeat, .curveLinear],
                      animations: { [weak self] in
            guard let self = self else { return }
            self.scanlineConstraint.constant = self.view.frame.height
            self.view.layoutIfNeeded()
        })
    }
}

// MARK: - UITextFieldDelegate

extension TerminalViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let command = textField.text, !command.isEmpty else { return false }
        
        executeCommand(command)
        textField.text = ""
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        return true
    }
}

// MARK: - WebSocketManagerDelegate

extension TerminalViewController: WebSocketManagerDelegate {
    func webSocketDidConnect(_ manager: WebSocketManager) {
        if manager === shellWebSocketManager {
            isShellConnected = true
            reconnectAttempts = 0 // Reset reconnect counter on successful connection
            appendToTerminal("✅ Connected to terminal server", color: CyberpunkTheme.success)
            print("🐚 Shell WebSocket connected successfully")
            
            // Send init message immediately after connection
            sendShellInitMessage()
            
            // Update toolbar items to show connected state
            updateToolbarForConnectionState()
        }
    }
    
    func webSocketDidDisconnect(_ manager: WebSocketManager, error: Error?) {
        if manager === shellWebSocketManager {
            isShellConnected = false
            if let error = error {
                appendToTerminal("⚠️ Disconnected: \(error.localizedDescription)", color: CyberpunkTheme.warning)
            } else {
                appendToTerminal("⚠️ Connection lost", color: CyberpunkTheme.warning)
            }
            print("🐚 Shell WebSocket disconnected")
            
            // Update toolbar to show disconnected state
            updateToolbarForConnectionState()
            
            // Auto-reconnect with exponential backoff
            attemptReconnection()
        }
    }
    
    private func attemptReconnection() {
        guard reconnectAttempts < maxReconnectAttempts else {
            appendToTerminal("❌ Failed to reconnect after \(maxReconnectAttempts) attempts", color: CyberpunkTheme.accentPink)
            return
        }
        
        reconnectAttempts += 1
        let delay = Double(reconnectAttempts) * 2.0 // Exponential backoff
        
        appendToTerminal("⏳ Reconnecting in \(Int(delay)) seconds... (attempt \(reconnectAttempts)/\(maxReconnectAttempts))", color: CyberpunkTheme.warning)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, !self.isShellConnected else { return }
            self.connectShellWebSocket()
        }
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveMessage message: WebSocketMessage) {
        if manager === shellWebSocketManager {
            // Handle shell output messages
            switch message.type {
            case .shellOutput:
                if let payload = message.payload,
                   let output = payload["output"] as? String {
                    appendToTerminal(output, color: CyberpunkTheme.primaryCyan)
                }
                
            case .shellError:
                if let payload = message.payload,
                   let error = payload["error"] as? String {
                    appendToTerminal(error, color: CyberpunkTheme.accentPink)
                }
                
            case .shellInit:
                if let payload = message.payload,
                   let cwd = payload["cwd"] as? String {
                    currentDirectory = cwd
                    updatePrompt()
                }
                
            default:
                // Also handle raw "output" type from backend
                if let type = message.payload?["type"] as? String,
                   type == "output",
                   let data = message.payload?["data"] as? String {
                    // Parse ANSI codes and display output
                    appendToTerminalWithANSI(data)
                }
                break
            }
        }
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveText text: String) {
        // Handle raw text messages from shell WebSocket
        if manager === shellWebSocketManager {
            // Parse JSON response from backend
            if let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let type = json["type"] as? String {
                    switch type {
                    case "output":
                        if let output = json["data"] as? String {
                            // Display shell output with ANSI parsing
                            // Don't add extra newlines for output that already has them
                            appendToTerminalWithANSI(output)
                        }
                    case "error":
                        if let error = json["data"] as? String {
                            // Check if it's a command not found error
                            if error.contains("command not found") || error.contains("not found") {
                                appendToTerminal(error, color: CyberpunkTheme.warning)
                            } else {
                                appendToTerminal("❌ \(error)", color: CyberpunkTheme.accentPink)
                            }
                        }
                    case "init":
                        // Shell initialized successfully
                        if let cwd = json["cwd"] as? String {
                            currentDirectory = cwd
                            updatePrompt()
                            appendToTerminal("✅ Shell initialized in \(cwd)", color: CyberpunkTheme.success)
                        } else {
                            appendToTerminal("✅ Shell initialized", color: CyberpunkTheme.success)
                        }
                    case "exit":
                        appendToTerminal("👋 Shell session ended", color: CyberpunkTheme.warning)
                        isShellConnected = false
                        // Don't auto-reconnect on explicit exit
                    case "clear":
                        // Handle clear screen command from backend
                        clearTerminal()
                    default:
                        print("🐚 Unknown shell message type: \(type)")
                        // Still try to display any data if present
                        if let data = json["data"] as? String {
                            appendToTerminalWithANSI(data)
                        }
                    }
                } else if let data = json["data"] as? String {
                    // Some messages might not have a type but have data
                    appendToTerminalWithANSI(data)
                } else {
                    // Handle other JSON structures
                    print("🐚 Received JSON without recognized structure: \(json)")
                }
            } else {
                // If not JSON, treat as raw output (might be streaming data)
                appendToTerminalWithANSI(text)
            }
        }
    }
    
    // MARK: - ANSI Code Parser
    
    private func parseANSIOutput(_ text: String) -> NSAttributedString {
        // Create an attributed string to handle ANSI colors
        let attributedString = NSMutableAttributedString()
        
        // ANSI color codes for foreground (30-37, 90-97)
        let ansiColors: [Int: UIColor] = [
            30: UIColor.black,
            31: UIColor.systemRed,
            32: UIColor.systemGreen,
            33: UIColor.systemYellow,
            34: UIColor.systemBlue,
            35: UIColor.systemPurple,
            36: UIColor.systemCyan,
            37: UIColor.white,
            90: UIColor.darkGray,
            91: UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0), // Light red
            92: UIColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0), // Light green
            93: UIColor(red: 1.0, green: 1.0, blue: 0.5, alpha: 1.0), // Light yellow
            94: UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0), // Light blue
            95: UIColor(red: 1.0, green: 0.5, blue: 1.0, alpha: 1.0), // Light magenta
            96: UIColor(red: 0.5, green: 1.0, blue: 1.0, alpha: 1.0), // Light cyan
            97: UIColor.white
        ]
        
        // Default attributes
        var currentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: CyberpunkTheme.primaryText
        ]
        
        // Pattern to match ANSI escape sequences (including 256 color and RGB)
        let ansiPattern = "\\x1B\\[([0-9;]+)m|\\x1B\\[([0-9]+)([A-Z])"
        let ansiRegex = try? NSRegularExpression(pattern: ansiPattern, options: [])
        
        var lastIndex = 0
        let nsText = text as NSString
        
        // Find all ANSI codes
        ansiRegex?.enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) { match, _, _ in
            guard let match = match else { return }
            
            // Append text before this ANSI code
            if match.range.location > lastIndex {
                let range = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                let substring = nsText.substring(with: range)
                attributedString.append(NSAttributedString(string: substring, attributes: currentAttributes))
            }
            
            // Parse ANSI codes
            if match.numberOfRanges > 1 {
                let codeRange = match.range(at: 1)
                let codes = nsText.substring(with: codeRange).split(separator: ";").compactMap { Int($0) }
                
                var i = 0
                while i < codes.count {
                    let code = codes[i]
                    switch code {
                    case 0: // Reset all attributes
                        currentAttributes[.foregroundColor] = CyberpunkTheme.primaryText
                        currentAttributes[.backgroundColor] = UIColor.clear
                        currentAttributes[.font] = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
                        currentAttributes[.underlineStyle] = 0
                        currentAttributes[.strikethroughStyle] = 0
                    case 1: // Bold
                        currentAttributes[.font] = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
                    case 2: // Dim
                        if let color = currentAttributes[.foregroundColor] as? UIColor {
                            currentAttributes[.foregroundColor] = color.withAlphaComponent(0.6)
                        }
                    case 3: // Italic (simulate with oblique if needed)
                        // iOS doesn't have italic monospace, keep regular
                        break
                    case 4: // Underline
                        currentAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                    case 7: // Reverse (swap foreground and background)
                        let fg = currentAttributes[.foregroundColor] as? UIColor ?? CyberpunkTheme.primaryText
                        let bg = currentAttributes[.backgroundColor] as? UIColor ?? UIColor.clear
                        currentAttributes[.foregroundColor] = bg == UIColor.clear ? UIColor.black : bg
                        currentAttributes[.backgroundColor] = fg
                    case 9: // Strikethrough
                        currentAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                    case 22: // Normal intensity
                        currentAttributes[.font] = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
                    case 24: // No underline
                        currentAttributes[.underlineStyle] = 0
                    case 30...37, 90...97: // Foreground colors
                        currentAttributes[.foregroundColor] = ansiColors[code] ?? CyberpunkTheme.primaryText
                    case 38: // Extended foreground color
                        if i + 2 < codes.count && codes[i + 1] == 5 {
                            // 256 color mode
                            let colorIndex = codes[i + 2]
                            currentAttributes[.foregroundColor] = ansi256Color(colorIndex)
                            i += 2
                        } else if i + 4 < codes.count && codes[i + 1] == 2 {
                            // RGB color mode
                            let r = CGFloat(codes[i + 2]) / 255.0
                            let g = CGFloat(codes[i + 3]) / 255.0
                            let b = CGFloat(codes[i + 4]) / 255.0
                            currentAttributes[.foregroundColor] = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                            i += 4
                        }
                    case 39: // Default foreground color
                        currentAttributes[.foregroundColor] = CyberpunkTheme.primaryText
                    case 40...47, 100...107: // Background colors
                        let bgCode = code >= 100 ? code - 60 : code - 10
                        currentAttributes[.backgroundColor] = ansiColors[bgCode] ?? UIColor.clear
                    case 48: // Extended background color
                        if i + 2 < codes.count && codes[i + 1] == 5 {
                            // 256 color mode
                            let colorIndex = codes[i + 2]
                            currentAttributes[.backgroundColor] = ansi256Color(colorIndex)
                            i += 2
                        } else if i + 4 < codes.count && codes[i + 1] == 2 {
                            // RGB color mode
                            let r = CGFloat(codes[i + 2]) / 255.0
                            let g = CGFloat(codes[i + 3]) / 255.0
                            let b = CGFloat(codes[i + 4]) / 255.0
                            currentAttributes[.backgroundColor] = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                            i += 4
                        }
                    case 49: // Default background color
                        currentAttributes[.backgroundColor] = UIColor.clear
                    default:
                        break
                    }
                    i += 1
                }
            }
            
            lastIndex = match.range.location + match.range.length
        }
        
        // Append remaining text
        if lastIndex < nsText.length {
            let range = NSRange(location: lastIndex, length: nsText.length - lastIndex)
            let substring = nsText.substring(with: range)
            attributedString.append(NSAttributedString(string: substring, attributes: currentAttributes))
        }
        
        // If no ANSI codes were found, return plain text with default attributes
        if attributedString.length == 0 {
            return NSAttributedString(string: text, attributes: currentAttributes)
        }
        
        return attributedString
    }
    
    private func appendToTerminalWithANSI(_ text: String) {
        let currentAttributedText = terminalTextView.attributedText ?? NSAttributedString()
        let mutableText = NSMutableAttributedString(attributedString: currentAttributedText)
        
        // Parse ANSI and append
        let parsedText = parseANSIOutput(text)
        mutableText.append(parsedText)
        
        // Add newline if not present and text is not empty
        if !text.isEmpty && !text.hasSuffix("\n") && !text.hasSuffix("\r") {
            mutableText.append(NSAttributedString(string: "\n"))
        }
        
        terminalTextView.attributedText = mutableText
        
        // Scroll to bottom
        if terminalTextView.text.count > 0 {
            let bottom = NSMakeRange(terminalTextView.text.count - 1, 1)
            terminalTextView.scrollRangeToVisible(bottom)
        }
    }
    
    // Helper function to get 256 color palette colors
    private func ansi256Color(_ index: Int) -> UIColor {
        // Standard 16 colors (0-15)
        if index < 16 {
            let standardColors: [UIColor] = [
                UIColor.black,
                UIColor(red: 0.5, green: 0, blue: 0, alpha: 1), // Dark red
                UIColor(red: 0, green: 0.5, blue: 0, alpha: 1), // Dark green
                UIColor(red: 0.5, green: 0.5, blue: 0, alpha: 1), // Dark yellow
                UIColor(red: 0, green: 0, blue: 0.5, alpha: 1), // Dark blue
                UIColor(red: 0.5, green: 0, blue: 0.5, alpha: 1), // Dark magenta
                UIColor(red: 0, green: 0.5, blue: 0.5, alpha: 1), // Dark cyan
                UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1), // Light gray
                UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1), // Dark gray
                UIColor.systemRed,
                UIColor.systemGreen,
                UIColor.systemYellow,
                UIColor.systemBlue,
                UIColor.systemPurple,
                UIColor.systemCyan,
                UIColor.white
            ]
            return index < standardColors.count ? standardColors[index] : CyberpunkTheme.primaryText
        }
        
        // 216 color cube (16-231)
        if index >= 16 && index <= 231 {
            let idx = index - 16
            let r = (idx / 36) * 51
            let g = ((idx % 36) / 6) * 51
            let b = (idx % 6) * 51
            return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0)
        }
        
        // Grayscale (232-255)
        if index >= 232 && index <= 255 {
            let gray = 8 + (index - 232) * 10
            let value = CGFloat(gray) / 255.0
            return UIColor(white: value, alpha: 1.0)
        }
        
        return CyberpunkTheme.primaryText
    }
    
    func webSocket(_ manager: WebSocketManager, didReceiveData data: Data) {
        // Handle binary data if needed
    }
    
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        switch state {
        case .connecting:
            print("🐚 Shell WebSocket connecting...")
        case .connected:
            print("🐚 Shell WebSocket connected")
        case .disconnected:
            print("🐚 Shell WebSocket disconnected")
        case .reconnecting:
            print("🐚 Shell WebSocket reconnecting...")
        case .failed:
            print("🐚 Shell WebSocket connection failed")
        @unknown default:
            print("🐚 Shell WebSocket unknown state")
        }
    }
}