//
//  AuthenticationViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

class AuthenticationViewController: BaseViewController {
    
    // MARK: - UI Components
    
    private lazy var backgroundGridView: GridBackgroundView = {
        let view = GridBackgroundView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = CyberpunkTheme.primaryCyan
        
        // Create a placeholder logo using SF Symbols
        let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .thin)
        imageView.image = UIImage(systemName: "cube.transparent", withConfiguration: config)
        
        // Add glow effect
        imageView.layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        imageView.layer.shadowRadius = 20
        imageView.layer.shadowOpacity = 0.5
        imageView.layer.shadowOffset = .zero
        
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Claude Code UI"
        label.font = CyberpunkTheme.titleFont
        label.textColor = CyberpunkTheme.primaryText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Mobile Interface for Claude Code CLI"
        label.font = CyberpunkTheme.bodyFont
        label.textColor = CyberpunkTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var biometricButton: NeonButton = {
        let button = NeonButton(style: .primary)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Authenticate with Face ID", for: .normal)
        button.addTarget(self, action: #selector(authenticateWithBiometrics), for: .touchUpInside)
        return button
    }()
    
    private lazy var manualAuthButton: NeonButton = {
        let button = NeonButton(style: .secondary)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Enter API Key", for: .normal)
        button.addTarget(self, action: #selector(showManualAuth), for: .touchUpInside)
        return button
    }()
    
    private lazy var apiKeyContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = CyberpunkTheme.surface
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = CyberpunkTheme.border.cgColor
        view.isHidden = true
        view.alpha = 0
        return view
    }()
    
    private lazy var serverURLTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Server URL (e.g., http://localhost:3004)"
        textField.font = CyberpunkTheme.codeFont
        textField.textColor = CyberpunkTheme.primaryText
        textField.tintColor = CyberpunkTheme.primaryCyan
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .URL
        textField.text = AppConfig.backendURL
        textField.returnKeyType = .next
        textField.delegate = self
        
        // Style placeholder
        textField.attributedPlaceholder = NSAttributedString(
            string: "Server URL (e.g., http://localhost:3004)",
            attributes: [
                .foregroundColor: CyberpunkTheme.secondaryText,
                .font: CyberpunkTheme.codeFont
            ]
        )
        
        return textField
    }()
    
    private lazy var apiKeyTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Enter your Claude API key (optional)"
        textField.font = CyberpunkTheme.codeFont
        textField.textColor = CyberpunkTheme.primaryText
        textField.tintColor = CyberpunkTheme.primaryCyan
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.isSecureTextEntry = true
        textField.returnKeyType = .done
        textField.delegate = self
        
        // Style placeholder
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter your Claude API key (optional)",
            attributes: [
                .foregroundColor: CyberpunkTheme.secondaryText,
                .font: CyberpunkTheme.codeFont
            ]
        )
        
