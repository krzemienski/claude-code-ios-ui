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
    private let shellWebSocketManager: ShellWebSocketManager
    private var isShellConnected = false
    private let maxHistorySize = 100
    
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
        
        // Add custom input accessory view for history navigation
        textField.inputAccessoryView = createHistoryNavigationView()
        
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
            action: #selector(navigateHistoryUp)
        )
        upButton.tintColor = CyberpunkTheme.primaryCyan
        
        let downButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.down"),
            style: .plain,
            target: self,
            action: #selector(navigateHistoryDown)
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
        // Create a dedicated shell WebSocket manager
        self.shellWebSocketManager = ShellWebSocketManager()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.project = nil
        self.shellWebSocketManager = ShellWebSocketManager()
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Send terminal resize message when view size changes
        if isShellConnected {
            sendTerminalResize()
        }
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
    
    private func createHistoryNavigationView() -> UIView {
        let accessoryView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        accessoryView.backgroundColor = CyberpunkTheme.surface
        accessoryView.layer.borderWidth = 1
        accessoryView.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        
        // Create a toolbar for the accessory view
        let toolbar = UIToolbar(frame: accessoryView.bounds)
        toolbar.barStyle = .black
        toolbar.isTranslucent = true
        toolbar.backgroundColor = CyberpunkTheme.surface
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Create navigation buttons
        let upButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up"),
            style: .plain,
            target: self,
            action: #selector(navigateHistoryUp)
        )
        upButton.tintColor = CyberpunkTheme.primaryCyan
        
        let downButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.down"),
            style: .plain,
            target: self,
            action: #selector(navigateHistoryDown)
        )
        downButton.tintColor = CyberpunkTheme.primaryCyan
        
        let clearButton = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearCommandField)
        )
        clearButton.tintColor = CyberpunkTheme.primaryCyan
        
        let tabButton = UIBarButtonItem(
            title: "TAB",
            style: .plain,
            target: self,
            action: #selector(handleTabCompletion)
        )
        tabButton.tintColor = CyberpunkTheme.primaryCyan
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissKeyboard)
        )
        doneButton.tintColor = CyberpunkTheme.primaryCyan
        
        toolbar.items = [upButton, downButton, flexSpace, clearButton, tabButton, flexSpace, doneButton]
        
        accessoryView.addSubview(toolbar)
        
        return accessoryView
    }
    
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
    
    private func appendAttributedText(_ attributedText: NSAttributedString) {
        let currentAttributedText = terminalTextView.attributedText ?? NSAttributedString()
        let mutableText = NSMutableAttributedString(attributedString: currentAttributedText)
        
        mutableText.append(attributedText)
        
        // Add newline if needed
        let text = attributedText.string
        if !text.isEmpty && !text.hasSuffix("\n") && !text.hasSuffix("\r") {
            let newlineAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular),
                .foregroundColor: CyberpunkTheme.primaryText
            ]
            mutableText.append(NSAttributedString(string: "\n", attributes: newlineAttributes))
        }
        
        terminalTextView.attributedText = mutableText
        
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
        
        // Special handling for help command
        if command.lowercased() == "help" {
            showHelp()
            return
        }
        
        // Send ALL other commands to backend for real execution
        sendCommandToBackend(command)
    }
    
    private func sendCommandToBackend(_ command: String) {
        // Always try WebSocket first for real-time communication
        if isShellConnected {
            sendCommandViaWebSocket(command)
            return
        }
        
        // If not connected, try to connect first
        appendToTerminal("⚠️ Not connected to shell. Attempting to connect...", color: CyberpunkTheme.warning)
        connectShellWebSocket()
        
        // Store the command to execute after connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            if self.isShellConnected {
                self.sendCommandViaWebSocket(command)
            } else {
                // Fallback to HTTP if WebSocket connection fails
                self.sendCommandViaHTTP(command)
            }
        }
    }
    
    private func sendCommandViaHTTP(_ command: String) {
        // HTTP fallback for command execution
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
        appendToTerminal("🔄 Connecting to shell server...", color: CyberpunkTheme.primaryCyan)
        
        // Set ourselves as delegate to receive messages
        shellWebSocketManager.delegate = self
        
        // Connect to the shell WebSocket endpoint with project path
        let projectPath = project?.path ?? project?.id ?? FileManager.default.currentDirectoryPath
        shellWebSocketManager.connect(projectPath: projectPath)
        
        print("🐚 Initiating shell WebSocket connection with project path: \(projectPath)")
    }
    
    
    private func sendTerminalResize() {
        // Calculate new terminal size
        let charWidth: CGFloat = 7.0
        let charHeight: CGFloat = 16.0
        let cols = Int((terminalTextView.bounds.width - 24) / charWidth)
        let rows = Int((terminalTextView.bounds.height - 24) / charHeight)
        
        shellWebSocketManager.sendTerminalResize(cols: max(80, cols), rows: max(24, rows))
        print("🐚 Sent terminal resize: cols=\(cols), rows=\(rows)")
    }
    
    private func sendCommandViaWebSocket(_ command: String) {
        // Ensure we're connected
        guard isShellConnected else {
            appendToTerminal("⚠️ Not connected to shell. Attempting to reconnect...", color: CyberpunkTheme.warning)
            connectShellWebSocket()
            return
        }
        
        // Send command through the new ShellWebSocketManager
        let workingDirectory = currentDirectory.isEmpty ? getCurrentWorkingDirectory() : currentDirectory
        shellWebSocketManager.sendCommand(command, workingDirectory: workingDirectory) { [weak self] success, error in
            if !success, let error = error {
                self?.appendToTerminal("❌ \(error)", color: CyberpunkTheme.accentPink)
            }
        }
        
        print("🐚 Sent shell command via WebSocket: \(command) in directory: \(workingDirectory)")
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
        TAB         - Auto-complete commands
        
        Note: All commands except 'clear', 'help' and 'exit' 
        are executed on the backend server.
        """
        
        appendToTerminal(helpText, color: CyberpunkTheme.primaryText)
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
            appendToTerminal("✅ Already connected to shell server", color: CyberpunkTheme.success)
        } else {
            appendToTerminal("🔄 Reconnecting to shell server...", color: CyberpunkTheme.primaryCyan)
            connectShellWebSocket()
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func navigateHistoryUp() {
        // Navigate to previous command in history
        if !commandHistory.isEmpty {
            if historyIndex == -1 {
                // Start from the end of history
                historyIndex = commandHistory.count - 1
            } else if historyIndex > 0 {
                // Move to previous command
                historyIndex -= 1
            }
            
            if historyIndex >= 0 && historyIndex < commandHistory.count {
                commandTextField.text = commandHistory[historyIndex]
            }
        }
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    @objc private func navigateHistoryDown() {
        // Navigate to next command in history
        if !commandHistory.isEmpty && historyIndex != -1 {
            if historyIndex < commandHistory.count - 1 {
                // Move to next command
                historyIndex += 1
                commandTextField.text = commandHistory[historyIndex]
            } else {
                // Clear the field when at the end
                historyIndex = -1
                commandTextField.text = ""
            }
        }
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    @objc private func clearCommandField() {
        commandTextField.text = ""
        historyIndex = -1
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func handleTabCompletion() {
        // TODO: Implement TAB completion for file paths
        // For now, just show a placeholder message
        guard let currentText = commandTextField.text, !currentText.isEmpty else { return }
        
        // Basic implementation: complete common commands
        let commonCommands = ["ls", "cd", "pwd", "echo", "clear", "help", "exit", "mkdir", "rm", "cat", "grep", "find"]
        let matchingCommands = commonCommands.filter { $0.hasPrefix(currentText) }
        
        if matchingCommands.count == 1 {
            commandTextField.text = matchingCommands[0] + " "
        } else if matchingCommands.count > 1 {
            appendToTerminal("Suggestions: \(matchingCommands.joined(separator: ", "))", color: CyberpunkTheme.secondaryText)
        }
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    @objc private func dismissKeyboard() {
        commandTextField.resignFirstResponder()
        
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

// MARK: - ShellWebSocketManagerDelegate

extension TerminalViewController: ShellWebSocketManagerDelegate {
    func shellWebSocketDidConnect(_ manager: ShellWebSocketManager) {
        isShellConnected = true
        appendToTerminal("✅ Connected to terminal server", color: CyberpunkTheme.success)
        print("🐚 Shell WebSocket connected successfully")
        
        // Update toolbar items to show connected state
        updateToolbarForConnectionState()
    }
    
    func shellWebSocketDidDisconnect(_ manager: ShellWebSocketManager, error: Error?) {
        isShellConnected = false
        if let error = error {
            appendToTerminal("⚠️ Disconnected: \(error.localizedDescription)", color: CyberpunkTheme.warning)
        } else {
            appendToTerminal("⚠️ Connection lost", color: CyberpunkTheme.warning)
        }
        print("🐚 Shell WebSocket disconnected")
        
        // Update toolbar to show disconnected state
        updateToolbarForConnectionState()
    }
    
    func shellWebSocketDidInitialize(_ manager: ShellWebSocketManager, workingDirectory: String?) {
        if let cwd = workingDirectory {
            currentDirectory = cwd
            updatePrompt()
            appendToTerminal("✅ Shell initialized in \(cwd)", color: CyberpunkTheme.success)
        } else {
            appendToTerminal("✅ Shell initialized", color: CyberpunkTheme.success)
        }
    }
    
    func shellWebSocket(_ manager: ShellWebSocketManager, didReceiveOutput output: String) {
        // Use TerminalOutputParser for ANSI code handling
        let parsedOutput = TerminalOutputParser.shared.parseOutput(output)
        appendAttributedText(parsedOutput)
    }
    
    func shellWebSocket(_ manager: ShellWebSocketManager, didReceiveError error: String) {
        if error.contains("command not found") || error.contains("not found") {
            appendToTerminal(error, color: CyberpunkTheme.warning)
        } else {
            appendToTerminal("❌ \(error)", color: CyberpunkTheme.accentPink)
        }
    }
}