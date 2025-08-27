//
//  GitViewModel.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import Foundation
import Combine

// MARK: - Data Models

struct GitFile {
    let path: String
    let status: String
    let isStaged: Bool
}

struct GitBranch {
    let name: String
    let isRemote: Bool
    let lastCommit: String?
}

struct GitCommit {
    let sha: String
    let message: String
    let author: String
    let date: String
}

struct GitStatusSection {
    let title: String
    let files: [GitFile]
}

// MARK: - View Model

class GitViewModel: ObservableObject {
    
    // MARK: - Properties
    
    private let project: Project?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    @Published var statusSections: [GitStatusSection] = []
    @Published var branches: [GitBranch] = []
    @Published var commits: [GitCommit] = []
    @Published var currentBranch: String = "main"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Callbacks for UIKit Integration
    
    var onStatusUpdate: (() -> Void)?
    var onBranchesUpdate: (() -> Void)?
    var onCommitsUpdate: (() -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    
    // MARK: - Initialization
    
    init(project: Project?) {
        self.project = project
    }
    
    // MARK: - Public Methods
    
    func loadStatus() {
        guard let project = project else {
            handleError("No project selected")
            return
        }
        
        setLoading(true)
        
        Task {
            do {
                let status = try await APIClient.shared.getGitStatus(projectPath: project.fullPath ?? project.path)
                await MainActor.run {
                    if let gitStatus = status.status {
                        self.parseGitStatus(gitStatus)
                    }
                    self.setLoading(false)
                    self.onStatusUpdate?()
                }
            } catch {
                await MainActor.run {
                    self.handleError("Failed to load Git status: \(error.localizedDescription)")
                    self.setLoading(false)
                }
            }
        }
    }
    
    func loadBranches() {
        guard let project = project else {
            handleError("No project selected")
            return
        }
        
        setLoading(true)
        
        Task {
            do {
                let branchData = try await APIClient.shared.getBranches(projectPath: project.fullPath ?? project.path)
                await MainActor.run {
                    if let branches = branchData.branches {
                        self.parseGitBranches(branches)
                    }
                    self.setLoading(false)
                    self.onBranchesUpdate?()
                }
            } catch {
                await MainActor.run {
                    self.handleError("Failed to load branches: \(error.localizedDescription)")
                    self.setLoading(false)
                }
            }
        }
    }
    
    func loadCommits() {
        guard let project = project else {
            handleError("No project selected")
            return
        }
        
        setLoading(true)
        
        Task {
            do {
                let commitData = try await APIClient.shared.getLog(projectPath: project.fullPath ?? project.path)
                await MainActor.run {
                    if let commits = commitData.commits {
                        self.parseGitCommits(commits)
                    }
                    self.setLoading(false)
                    self.onCommitsUpdate?()
                }
            } catch {
                await MainActor.run {
                    self.handleError("Failed to load commits: \(error.localizedDescription)")
                    self.setLoading(false)
                }
            }
        }
    }
    
    func hasChangesToCommit() -> Bool {
        return statusSections.contains { section in
            section.title == "Staged Changes" && !section.files.isEmpty
        }
    }
    
    func stageFile(_ filePath: String) {
        guard let project = project else { return }
        
        Task {
            do {
                try await APIClient.shared.addFiles(
                    projectPath: project.fullPath ?? project.path,
                    files: [filePath]
                )
                await MainActor.run {
                    self.loadStatus()
                }
            } catch {
                await MainActor.run {
                    self.handleError("Failed to stage file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func unstageFile(_ filePath: String) {
        guard let project = project else { return }
        
        Task {
            do {
                try await APIClient.shared.resetFiles(
                    projectPath: project.fullPath ?? project.path,
                    files: [filePath]
                )
                await MainActor.run {
                    self.loadStatus()
                }
            } catch {
                await MainActor.run {
                    self.handleError("Failed to unstage file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func commit(message: String, completion: @escaping (Bool) -> Void) {
        guard let project = project else {
            completion(false)
            return
        }
        
        setLoading(true)
        
        Task {
            do {
                try await APIClient.shared.commitChanges(
                    projectPath: project.fullPath ?? project.path,
                    message: message
                )
                await MainActor.run {
                    self.setLoading(false)
                    self.loadStatus()
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.handleError("Failed to commit: \(error.localizedDescription)")
                    self.setLoading(false)
                    completion(false)
                }
            }
        }
    }
    
    func pull(completion: @escaping (Bool) -> Void) {
        guard let project = project else {
            completion(false)
            return
        }
        
        setLoading(true)
        
        Task {
            do {
                try await APIClient.shared.pullChanges(projectPath: project.fullPath ?? project.path)
                await MainActor.run {
                    self.setLoading(false)
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.handleError("Failed to pull: \(error.localizedDescription)")
                    self.setLoading(false)
                    completion(false)
                }
            }
        }
    }
    
    func push(completion: @escaping (Bool) -> Void) {
        guard let project = project else {
            completion(false)
            return
        }
        
        setLoading(true)
        
        Task {
            do {
                try await APIClient.shared.pushChanges(projectPath: project.fullPath ?? project.path)
                await MainActor.run {
                    self.setLoading(false)
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.handleError("Failed to push: \(error.localizedDescription)")
                    self.setLoading(false)
                    completion(false)
                }
            }
        }
    }
    
    func checkoutBranch(_ branchName: String, completion: @escaping (Bool) -> Void) {
        guard let project = project else {
            completion(false)
            return
        }
        
        setLoading(true)
        
        Task {
            do {
                try await APIClient.shared.checkoutBranch(
                    projectPath: project.fullPath ?? project.path,
                    branch: branchName
                )
                await MainActor.run {
                    self.currentBranch = branchName
                    self.setLoading(false)
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.handleError("Failed to checkout branch: \(error.localizedDescription)")
                    self.setLoading(false)
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setLoading(_ loading: Bool) {
        isLoading = loading
        onLoading?(loading)
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        onError?(message)
    }
    
    private func parseGitStatus(_ statusData: GitStatus) {
        var sections: [GitStatusSection] = []
        
        // Parse staged changes
        if !statusData.staged.isEmpty {
            let stagedFiles = statusData.staged.map { path in
                GitFile(path: path, status: "staged", isStaged: true)
            }
            sections.append(GitStatusSection(title: "Staged Changes", files: stagedFiles))
        }
        
        // Parse modified files (unstaged changes)
        if !statusData.modified.isEmpty {
            let modifiedFiles = statusData.modified.map { path in
                GitFile(path: path, status: "modified", isStaged: false)
            }
            sections.append(GitStatusSection(title: "Changes", files: modifiedFiles))
        }
        
        // Parse untracked files
        if !statusData.untracked.isEmpty {
            let untrackedFiles = statusData.untracked.map { path in
                GitFile(path: path, status: "untracked", isStaged: false)
            }
            sections.append(GitStatusSection(title: "Untracked Files", files: untrackedFiles))
        }
        
        // Update current branch
        currentBranch = statusData.branch
        
        statusSections = sections
    }
    
    private func parseGitBranches(_ branchData: [APIGitBranch]) {
        var parsedBranches: [GitBranch] = []
        
        // Convert API branches to GitBranch
        for branch in branchData {
            let gitBranch = GitBranch(
                name: branch.name, 
                isRemote: false,  // API doesn't distinguish, all are local
                lastCommit: nil   // API doesn't provide last commit info
            )
            parsedBranches.append(gitBranch)
            
            // Update current branch if it's marked as current
            if branch.current {
                currentBranch = branch.name
            }
        }
        
        branches = parsedBranches
    }
    
    private func parseGitCommits(_ commitData: [APIGitCommit]) {
        commits = commitData.map { commit in
            GitCommit(
                sha: commit.hash,
                message: commit.message,
                author: commit.author,
                date: formatDate(commit.date)
            )
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Parse ISO date and format for display
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Mock Data for Testing

extension GitViewModel {
    func loadMockData() {
        // Mock status
        statusSections = [
            GitStatusSection(
                title: "Staged Changes",
                files: [
                    GitFile(path: "README.md", status: "modified", isStaged: true),
                    GitFile(path: "src/main.swift", status: "added", isStaged: true)
                ]
            ),
            GitStatusSection(
                title: "Changes",
                files: [
                    GitFile(path: "Package.swift", status: "modified", isStaged: false),
                    GitFile(path: "Tests/test.swift", status: "deleted", isStaged: false)
                ]
            ),
            GitStatusSection(
                title: "Untracked Files",
                files: [
                    GitFile(path: ".env.local", status: "untracked", isStaged: false),
                    GitFile(path: "docs/notes.txt", status: "untracked", isStaged: false)
                ]
            )
        ]
        
        // Mock branches
        branches = [
            GitBranch(name: "main", isRemote: false, lastCommit: "abc123"),
            GitBranch(name: "feature/new-ui", isRemote: false, lastCommit: "def456"),
            GitBranch(name: "bugfix/crash-fix", isRemote: false, lastCommit: "ghi789"),
            GitBranch(name: "origin/main", isRemote: true, lastCommit: "abc123"),
            GitBranch(name: "origin/develop", isRemote: true, lastCommit: "jkl012")
        ]
        
        // Mock commits
        commits = [
            GitCommit(
                sha: "abc1234567890",
                message: "Add new feature for Git integration",
                author: "John Doe",
                date: "Jan 16, 2025 at 10:30 AM"
            ),
            GitCommit(
                sha: "def0987654321",
                message: "Fix crash in chat view controller",
                author: "Jane Smith",
                date: "Jan 15, 2025 at 3:45 PM"
            ),
            GitCommit(
                sha: "ghi1357924680",
                message: "Update documentation and clean up code",
                author: "Bob Johnson",
                date: "Jan 14, 2025 at 9:15 AM"
            )
        ]
        
        currentBranch = "main"
        onStatusUpdate?()
        onBranchesUpdate?()
        onCommitsUpdate?()
    }
}