        return textField
    }()
    
    private lazy var saveKeyButton: NeonButton = {
        let button = NeonButton(style: .primary)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save & Continue", for: .normal)
        button.addTarget(self, action: #selector(saveAPIKey), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    private let biometricAuth = BiometricAuthManager()
    private let errorHandler: ErrorHandlingService
    private let dataContainer: SwiftDataContainer?
    
    // MARK: - Initialization
    
    init(errorHandler: ErrorHandlingService = DIContainer.shared.errorHandler,
         dataContainer: SwiftDataContainer? = try? SwiftDataContainer()) {
        self.errorHandler = errorHandler
        self.dataContainer = dataContainer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateBiometricButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateLogoGlow()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add background grid
        view.addSubview(backgroundGridView)
        
        // Add main content
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(biometricButton)
        view.addSubview(manualAuthButton)
        view.addSubview(apiKeyContainerView)
        
        // Add API key input components
        apiKeyContainerView.addSubview(serverURLTextField)
        apiKeyContainerView.addSubview(apiKeyTextField)
        apiKeyContainerView.addSubview(saveKeyButton)
        
        NSLayoutConstraint.activate([
            // Background grid
            backgroundGridView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundGridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundGridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundGridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Logo
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // Biometric button
            biometricButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            biometricButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            biometricButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            biometricButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Manual auth button
            manualAuthButton.topAnchor.constraint(equalTo: biometricButton.bottomAnchor, constant: 16),
            manualAuthButton.leadingAnchor.constraint(equalTo: biometricButton.leadingAnchor),
            manualAuthButton.trailingAnchor.constraint(equalTo: biometricButton.trailingAnchor),
            manualAuthButton.heightAnchor.constraint(equalToConstant: 56),
            
            // API key container
            apiKeyContainerView.topAnchor.constraint(equalTo: manualAuthButton.bottomAnchor, constant: 24),
            apiKeyContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            apiKeyContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // Server URL text field
            serverURLTextField.topAnchor.constraint(equalTo: apiKeyContainerView.topAnchor, constant: 16),
            serverURLTextField.leadingAnchor.constraint(equalTo: apiKeyContainerView.leadingAnchor, constant: 16),
            serverURLTextField.trailingAnchor.constraint(equalTo: apiKeyContainerView.trailingAnchor, constant: -16),
            serverURLTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // API key text field
            apiKeyTextField.topAnchor.constraint(equalTo: serverURLTextField.bottomAnchor, constant: 12),
            apiKeyTextField.leadingAnchor.constraint(equalTo: apiKeyContainerView.leadingAnchor, constant: 16),
            apiKeyTextField.trailingAnchor.constraint(equalTo: apiKeyContainerView.trailingAnchor, constant: -16),
            apiKeyTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Save button
            saveKeyButton.topAnchor.constraint(equalTo: apiKeyTextField.bottomAnchor, constant: 16),
            saveKeyButton.leadingAnchor.constraint(equalTo: apiKeyTextField.leadingAnchor),
            saveKeyButton.trailingAnchor.constraint(equalTo: apiKeyTextField.trailingAnchor),
            saveKeyButton.bottomAnchor.constraint(equalTo: apiKeyContainerView.bottomAnchor, constant: -16),
            saveKeyButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func updateBiometricButton() {
        let biometricType = biometricAuth.biometricType
        let isAvailable = biometricAuth.isBiometricAvailable
        
        if isAvailable {
            biometricButton.setTitle("Authenticate with \(biometricType)", for: .normal)
            biometricButton.isEnabled = true
        } else {
            biometricButton.setTitle("Biometric Authentication Not Available", for: .normal)
            biometricButton.isEnabled = false
        }
    }
    
    // MARK: - Animations
    
    private func animateLogoGlow() {
        UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.logoImageView.layer.shadowOpacity = 0.8
        })
    }
    
    private func showAPIKeyInput() {
        apiKeyContainerView.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.apiKeyContainerView.alpha = 1
            self.apiKeyTextField.becomeFirstResponder()
        }
    }
    
    private func hideAPIKeyInput() {
        UIView.animate(withDuration: 0.3) {
            self.apiKeyContainerView.alpha = 0
        } completion: { _ in
            self.apiKeyContainerView.isHidden = true
            self.apiKeyTextField.text = ""
        }
    }
    
    // MARK: - Actions
    
    @objc private func authenticateWithBiometrics() {
        Task {
            do {
                try await biometricAuth.authenticate()
                await proceedToMainApp()
            } catch {
                await errorHandler.handle(error)
            }
        }
    }
    
    @objc private func showManualAuth() {
        showAPIKeyInput()
    }
    
    @objc private func saveAPIKey() {
        guard let serverURL = serverURLTextField.text, !serverURL.isEmpty else {
            errorHandler.handle(ValidationError(message: "Please enter a valid server URL"))
            return
        }
        
        // API key is optional
        let apiKey = apiKeyTextField.text
        
        Task {
            do {
                // Save server URL and API key to settings
                if let dataContainer = dataContainer {
                    var settings = try await dataContainer.fetchSettings() ?? Settings()
                    settings.apiBaseURL = serverURL
                    settings.webSocketURL = serverURL.replacingOccurrences(of: "http://", with: "ws://")
                                                     .replacingOccurrences(of: "https://", with: "wss://")
                    settings.authToken = apiKey
                    try await dataContainer.updateSettings(settings)
                }
                
                hideAPIKeyInput()
                await proceedToMainApp()
            } catch {
                await errorHandler.handle(error)
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @MainActor
    private func proceedToMainApp() {
        // Navigate to projects dashboard
        let projectsVC = ProjectsViewController()
        let navController = UINavigationController(rootViewController: projectsVC)
        navController.modalPresentationStyle = .fullScreen
        navController.modalTransitionStyle = .crossDissolve
        present(navController, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension AuthenticationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == serverURLTextField {
            apiKeyTextField.becomeFirstResponder()
        } else if textField == apiKeyTextField {
            saveAPIKey()
        }
        return true
    }
}

// MARK: - Validation Error

struct ValidationError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}