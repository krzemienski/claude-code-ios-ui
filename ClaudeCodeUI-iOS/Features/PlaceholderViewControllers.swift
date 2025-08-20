//
//  PlaceholderViewControllers.swift
//  ClaudeCodeUI
//
//  Temporary placeholder view controllers to allow the app to build
//

import UIKit

// MARK: - ProjectsViewController
class ProjectsViewController: UIViewController {
    var onProjectSelected: ((Project) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Projects"
    }
}

// MARK: - SettingsViewController  
class SettingsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Settings"
    }
}

// MARK: - TranscriptionViewController
class TranscriptionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Transcription"
    }
}

// MARK: - MCPServerListViewController
class MCPServerListViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "MCP Servers"
    }
}

// MARK: - SearchViewController
class SearchViewController: UIViewController {
    init(project: Project?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Search"
    }
}

// MARK: - TerminalViewController
// Already implemented in Features/Terminal/TerminalViewController.swift

// MARK: - GitViewController
class GitViewController: UIViewController {
    init(project: Project?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Git"
    }
}

// MARK: - SessionListViewController (for navigation)
// Already implemented in Features/Sessions/SessionListViewController.swift