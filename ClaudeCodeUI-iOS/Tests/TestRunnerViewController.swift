//
//  TestRunnerViewController.swift
//  ClaudeCodeUI
//
//  Test runner for all integration tests
//

import UIKit

class TestRunnerViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let outputTextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTests()
    }
    
    private func setupUI() {
        title = "Integration Tests"
        view.backgroundColor = CyberpunkTheme.background
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Setup stack view
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // Setup output text view
        outputTextView.backgroundColor = UIColor(white: 0.1, alpha: 1)
        outputTextView.textColor = CyberpunkTheme.primaryCyan
        outputTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        outputTextView.isEditable = false
        outputTextView.translatesAutoresizingMaskIntoConstraints = false
        outputTextView.layer.cornerRadius = 8
        outputTextView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func setupTests() {
        // Add test buttons
        addTestButton(
            title: "🌊 Test WebSocket Streaming",
            subtitle: "Real-time JSON streaming from backend",
            action: #selector(runWebSocketTest)
        )
        
        addTestButton(
            title: "🎯 Test Cursor Integration",
            subtitle: "All 8 Cursor API endpoints",
            action: #selector(runCursorTest)
        )
        
        addTestButton(
            title: "🐚 Test Shell WebSocket",
            subtitle: "Terminal command execution",
            action: #selector(runShellTest)
        )
        
        addTestButton(
            title: "🔄 Test All APIs",
            subtitle: "Complete backend API test suite",
            action: #selector(runAllTests)
        )
        
        // Add output view
        let outputLabel = UILabel()
        outputLabel.text = "Test Output:"
        outputLabel.textColor = CyberpunkTheme.primaryText
        outputLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        stackView.addArrangedSubview(outputLabel)
        
        stackView.addArrangedSubview(outputTextView)
        outputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        
        // Add clear button
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear Output", for: .normal)
        clearButton.setTitleColor(CyberpunkTheme.accentPink, for: .normal)
        clearButton.addTarget(self, action: #selector(clearOutput), for: .touchUpInside)
        stackView.addArrangedSubview(clearButton)
    }
    
    private func addTestButton(title: String, subtitle: String, action: Selector) {
        let container = UIView()
        container.backgroundColor = CyberpunkTheme.surface
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = CyberpunkTheme.primaryCyan
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = CyberpunkTheme.secondaryText
        subtitleLabel.font = .systemFont(ofSize: 14)
        
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 4
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        labelStack.isUserInteractionEnabled = false
        container.addSubview(labelStack)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            labelStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            labelStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            labelStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            labelStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        button.addTarget(self, action: action, for: .touchUpInside)
        
        stackView.addArrangedSubview(container)
    }
    
    // MARK: - Test Actions
    
    @objc private func runWebSocketTest() {
        outputTextView.text = "Starting WebSocket Streaming Test...\n\n"
        
        // Redirect console output to text view
        let originalOutput = dup(STDOUT_FILENO)
        let pipe = Pipe()
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        
        // Run test
        WebSocketStreamingTest.runLiveTest()
        
        // Capture output
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            // Restore original output
            dup2(originalOutput, STDOUT_FILENO)
            
            // Read captured output
            let data = pipe.fileHandleForReading.availableData
            if let output = String(data: data, encoding: .utf8) {
                self?.outputTextView.text += output
            }
        }
    }
    
    @objc private func runCursorTest() {
        outputTextView.text = "Starting Cursor Integration Tests...\n\n"
        
        Task {
            // Run tests and capture output
            await CursorIntegrationTest().runAllTests()
            
            DispatchQueue.main.async { [weak self] in
                self?.outputTextView.text += "\nTests completed. Check Xcode console for detailed output."
            }
        }
    }
    
    @objc private func runShellTest() {
        outputTextView.text = "Starting Shell WebSocket Test...\n\n"
        
        // Create a test terminal view controller
        let terminalVC = TerminalViewController(project: nil)
        
        // Present it temporarily to test connection
        present(terminalVC, animated: true) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self?.outputTextView.text += "Shell WebSocket test initiated.\n"
                self?.outputTextView.text += "Check the terminal view for connection status.\n"
                
                // Dismiss after testing
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    terminalVC.dismiss(animated: true)
                }
            }
        }
    }
    
    @objc private func runAllTests() {
        outputTextView.text = "Running All Integration Tests...\n\n"
        
        Task {
            outputTextView.text += "1. WebSocket Streaming Test\n"
            WebSocketStreamingTest.runLiveTest()
            
            outputTextView.text += "\n2. Cursor Integration Tests\n"
            await CursorIntegrationTest().runAllTests()
            
            outputTextView.text += "\n3. Shell WebSocket Test\n"
            runShellTest()
            
            outputTextView.text += "\n\nAll tests initiated. Check Xcode console for detailed output."
        }
    }
    
    @objc private func clearOutput() {
        outputTextView.text = ""
    }
}

// MARK: - Test Runner Extension for Easy Access

extension TestRunnerViewController {
    static func present(from viewController: UIViewController) {
        let testRunner = TestRunnerViewController()
        let navController = UINavigationController(rootViewController: testRunner)
        navController.modalPresentationStyle = .fullScreen
        
        // Add close button
        testRunner.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: testRunner,
            action: #selector(dismissTestRunner)
        )
        
        viewController.present(navController, animated: true)
    }
    
    @objc private func dismissTestRunner() {
        dismiss(animated: true)
    }
}