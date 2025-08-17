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
                let status = try await APIClient.shared.getGitStatus(projectPath: project.fullPath)
                await MainActor.run {
                    self.parseGitStatus(status)
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
                let branchData = try await APIClient.shared.getGitBranches(projectPath: project.fullPath)
                await MainActor.run {
                    self.parseGitBranches(branchData)
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
                let commitData = try await APIClient.shared.getGitLog(projectPath: project.fullPath)
                await MainActor.run {
                    self.parseGitCommits(commitData)
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
                try await APIClient.shared.gitAdd(
                    projectPath: project.fullPath,
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
                try await APIClient.shared.gitReset(
                    projectPath: project.fullPath,
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
                try await APIClient.shared.gitCommit(
                    projectPath: project.fullPath,
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
                try await APIClient.shared.gitPull(projectPath: project.fullPath)
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
                try await APIClient.shared.gitPush(projectPath: project.fullPath)
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
                try await APIClient.shared.gitCheckout(
                    projectPath: project.fullPath,
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
    
    private func parseGitStatus(_ statusData: [String: Any]) {
        var sections: [GitStatusSection] = []
        
        // Parse staged changes
        if let staged = statusData["staged"] as? [[String: Any]], !staged.isEmpty {
            let stagedFiles = staged.compactMap { fileData -> GitFile? in
                guard let path = fileData["path"] as? String,
                      let status = fileData["status"] as? String else { return nil }
                return GitFile(path: path, status: status, isStaged: true)
            }
            sections.append(GitStatusSection(title: "Staged Changes", files: stagedFiles))
        }
        
        // Parse unstaged changes
        if let unstaged = statusData["unstaged"] as? [[String: Any]], !unstaged.isEmpty {
            let unstagedFiles = unstaged.compactMap { fileData -> GitFile? in
                guard let path = fileData["path"] as? String,
                      let status = fileData["status"] as? String else { return nil }
                return GitFile(path: path, status: status, isStaged: false)
            }
            sections.append(GitStatusSection(title: "Changes", files: unstagedFiles))
        }
        
        // Parse untracked files
        if let untracked = statusData["untracked"] as? [String], !untracked.isEmpty {
            let untrackedFiles = untracked.map { path in
                GitFile(path: path, status: "untracked", isStaged: false)
            }
            sections.append(GitStatusSection(title: "Untracked Files", files: untrackedFiles))
        }
        
        // Update current branch
        if let branch = statusData["branch"] as? String {
            currentBranch = branch
        }
        
        statusSections = sections
    }
    
    private func parseGitBranches(_ branchData: [String: Any]) {
        var parsedBranches: [GitBranch] = []
        
        // Parse local branches
        if let local = branchData["local"] as? [[String: Any]] {
            let localBranches = local.compactMap { branch -> GitBranch? in
                guard let name = branch["name"] as? String else { return nil }
                let lastCommit = branch["lastCommit"] as? String
                return GitBranch(name: name, isRemote: false, lastCommit: lastCommit)
            }
            parsedBranches.append(contentsOf: localBranches)
        }
        
        // Parse remote branches
        if let remote = branchData["remote"] as? [[String: Any]] {
            let remoteBranches = remote.compactMap { branch -> GitBranch? in
                guard let name = branch["name"] as? String else { return nil }
                let lastCommit = branch["lastCommit"] as? String
                return GitBranch(name: name, isRemote: true, lastCommit: lastCommit)
            }
            parsedBranches.append(contentsOf: remoteBranches)
        }
        
        // Update current branch if provided
        if let current = branchData["current"] as? String {
            currentBranch = current
        }
        
        branches = parsedBranches
    }
    
    private func parseGitCommits(_ commitData: [[String: Any]]) {
        commits = commitData.compactMap { commit -> GitCommit? in
            guard let sha = commit["sha"] as? String,
                  let message = commit["message"] as? String,
                  let author = commit["author"] as? String,
                  let date = commit["date"] as? String else { return nil }
            
            return GitCommit(
                sha: sha,
                message: message,
                author: author,
                date: formatDate(date)
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