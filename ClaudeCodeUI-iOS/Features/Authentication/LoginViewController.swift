//
//  LoginViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

class LoginViewController: BaseViewController {
    
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
        label.text = "Login to continue"
        label.font = CyberpunkTheme.bodyFont
        label.textColor = CyberpunkTheme.secondaryText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = CyberpunkTheme.surface
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = CyberpunkTheme.border.cgColor
        return view
    }()
    
    private lazy var usernameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Username"
        textField.font = CyberpunkTheme.codeFont
        textField.textColor = CyberpunkTheme.primaryText
        textField.tintColor = CyberpunkTheme.primaryCyan
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .next
        textField.delegate = self
        
        // Style placeholder
        textField.attributedPlaceholder = NSAttributedString(
            string: "Username",
            attributes: [
                .foregroundColor: CyberpunkTheme.secondaryText,
                .font: CyberpunkTheme.codeFont
            ]
        )
        
        // Add padding
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Password"
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
            string: "Password",
            attributes: [
                .foregroundColor: CyberpunkTheme.secondaryText,
                .font: CyberpunkTheme.codeFont
            ]
        )
        
        // Add padding
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private lazy var loginButton: NeonButton = {
        let button = NeonButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Login", for: .normal)
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        return button
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = CyberpunkTheme.primaryCyan
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Properties
    
    private let errorHandler: ErrorHandlingService
    private let dataContainer: SwiftDataContainer?
    private var isLoginInProgress = false
    
    // MARK: - Initialization
    
    @MainActor
    init(errorHandler: ErrorHandlingService? = nil,
         dataContainer: SwiftDataContainer? = nil) {
        self.errorHandler = errorHandler ?? DIContainer.shared.errorHandler
        self.dataContainer = dataContainer ?? DIContainer.shared.dataContainer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Set default username for testing
        #if DEBUG
        usernameTextField.text = "admin"
        passwordTextField.text = "admin123"
        
        // Auto-bypass login in development mode for testing
        if ProcessInfo.processInfo.environment["BYPASS_LOGIN"] == "true" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.bypassLogin()
            }
        }
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateLogoGlow()
        usernameTextField.becomeFirstResponder()
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
        view.addSubview(containerView)
        view.addSubview(activityIndicator)
        
        // Add text fields to container
        containerView.addSubview(usernameTextField)
        containerView.addSubview(passwordTextField)
        containerView.addSubview(loginButton)
        
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
            
            // Container
            containerView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // Username text field
            usernameTextField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            usernameTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            usernameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            usernameTextField.heightAnchor.constraint(equalToConstant: 56),
            
            // Divider
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor),
            passwordTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 56),
            
            // Login button
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            loginButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            loginButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor)
        ])
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Animations
    
    private func animateLogoGlow() {
        UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.logoImageView.layer.shadowOpacity = 0.8
        })
    }
    
    // MARK: - Actions
    
    @objc private func handleLogin() {
        guard !isLoginInProgress else { return }
        
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            errorHandler.handle(ValidationError.emptyField(fieldName: "Username and password"))
            return
        }
        
        dismissKeyboard()
        setLoginInProgress(true)
        
        Task {
            do {
                // Make login request
                let apiClient = DIContainer.shared.apiClient
                let response: AuthResponse = try await apiClient.request(.login(username: username, password: password))
                
                guard response.success, let token = response.token else {
                    throw APIError.serverError("Login failed")
                }
                
                // Save auth token
                await apiClient.setAuthToken(token)
                
                // Save to settings
                if let dataContainer = dataContainer {
                    let settings = try await dataContainer.fetchSettings()
                    settings.authToken = token
                    // Username is not stored in settings - could be added if needed
                    try await dataContainer.updateSettings(settings)
                }
                
                // Navigate to main app
                await proceedToMainApp()
                
            } catch {
                await MainActor.run {
                    setLoginInProgress(false)
                    errorHandler.handle(error)
                }
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setLoginInProgress(_ inProgress: Bool) {
        isLoginInProgress = inProgress
        
        UIView.animate(withDuration: 0.3) {
            self.loginButton.alpha = inProgress ? 0 : 1
            self.usernameTextField.isEnabled = !inProgress
            self.passwordTextField.isEnabled = !inProgress
        }
        
        if inProgress {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    @MainActor
    private func proceedToMainApp() {
        // Create the main tab bar controller
        let mainTabBarController = MainTabBarController()
        mainTabBarController.modalPresentationStyle = .fullScreen
        mainTabBarController.modalTransitionStyle = .crossDissolve
        present(mainTabBarController, animated: true)
    }
    
    #if DEBUG
    private func bypassLogin() {
        // Set a fake JWT token for development testing
        let fakeToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJkZXZfdXNlciIsInVzZXJuYW1lIjoiZGV2IiwiaWF0IjoxNzM2ODY0MDAwLCJleHAiOjE3MzY5NTA0MDB9.fake_signature"
        
        Task {
            // Save fake auth token
            let apiClient = DIContainer.shared.apiClient
            await apiClient.setAuthToken(fakeToken)
            
            // Save to settings
            if let dataContainer = dataContainer {
                if let settings = try? await dataContainer.fetchSettings() {
                    settings.authToken = fakeToken
                    // Username is not stored in settings - could be added if needed
                    try? await dataContainer.updateSettings(settings)
                }
            }
            
            // Navigate to main app
            await proceedToMainApp()
        }
    }
    #endif
}

// MARK: - UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            handleLogin()
        }
        return true
    }
}