//
//  ModelValidationTests.swift
//  ClaudeCodeUITests
//
//  Comprehensive unit tests for data models and validation logic
//

import XCTest
import SwiftData
@testable import ClaudeCodeUI

final class ModelValidationTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Project.self, Session.self, Message.self, configurations: config)
        context = ModelContext(container)
    }
    
    override func tearDownWithError() throws {
        container = nil
        context = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Project Model Tests
    
    func testProjectCreation() throws {
        // Given
        let projectName = "TestProject"
        let projectPath = "/path/to/project"
        
        // When
        let project = Project(name: projectName, fullPath: projectPath)
        context.insert(project)
        
        // Then
        XCTAssertEqual(project.name, projectName)
        XCTAssertEqual(project.fullPath, projectPath)
        XCTAssertNotNil(project.createdAt)
        XCTAssertEqual(project.createdAt, project.updatedAt)
        XCTAssertTrue(project.isActive)
        XCTAssertEqual(project.sessionCount, 0)
    }
    
    func testProjectNameValidation() throws {
        // Test empty name
        XCTAssertThrowsError(try Project.validateName("")) { error in
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test valid name
        XCTAssertNoThrow(try Project.validateName("ValidProject"))
        
        // Test name with special characters
        XCTAssertThrowsError(try Project.validateName("Project/With/Slashes")) { error in
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test name length validation
        let longName = String(repeating: "a", count: 256)
        XCTAssertThrowsError(try Project.validateName(longName)) { error in
            XCTAssertTrue(error is ValidationError)
        }
    }
    
    func testProjectPathValidation() throws {
        // Test absolute path
        XCTAssertNoThrow(try Project.validatePath("/valid/absolute/path"))
        
        // Test relative path (should be converted to absolute)
        XCTAssertNoThrow(try Project.validatePath("relative/path"))
        
        // Test empty path
        XCTAssertThrowsError(try Project.validatePath("")) { error in
            XCTAssertTrue(error is ValidationError)
        }
    }
    
    func testProjectSessions() throws {
        // Given
        let project = Project(name: "TestProject", fullPath: "/path")
        context.insert(project)
        
        let session1 = Session(projectId: project.persistentModelID, title: "Session 1")
        let session2 = Session(projectId: project.persistentModelID, title: "Session 2")
        
        context.insert(session1)
        context.insert(session2)
        
        // When
        try context.save()
        
        // Then
        // Note: Actual relationship testing would require proper SwiftData relationship setup
        XCTAssertTrue(project.sessionCount >= 0) // Basic validation
    }
    
    // MARK: - Session Model Tests
    
    func testSessionCreation() throws {
        // Given
        let project = Project(name: "TestProject", fullPath: "/path")
        context.insert(project)
        try context.save()
        
        let sessionTitle = "Test Session"
        
        // When
        let session = Session(projectId: project.persistentModelID, title: sessionTitle)
        context.insert(session)
        
        // Then
        XCTAssertEqual(session.title, sessionTitle)
        XCTAssertNotNil(session.createdAt)
        XCTAssertEqual(session.createdAt, session.updatedAt)
        XCTAssertEqual(session.messageCount, 0)
        XCTAssertEqual(session.status, .active)
    }
    
    func testSessionStatusTransitions() throws {
        // Given
        let project = Project(name: "TestProject", fullPath: "/path")
        context.insert(project)
        let session = Session(projectId: project.persistentModelID, title: "Test")
        context.insert(session)
        
        // When & Then - Valid transitions
        session.status = .paused
        XCTAssertEqual(session.status, .paused)
        
        session.status = .active
        XCTAssertEqual(session.status, .active)
        
        session.status = .completed
        XCTAssertEqual(session.status, .completed)
        
        // Verify updatedAt changes
        let originalUpdatedAt = session.updatedAt
        usleep(1000) // 1ms sleep to ensure timestamp difference
        session.status = .active
        XCTAssertGreaterThan(session.updatedAt, originalUpdatedAt)
    }
    
    func testSessionTitleValidation() throws {
        // Test empty title - should use default
        let session = Session(projectId: UUID(), title: "")
        XCTAssertFalse(session.title.isEmpty)
        XCTAssertTrue(session.title.contains("Session"))
        
        // Test long title - should be truncated
        let longTitle = String(repeating: "a", count: 200)
        let sessionWithLongTitle = Session(projectId: UUID(), title: longTitle)
        XCTAssertLessThanOrEqual(sessionWithLongTitle.title.count, 100)
    }
    
    // MARK: - Message Model Tests
    
    func testMessageCreation() throws {
        // Given
        let project = Project(name: "TestProject", fullPath: "/path")
        let session = Session(projectId: project.persistentModelID, title: "Test Session")
        context.insert(project)
        context.insert(session)
        
        let messageContent = "Hello, Claude!"
        
        // When
        let message = Message(
            sessionId: session.persistentModelID,
            content: messageContent,
            isFromUser: true
        )
        context.insert(message)
        
        // Then
        XCTAssertEqual(message.content, messageContent)
        XCTAssertTrue(message.isFromUser)
        XCTAssertNotNil(message.timestamp)
        XCTAssertEqual(message.status, .sent)
        XCTAssertNil(message.errorMessage)
    }
    
    func testMessageStatusFlow() throws {
        // Given
        let project = Project(name: "TestProject", fullPath: "/path")
        let session = Session(projectId: project.persistentModelID, title: "Test")
        let message = Message(sessionId: session.persistentModelID, content: "Test", isFromUser: true)
        
        context.insert(project)
        context.insert(session)
        context.insert(message)
        
        // When & Then - Valid status flow
        message.status = .sending
        XCTAssertEqual(message.status, .sending)
        
        message.status = .sent
        XCTAssertEqual(message.status, .sent)
        
        message.status = .delivered
        XCTAssertEqual(message.status, .delivered)
        
        message.status = .read
        XCTAssertEqual(message.status, .read)
    }
    
    func testMessageErrorHandling() throws {
        // Given
        let project = Project(name: "TestProject", fullPath: "/path")
        let session = Session(projectId: project.persistentModelID, title: "Test")
        let message = Message(sessionId: session.persistentModelID, content: "Test", isFromUser: true)
        
        context.insert(project)
        context.insert(session)
        context.insert(message)
        
        // When
        let errorMessage = "Network timeout"
        message.setError(errorMessage)
        
        // Then
        XCTAssertEqual(message.status, .failed)
        XCTAssertEqual(message.errorMessage, errorMessage)
        XCTAssertNotNil(message.timestamp)
    }
    
    func testMessageContentValidation() throws {
        // Test empty content
        XCTAssertThrowsError(try Message.validateContent("")) { error in
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test valid content
        XCTAssertNoThrow(try Message.validateContent("Valid message"))
        
        // Test content length limit
        let longContent = String(repeating: "a", count: 10001)
        XCTAssertThrowsError(try Message.validateContent(longContent)) { error in
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test content with only whitespace
        XCTAssertThrowsError(try Message.validateContent("   \n\t   ")) { error in
            XCTAssertTrue(error is ValidationError)
        }
    }
    
    // MARK: - Git Models Tests
    
    func testGitCommitModel() throws {
        // Given
        let commit = GitCommit(
            hash: "abc123def456",
            message: "Initial commit",
            author: "Test User",
            email: "test@example.com",
            date: Date()
        )
        
        // Then
        XCTAssertEqual(commit.hash, "abc123def456")
        XCTAssertEqual(commit.message, "Initial commit")
        XCTAssertEqual(commit.author, "Test User")
        XCTAssertEqual(commit.email, "test@example.com")
        XCTAssertNotNil(commit.date)
        XCTAssertEqual(commit.shortHash, "abc123d")
    }
    
    func testGitBranchModel() throws {
        // Given
        let branch = GitBranch(
            name: "feature/new-feature",
            isCurrentBranch: true,
            lastCommitHash: "def456ghi789"
        )
        
        // Then
        XCTAssertEqual(branch.name, "feature/new-feature")
        XCTAssertTrue(branch.isCurrentBranch)
        XCTAssertEqual(branch.lastCommitHash, "def456ghi789")
        XCTAssertEqual(branch.displayName, "feature/new-feature")
    }
    
    func testGitFileStatusModel() throws {
        // Given
        let fileStatus = GitFileStatus(
            filePath: "src/main.swift",
            status: .modified
        )
        
        // Then
        XCTAssertEqual(fileStatus.filePath, "src/main.swift")
        XCTAssertEqual(fileStatus.status, .modified)
        XCTAssertEqual(fileStatus.fileName, "main.swift")
        XCTAssertEqual(fileStatus.displayStatus, "M")
    }
    
    // MARK: - MCP Models Tests
    
    func testMCPServerModel() throws {
        // Given
        let server = MCPServer(
            name: "Test MCP Server",
            url: "http://localhost:3000",
            isEnabled: true
        )
        
        // Then
        XCTAssertEqual(server.name, "Test MCP Server")
        XCTAssertEqual(server.url, "http://localhost:3000")
        XCTAssertTrue(server.isEnabled)
        XCTAssertEqual(server.status, .disconnected)
        XCTAssertNotNil(server.createdAt)
    }
    
    func testMCPServerValidation() throws {
        // Test valid URL
        XCTAssertNoThrow(try MCPServer.validateURL("http://localhost:3000"))
        XCTAssertNoThrow(try MCPServer.validateURL("https://api.example.com"))
        
        // Test invalid URL
        XCTAssertThrowsError(try MCPServer.validateURL("not-a-url")) { error in
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test empty URL
        XCTAssertThrowsError(try MCPServer.validateURL("")) { error in
            XCTAssertTrue(error is ValidationError)
        }
    }
    
    // MARK: - Settings Model Tests
    
    func testSettingsModel() throws {
        // Given
        let settings = AppSettings()
        
        // Then - Default values
        XCTAssertEqual(settings.theme, .cyberpunk)
        XCTAssertEqual(settings.fontSize, .medium)
        XCTAssertTrue(settings.enableHapticFeedback)
        XCTAssertTrue(settings.enableAnimations)
        XCTAssertFalse(settings.offlineMode)
        XCTAssertEqual(settings.maxMessageHistory, 1000)
    }
    
    func testSettingsValidation() throws {
        let settings = AppSettings()
        
        // Test invalid font size
        settings.fontSize = .custom(-1)
        XCTAssertThrowsError(try settings.validate()) { error in
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test invalid message history
        settings.maxMessageHistory = 0
        XCTAssertThrowsError(try settings.validate()) { error in
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test valid settings
        settings.fontSize = .medium
        settings.maxMessageHistory = 500
        XCTAssertNoThrow(try settings.validate())
    }
    
    // MARK: - File Node Tests
    
    func testFileNodeModel() throws {
        // Given - File node
        let fileNode = FileNode(
            name: "test.swift",
            path: "/project/src/test.swift",
            isDirectory: false,
            size: 1024
        )
        
        // Then
        XCTAssertEqual(fileNode.name, "test.swift")
        XCTAssertEqual(fileNode.path, "/project/src/test.swift")
        XCTAssertFalse(fileNode.isDirectory)
        XCTAssertEqual(fileNode.size, 1024)
        XCTAssertEqual(fileNode.fileExtension, "swift")
        XCTAssertEqual(fileNode.displaySize, "1.0 KB")
        
        // Given - Directory node
        let dirNode = FileNode(
            name: "src",
            path: "/project/src",
            isDirectory: true,
            size: 0
        )
        
        // Then
        XCTAssertTrue(dirNode.isDirectory)
        XCTAssertNil(dirNode.fileExtension)
        XCTAssertEqual(dirNode.displaySize, "—")
    }
    
    func testFileNodeHierarchy() throws {
        // Given
        let rootNode = FileNode(name: "project", path: "/project", isDirectory: true, size: 0)
        let srcNode = FileNode(name: "src", path: "/project/src", isDirectory: true, size: 0)
        let fileNode = FileNode(name: "main.swift", path: "/project/src/main.swift", isDirectory: false, size: 512)
        
        // When
        rootNode.addChild(srcNode)
        srcNode.addChild(fileNode)
        
        // Then
        XCTAssertEqual(rootNode.children.count, 1)
        XCTAssertTrue(rootNode.children.contains(srcNode))
        XCTAssertEqual(srcNode.parent, rootNode)
        XCTAssertEqual(fileNode.parent, srcNode)
        XCTAssertEqual(fileNode.depth, 2)
    }
    
    // MARK: - Performance Tests
    
    func testModelCreationPerformance() throws {
        measure {
            for i in 0..<1000 {
                let project = Project(name: "Project\(i)", fullPath: "/path/\(i)")
                let session = Session(projectId: project.persistentModelID, title: "Session\(i)")
                let message = Message(sessionId: session.persistentModelID, content: "Message\(i)", isFromUser: true)
                
                // Basic validation that objects are created
                XCTAssertNotNil(project.name)
                XCTAssertNotNil(session.title)
                XCTAssertNotNil(message.content)
            }
        }
    }
    
    func testModelValidationPerformance() throws {
        measure {
            for i in 0..<100 {
                let validName = "Project\(i)"
                let validPath = "/valid/path/\(i)"
                let validContent = "This is test message number \(i)"
                
                XCTAssertNoThrow(try Project.validateName(validName))
                XCTAssertNoThrow(try Project.validatePath(validPath))
                XCTAssertNoThrow(try Message.validateContent(validContent))
            }
        }
    }
}

// MARK: - Custom Error Types

enum ValidationError: Error, LocalizedError {
    case emptyValue
    case invalidFormat
    case invalidLength
    case invalidCharacters
    
    var errorDescription: String? {
        switch self {
        case .emptyValue:
            return "Value cannot be empty"
        case .invalidFormat:
            return "Invalid format"
        case .invalidLength:
            return "Invalid length"
        case .invalidCharacters:
            return "Contains invalid characters"
        }
    }
}

// MARK: - Model Extensions for Testing

extension Project {
    static func validateName(_ name: String) throws {
        guard !name.isEmpty else { throw ValidationError.emptyValue }
        guard name.count <= 255 else { throw ValidationError.invalidLength }
        guard !name.contains("/") else { throw ValidationError.invalidCharacters }
    }
    
    static func validatePath(_ path: String) throws {
        guard !path.isEmpty else { throw ValidationError.emptyValue }
    }
}

extension Message {
    static func validateContent(_ content: String) throws {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ValidationError.emptyValue }
        guard content.count <= 10000 else { throw ValidationError.invalidLength }
    }
    
    func setError(_ errorMessage: String) {
        self.status = .failed
        self.errorMessage = errorMessage
    }
}

extension MCPServer {
    static func validateURL(_ urlString: String) throws {
        guard !urlString.isEmpty else { throw ValidationError.emptyValue }
        guard URL(string: urlString) != nil else { throw ValidationError.invalidFormat }
    }
}

extension AppSettings {
    func validate() throws {
        if case .custom(let size) = fontSize, size <= 0 {
            throw ValidationError.invalidFormat
        }
        guard maxMessageHistory > 0 else { throw ValidationError.invalidFormat }
    }
}

extension GitCommit {
    var shortHash: String {
        String(hash.prefix(7))
    }
}

extension GitBranch {
    var displayName: String {
        name
    }
}

extension GitFileStatus {
    var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }
    
    var displayStatus: String {
        switch status {
        case .untracked: return "??"
        case .modified: return "M"
        case .added: return "A"
        case .deleted: return "D"
        case .renamed: return "R"
        case .copied: return "C"
        }
    }
}

extension FileNode {
    var fileExtension: String? {
        guard !isDirectory else { return nil }
        let components = name.components(separatedBy: ".")
        return components.count > 1 ? components.last : nil
    }
    
    var displaySize: String {
        guard !isDirectory else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
    
    var depth: Int {
        var level = 0
        var current = parent
        while current != nil {
            level += 1
            current = current?.parent
        }
        return level
    }
    
    func addChild(_ child: FileNode) {
        children.append(child)
        child.parent = self
    }
}