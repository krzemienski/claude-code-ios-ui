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
        
        toolbar.items = [clearButton, historyButton, flexSpace, upButton, downButton]
        
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
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.project = nil
        self.webSocketManager = DIContainer.shared.webSocketManager
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        showWelcomeMessage()
        startScanlineAnimation()
        setupKeyboardObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        commandTextField.becomeFirstResponder()
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
        commandHistory.append(command)
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
    
    // MARK: - Actions
    
    @objc private func closeTerminal() {
        dismiss(animated: true)
    }
    
    @objc private func clearTerminal() {
        terminalTextView.text = ""
        terminalTextView.attributedText = NSAttributedString()
        showWelcomeMessage()
        
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