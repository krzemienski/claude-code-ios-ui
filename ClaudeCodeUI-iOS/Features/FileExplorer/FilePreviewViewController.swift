//
//  FilePreviewViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/05.
//

import UIKit

class FilePreviewViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let fileNode: FileTreeNode
    private let project: Project
    private var fileContent: String = ""
    private let apiClient: APIClient
    
    // MARK: - UI Components
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = CyberpunkTheme.surface
        textView.textColor = CyberpunkTheme.primaryText
        textView.font = CyberpunkTheme.codeFont
        textView.isEditable = false
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        // Add syntax highlighting colors for common keywords
        textView.tintColor = CyberpunkTheme.primaryCyan
        
        return textView
    }()
    
    private lazy var lineNumberView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = CyberpunkTheme.background
        textView.textColor = CyberpunkTheme.secondaryText
        textView.font = CyberpunkTheme.codeFont
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8)
        textView.textAlignment = .right
        return textView
    }()
    
    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.barStyle = .black
        toolbar.isTranslucent = true
        toolbar.backgroundColor = CyberpunkTheme.surface
        
        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(toggleEditMode)
        )
        editButton.tintColor = CyberpunkTheme.primaryCyan
        
        let copyButton = UIBarButtonItem(
            image: UIImage(systemName: "doc.on.doc"),
            style: .plain,
            target: self,
            action: #selector(copyContent)
        )
        copyButton.tintColor = CyberpunkTheme.primaryCyan
        
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareContent)
        )
        shareButton.tintColor = CyberpunkTheme.primaryCyan
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [editButton, flexSpace, copyButton, shareButton]
        self.editButton = editButton
        
        return toolbar
    }()
    
    private lazy var loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = CyberpunkTheme.primaryCyan
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var editButton: UIBarButtonItem?
    private var lineNumberWidthConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    
    init(fileNode: FileTreeNode, project: Project) {
        self.fileNode = fileNode
        self.project = project
        self.apiClient = DIContainer.shared.apiClient
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadFileContent()
        
        // Observe text changes for line numbers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidChange),
            name: UITextView.textDidChangeNotification,
            object: textView
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        view.addSubview(lineNumberView)
        view.addSubview(textView)
        view.addSubview(toolbar)
        view.addSubview(loadingView)
        
        lineNumberWidthConstraint = lineNumberView.widthAnchor.constraint(equalToConstant: 50)
        
        NSLayoutConstraint.activate([
            lineNumberView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            lineNumberView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lineNumberWidthConstraint,
            lineNumberView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: lineNumberView.trailingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),
            
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Sync scrolling
        textView.delegate = self
    }
    
    private func setupNavigationBar() {
        title = fileNode.name
        navigationItem.largeTitleDisplayMode = .never
        
        let saveButton = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveFile)
        )
        saveButton.tintColor = CyberpunkTheme.primaryCyan
        navigationItem.rightBarButtonItem = saveButton
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    // MARK: - Data Loading
    
    private func loadFileContent() {
        loadingView.startAnimating()
        
        // Load mock content for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadMockContent()
            self?.loadingView.stopAnimating()
        }
    }
    
    private func loadMockContent() {
        let ext = (fileNode.name as NSString).pathExtension.lowercased()
        
        switch ext {
        case "swift":
            fileContent = """
            //
            //  \(fileNode.name)
            //  \(project.name)
            //
            
            import UIKit
            
            class ViewController: UIViewController {
                
                override func viewDidLoad() {
                    super.viewDidLoad()
                    setupUI()
                }
                
                private func setupUI() {
                    view.backgroundColor = .systemBackground
                    
                    let label = UILabel()
                    label.text = "Hello, World!"
                    label.translatesAutoresizingMaskIntoConstraints = false
                    
                    view.addSubview(label)
                    
                    NSLayoutConstraint.activate([
                        label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                        label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                    ])
                }
            }
            """
            
        case "json":
            fileContent = """
            {
              "name": "\(project.name)",
              "version": "1.0.0",
              "description": "iOS application",
              "dependencies": {
                "swift": "5.9",
                "ios": "17.0"
              },
              "scripts": {
                "build": "xcodebuild",
                "test": "xcodebuild test"
              }
            }
            """
            
        case "md":
            fileContent = """
            # \(project.name)
            
            ## Overview
            This is an iOS application built with Swift and UIKit.
            
            ## Features
            - Modern UI with cyberpunk theme
            - Real-time WebSocket communication
            - File explorer with syntax highlighting
            - Integrated terminal
            
            ## Installation
            1. Clone the repository
            2. Open in Xcode
            3. Build and run
            
            ## License
            MIT
            """
            
        default:
            fileContent = """
            // File: \(fileNode.name)
            // Path: \(fileNode.path)
            // Project: \(project.name)
            
            This is a sample file content.
            You can edit this file and save your changes.
            
            Lines of code will be displayed here with syntax highlighting.
            """
        }
        
        textView.text = fileContent
        updateLineNumbers()
        applySyntaxHighlighting()
    }
    
    // MARK: - Actions
    
    @objc private func toggleEditMode() {
        textView.isEditable.toggle()
        
        if textView.isEditable {
            editButton?.image = UIImage(systemName: "checkmark")
            textView.becomeFirstResponder()
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            editButton?.image = UIImage(systemName: "pencil")
            textView.resignFirstResponder()
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func saveFile() {
        guard textView.isEditable else { return }
        
        // TODO: Implement actual file saving via API
        fileContent = textView.text
        
        // Show success feedback
        let alert = UIAlertController(
            title: "Saved",
            message: "File saved successfully",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Exit edit mode
        toggleEditMode()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @objc private func copyContent() {
        UIPasteboard.general.string = textView.text
        
        // Show feedback
        let label = UILabel()
        label.text = "Copied to clipboard"
        label.font = CyberpunkTheme.bodyFont
        label.textColor = .white
        label.backgroundColor = CyberpunkTheme.primaryCyan
        label.textAlignment = .center
        label.layer.cornerRadius = 20
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            label.widthAnchor.constraint(equalToConstant: 200),
            label.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, delay: 1.0, options: [], animations: {
            label.alpha = 0
        }) { _ in
            label.removeFromSuperview()
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @objc private func shareContent() {
        let activityVC = UIActivityViewController(
            activityItems: [textView.text ?? ""],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = toolbar.items?.last
        }
        
        present(activityVC, animated: true)
    }
    
    @objc private func textViewDidChange() {
        updateLineNumbers()
        applySyntaxHighlighting()
    }
    
    // MARK: - Helper Methods
    
    private func updateLineNumbers() {
        let lines = textView.text.components(separatedBy: .newlines)
        let lineNumbers = (1...lines.count).map { String($0) }.joined(separator: "\n")
        lineNumberView.text = lineNumbers
        
        // Adjust width based on number of digits
        let maxDigits = String(lines.count).count
        let width = CGFloat(maxDigits * 10 + 20)
        lineNumberWidthConstraint.constant = width
    }
    
    private func applySyntaxHighlighting() {
        guard let text = textView.text else { return }
        
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.count)
        
        // Reset to default color
        attributedString.addAttribute(.foregroundColor, value: CyberpunkTheme.primaryText, range: fullRange)
        attributedString.addAttribute(.font, value: CyberpunkTheme.codeFont, range: fullRange)
        
        // Apply syntax highlighting based on file type
        let ext = (fileNode.name as NSString).pathExtension.lowercased()
        
        if ext == "swift" {
            highlightSwiftSyntax(attributedString)
        } else if ext == "json" {
            highlightJSONSyntax(attributedString)
        }
        
        textView.attributedText = attributedString
    }
    
    private func highlightSwiftSyntax(_ attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        
        // Keywords
        let keywords = ["import", "class", "struct", "enum", "func", "var", "let", "if", "else", "for", "while", "return", "override", "private", "public", "internal", "static", "self", "super", "init"]
        
        for keyword in keywords {
            let regex = try? NSRegularExpression(pattern: "\\b\(keyword)\\b", options: [])
            let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? []
            
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: CyberpunkTheme.primaryCyan, range: match.range)
            }
        }
        
        // Strings
        let stringRegex = try? NSRegularExpression(pattern: "\"[^\"]*\"", options: [])
        let stringMatches = stringRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? []
        
        for match in stringMatches {
            attributedString.addAttribute(.foregroundColor, value: CyberpunkTheme.accentPink, range: match.range)
        }
        
        // Comments
        let commentRegex = try? NSRegularExpression(pattern: "//.*$", options: [.anchorsMatchLines])
        let commentMatches = commentRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? []
        
        for match in commentMatches {
            attributedString.addAttribute(.foregroundColor, value: CyberpunkTheme.secondaryText, range: match.range)
        }
    }
    
    private func highlightJSONSyntax(_ attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        
        // Keys
        let keyRegex = try? NSRegularExpression(pattern: "\"[^\"]+\"\\s*:", options: [])
        let keyMatches = keyRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? []
        
        for match in keyMatches {
            attributedString.addAttribute(.foregroundColor, value: CyberpunkTheme.primaryCyan, range: match.range)
        }
        
        // String values
        let stringRegex = try? NSRegularExpression(pattern: ":\\s*\"[^\"]*\"", options: [])
        let stringMatches = stringRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? []
        
        for match in stringMatches {
            attributedString.addAttribute(.foregroundColor, value: CyberpunkTheme.accentPink, range: match.range)
        }
    }
}

// MARK: - UITextViewDelegate

extension FilePreviewViewController: UITextViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Sync line number scroll with text view
        if scrollView == textView {
            lineNumberView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y)
        }
    }
}