//
//  FileViewerViewController.swift
//  ClaudeCodeUI
//
//  File viewer with syntax highlighting and cyberpunk theme
//

import UIKit

public class FileViewerViewController: BaseViewController {
    
    // MARK: - Properties
    private let filePath: String
    private let fileName: String
    private let textView = UITextView()
    private let lineNumberView = UITextView()
    private let scrollView = UIScrollView()
    private let containerView = UIView()
    private var fileContent: String = ""
    
    // MARK: - Initialization
    init(filePath: String, fileName: String) {
        self.filePath = filePath
        self.fileName = fileName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFileContent()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        title = fileName
        
        // Navigation items
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "square.and.pencil"),
                style: .plain,
                target: self,
                action: #selector(editFile)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "doc.on.doc"),
                style: .plain,
                target: self,
                action: #selector(copyContent)
            )
        ]
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = CyberpunkTheme.primaryCyan }
        
        // Container setup
        scrollView.backgroundColor = CyberpunkTheme.surface
        scrollView.layer.cornerRadius = 8
        scrollView.layer.borderWidth = 1
        scrollView.layer.borderColor = CyberpunkTheme.border.cgColor
        scrollView.delegate = self
        
        // Line numbers view
        lineNumberView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        lineNumberView.textColor = CyberpunkTheme.secondaryText
        lineNumberView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        lineNumberView.isEditable = false
        lineNumberView.isSelectable = false
        lineNumberView.isScrollEnabled = false
        lineNumberView.textAlignment = .right
        lineNumberView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        // Text view
        textView.backgroundColor = .clear
        textView.textColor = CyberpunkTheme.primaryText
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(lineNumberView)
        containerView.addSubview(textView)
        
        // Setup constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        lineNumberView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            lineNumberView.topAnchor.constraint(equalTo: containerView.topAnchor),
            lineNumberView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            lineNumberView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            lineNumberView.widthAnchor.constraint(equalToConstant: 50),
            
            textView.topAnchor.constraint(equalTo: containerView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: lineNumberView.trailingAnchor),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    // MARK: - Content Loading
    private func loadFileContent() {
        // Mock content for demonstration
        let language = detectLanguage(from: fileName)
        
        // Sample code based on file extension
        if fileName.hasSuffix(".swift") {
            fileContent = """
            import UIKit
            
            class ViewController: UIViewController {
                @IBOutlet weak var titleLabel: UILabel!
                @IBOutlet weak var actionButton: UIButton!
                
                override func viewDidLoad() {
                    super.viewDidLoad()
                    setupUI()
                    loadData()
                }
                
                private func setupUI() {
                    titleLabel.text = "Hello, World!"
                    titleLabel.textColor = .systemBlue
                    
                    actionButton.setTitle("Tap Me", for: .normal)
                    actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
                }
                
                @objc private func buttonTapped() {
                    print("Button was tapped!")
                    showAlert()
                }
                
                private func showAlert() {
                    let alert = UIAlertController(title: "Success", message: "You tapped the button!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
                
                private func loadData() {
                    // Load data from API
                    APIClient.shared.fetchData { [weak self] result in
                        switch result {
                        case .success(let data):
                            self?.processData(data)
                        case .failure(let error):
                            print("Error: \\(error.localizedDescription)")
                        }
                    }
                }
                
                private func processData(_ data: [String: Any]) {
                    // Process the data
                    guard let items = data["items"] as? [[String: Any]] else { return }
                    
                    for item in items {
                        if let name = item["name"] as? String {
                            print("Item: \\(name)")
                        }
                    }
                }
            }
            """
        } else if fileName.hasSuffix(".js") || fileName.hasSuffix(".jsx") {
            fileContent = """
            import React, { useState, useEffect } from 'react';
            import './App.css';
            
            function App() {
                const [count, setCount] = useState(0);
                const [data, setData] = useState(null);
                
                useEffect(() => {
                    // Fetch data when component mounts
                    fetchData();
                }, []);
                
                const fetchData = async () => {
                    try {
                        const response = await fetch('/api/data');
                        const json = await response.json();
                        setData(json);
                    } catch (error) {
                        console.error('Error fetching data:', error);
                    }
                };
                
                const handleClick = () => {
                    setCount(prevCount => prevCount + 1);
                    console.log('Button clicked!');
                };
                
                return (
                    <div className="App">
                        <header className="App-header">
                            <h1>React Counter App</h1>
                            <p>You clicked {count} times</p>
                            <button onClick={handleClick}>
                                Click me
                            </button>
                            {data && (
                                <div>
                                    <h2>Data from API:</h2>
                                    <pre>{JSON.stringify(data, null, 2)}</pre>
                                </div>
                            )}
                        </header>
                    </div>
                );
            }
            
            export default App;
            """
        } else {
            fileContent = """
            # Sample File Content
            
            This is a sample file viewer with syntax highlighting.
            
            ## Features
            - Line numbers
            - Syntax highlighting
            - Copy to clipboard
            - Edit mode
            
            ## Supported Languages
            - Swift
            - JavaScript/TypeScript
            - Python
            - HTML/CSS
            - JSON
            - Markdown
            
            The syntax highlighting adapts based on the file extension.
            """
        }
        
        // Apply syntax highlighting
        applySyntaxHighlighting(language: language)
        
        // Update line numbers
        updateLineNumbers()
    }
    
    private func detectLanguage(from fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "js", "jsx": return "javascript"
        case "ts", "tsx": return "typescript"
        case "py": return "python"
        case "html": return "html"
        case "css", "scss", "sass": return "css"
        case "json": return "json"
        case "md", "markdown": return "markdown"
        case "java": return "java"
        case "c", "h": return "c"
        case "cpp", "cc", "hpp": return "cpp"
        case "rb": return "ruby"
        case "go": return "go"
        case "rs": return "rust"
        case "php": return "php"
        case "sql": return "sql"
        case "sh", "bash": return "bash"
        case "yml", "yaml": return "yaml"
        case "xml": return "xml"
        default: return "text"
        }
    }
    
    private func applySyntaxHighlighting(language: String) {
        let attributedString = NSMutableAttributedString(string: fileContent)
        let fullRange = NSRange(location: 0, length: fileContent.count)
        
        // Base attributes
        attributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular), range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: CyberpunkTheme.primaryText, range: fullRange)
        
        // Language-specific highlighting
        switch language {
        case "swift":
            highlightSwiftSyntax(in: attributedString)
        case "javascript", "typescript":
            highlightJavaScriptSyntax(in: attributedString)
        case "python":
            highlightPythonSyntax(in: attributedString)
        case "html", "xml":
            highlightHTMLSyntax(in: attributedString)
        case "css":
            highlightCSSSyntax(in: attributedString)
        case "json":
            highlightJSONSyntax(in: attributedString)
        case "markdown":
            highlightMarkdownSyntax(in: attributedString)
        default:
            // Basic highlighting for other languages
            highlightCommonPatterns(in: attributedString)
        }
        
        textView.attributedText = attributedString
    }
    
    private func highlightSwiftSyntax(in attributedString: NSMutableAttributedString) {
        // Keywords
        let keywords = ["import", "class", "struct", "enum", "protocol", "func", "var", "let", 
                       "if", "else", "for", "while", "switch", "case", "return", "break", "continue",
                       "private", "public", "internal", "static", "override", "init", "self", "super",
                       "@IBOutlet", "@IBAction", "@objc", "weak", "strong", "lazy", "async", "await", "throws"]
        
        for keyword in keywords {
            highlightPattern("\\b\(keyword)\\b", color: CyberpunkTheme.primaryCyan, bold: true, in: attributedString)
        }
        
        // Types
        let types = ["String", "Int", "Double", "Float", "Bool", "Any", "AnyObject", "Void",
                    "UIViewController", "UIView", "UILabel", "UIButton", "UITableView", "UICollectionView"]
        
        for type in types {
            highlightPattern("\\b\(type)\\b", color: UIColor.systemPurple, bold: false, in: attributedString)
        }
        
        // Strings
        highlightPattern("\"[^\"]*\"", color: UIColor.systemGreen, bold: false, in: attributedString)
        
        // Comments
        highlightPattern("//.*$", color: CyberpunkTheme.secondaryText, bold: false, italic: true, in: attributedString)
        highlightPattern("/\\*[\\s\\S]*?\\*/", color: CyberpunkTheme.secondaryText, bold: false, italic: true, in: attributedString)
        
        // Numbers
        highlightPattern("\\b\\d+(\\.\\d+)?\\b", color: UIColor.systemOrange, bold: false, in: attributedString)
        
        // Function calls
        highlightPattern("\\b\\w+(?=\\()", color: UIColor.systemYellow, bold: false, in: attributedString)
    }
    
    private func highlightJavaScriptSyntax(in attributedString: NSMutableAttributedString) {
        // Keywords
        let keywords = ["import", "export", "from", "function", "const", "let", "var", "class",
                       "if", "else", "for", "while", "switch", "case", "return", "break", "continue",
                       "async", "await", "try", "catch", "finally", "throw", "new", "this",
                       "true", "false", "null", "undefined"]
        
        for keyword in keywords {
            highlightPattern("\\b\(keyword)\\b", color: CyberpunkTheme.primaryCyan, bold: true, in: attributedString)
        }
        
        // Strings
        highlightPattern("'[^']*'", color: UIColor.systemGreen, bold: false, in: attributedString)
        highlightPattern("\"[^\"]*\"", color: UIColor.systemGreen, bold: false, in: attributedString)
        highlightPattern("`[^`]*`", color: UIColor.systemGreen, bold: false, in: attributedString)
        
        // Comments
        highlightPattern("//.*$", color: CyberpunkTheme.secondaryText, bold: false, italic: true, in: attributedString)
        highlightPattern("/\\*[\\s\\S]*?\\*/", color: CyberpunkTheme.secondaryText, bold: false, italic: true, in: attributedString)
        
        // Numbers
        highlightPattern("\\b\\d+(\\.\\d+)?\\b", color: UIColor.systemOrange, bold: false, in: attributedString)
        
        // JSX tags
        highlightPattern("<[^>]+>", color: CyberpunkTheme.accentPink, bold: false, in: attributedString)
    }
    
    private func highlightPythonSyntax(in attributedString: NSMutableAttributedString) {
        // Keywords
        let keywords = ["import", "from", "as", "def", "class", "if", "elif", "else",
                       "for", "while", "return", "break", "continue", "pass", "try",
                       "except", "finally", "raise", "with", "lambda", "yield",
                       "True", "False", "None", "and", "or", "not", "in", "is"]
        
        for keyword in keywords {
            highlightPattern("\\b\(keyword)\\b", color: CyberpunkTheme.primaryCyan, bold: true, in: attributedString)
        }
        
        // Strings
        highlightPattern("'[^']*'", color: UIColor.systemGreen, bold: false, in: attributedString)
        highlightPattern("\"[^\"]*\"", color: UIColor.systemGreen, bold: false, in: attributedString)
        highlightPattern("'''[\\s\\S]*?'''", color: UIColor.systemGreen, bold: false, in: attributedString)
        highlightPattern("\"\"\"[\\s\\S]*?\"\"\"", color: UIColor.systemGreen, bold: false, in: attributedString)
        
        // Comments
        highlightPattern("#.*$", color: CyberpunkTheme.secondaryText, bold: false, italic: true, in: attributedString)
        
        // Numbers
        highlightPattern("\\b\\d+(\\.\\d+)?\\b", color: UIColor.systemOrange, bold: false, in: attributedString)
    }
    
    private func highlightHTMLSyntax(in attributedString: NSMutableAttributedString) {
        // Tags
        highlightPattern("</?\\w+[^>]*>", color: CyberpunkTheme.accentPink, bold: false, in: attributedString)
        
        // Attributes
        highlightPattern("\\w+(?=\\=)", color: UIColor.systemYellow, bold: false, in: attributedString)
        
        // Strings
        highlightPattern("\"[^\"]*\"", color: UIColor.systemGreen, bold: false, in: attributedString)
        highlightPattern("'[^']*'", color: UIColor.systemGreen, bold: false, in: attributedString)
        
        // Comments
        highlightPattern("<!--[\\s\\S]*?-->", color: CyberpunkTheme.secondaryText, bold: false, italic: true, in: attributedString)
    }
    
    private func highlightCSSSyntax(in attributedString: NSMutableAttributedString) {
        // Selectors
        highlightPattern("[.#]?\\w+[\\s{]", color: CyberpunkTheme.primaryCyan, bold: true, in: attributedString)
        
        // Properties
        highlightPattern("\\w+(?=:)", color: UIColor.systemPurple, bold: false, in: attributedString)
        
        // Values
        highlightPattern(":[^;]+;", color: UIColor.systemGreen, bold: false, in: attributedString)
        
        // Comments
        highlightPattern("/\\*[\\s\\S]*?\\*/", color: CyberpunkTheme.secondaryText, bold: false, italic: true, in: attributedString)
    }
    
    private func highlightJSONSyntax(in attributedString: NSMutableAttributedString) {
        // Keys
        highlightPattern("\"\\w+\"(?=:)", color: CyberpunkTheme.primaryCyan, bold: true, in: attributedString)
        
        // Strings
        highlightPattern("\"[^\"]*\"", color: UIColor.systemGreen, bold: false, in: attributedString)
        
        // Numbers
        highlightPattern("\\b\\d+(\\.\\d+)?\\b", color: UIColor.systemOrange, bold: false, in: attributedString)
        
        // Booleans and null
        highlightPattern("\\b(true|false|null)\\b", color: CyberpunkTheme.accentPink, bold: false, in: attributedString)
    }
    
    private func highlightMarkdownSyntax(in attributedString: NSMutableAttributedString) {
        // Headers
        highlightPattern("^#{1,6}.*$", color: CyberpunkTheme.primaryCyan, bold: true, in: attributedString)
        
        // Bold
        highlightPattern("\\*\\*[^\\*]+\\*\\*", color: CyberpunkTheme.primaryText, bold: true, in: attributedString)
        
        // Italic
        highlightPattern("\\*[^\\*]+\\*", color: CyberpunkTheme.primaryText, bold: false, italic: true, in: attributedString)
        
        // Code blocks
        highlightPattern("`[^`]+`", color: UIColor.systemGreen, bold: false, in: attributedString)
        highlightPattern("```[\\s\\S]*?```", color: UIColor.systemGreen, bold: false, in: attributedString)
        
        // Links
        highlightPattern("\\[([^\\]]+)\\]\\(([^\\)]+)\\)", color: CyberpunkTheme.accentPink, bold: false, in: attributedString)
        
        // Lists
        highlightPattern("^[\\*\\-\\+]\\s", color: CyberpunkTheme.primaryCyan, bold: false, in: attributedString)
        highlightPattern("^\\d+\\.\\s", color: CyberpunkTheme.primaryCyan, bold: false, in: attributedString)
    }
    
    private func highlightCommonPatterns(in attributedString: NSMutableAttributedString) {
        // Strings
        highlightPattern("\"[^\"]*\"", color: UIColor.systemGreen, bold: false, in: attributedString)
        highlightPattern("'[^']*'", color: UIColor.systemGreen, bold: false, in: attributedString)
        
        // Numbers
        highlightPattern("\\b\\d+(\\.\\d+)?\\b", color: UIColor.systemOrange, bold: false, in: attributedString)
        
        // Comments (common patterns)
        highlightPattern("//.*$", color: CyberpunkTheme.secondaryText, bold: false, italic: true, in: attributedString)
        highlightPattern("#.*$", color: CyberpunkTheme.secondaryText, bold: false, italic: true, in: attributedString)
        highlightPattern("/\\*[\\s\\S]*?\\*/", color: CyberpunkTheme.secondaryText, bold: false, italic: true, in: attributedString)
    }
    
    private func highlightPattern(_ pattern: String, color: UIColor, bold: Bool, italic: Bool = false, in attributedString: NSMutableAttributedString) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
            let matches = regex.matches(in: attributedString.string, options: [], range: NSRange(location: 0, length: attributedString.length))
            
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
                
                if bold || italic {
                    var traits: UIFontDescriptor.SymbolicTraits = []
                    if bold { traits.insert(.traitBold) }
                    if italic { traits.insert(.traitItalic) }
                    
                    if let font = UIFont.monospacedSystemFont(ofSize: 14, weight: bold ? .semibold : .regular).fontDescriptor.withSymbolicTraits(traits) {
                        attributedString.addAttribute(.font, value: UIFont(descriptor: font, size: 14), range: match.range)
                    }
                }
            }
        } catch {
            print("Error creating regex pattern: \(error)")
        }
    }
    
    private func updateLineNumbers() {
        let lines = fileContent.components(separatedBy: .newlines)
        var lineNumbersText = ""
        
        for i in 1...lines.count {
            lineNumbersText += "\(i)\n"
        }
        
        lineNumberView.text = lineNumbersText
    }
    
    // MARK: - Actions
    @objc private func editFile() {
        let alert = UIAlertController(
            title: "Edit Mode",
            message: "File editing is not yet implemented",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func copyContent() {
        UIPasteboard.general.string = fileContent
        
        // Show feedback
        let alert = UIAlertController(
            title: "Copied",
            message: "File content copied to clipboard",
            preferredStyle: .alert
        )
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - UIScrollViewDelegate
extension FileViewerViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Sync line numbers scroll with text view scroll
        lineNumberView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y)
    }
}