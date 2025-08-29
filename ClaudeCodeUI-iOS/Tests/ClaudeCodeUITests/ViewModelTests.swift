//
//  ViewModelTests.swift
//  ClaudeCodeUITests
//
//  Comprehensive unit tests for ViewModels and business logic
//

import XCTest
import Combine
@testable import ClaudeCodeUI

final class ViewModelTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    var mockAPIClient: MockAPIClient!
    var mockWebSocketManager: MockWebSocketManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        cancellables = Set<AnyCancellable>()
        mockAPIClient = MockAPIClient()
        mockWebSocketManager = MockWebSocketManager()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        mockAPIClient = nil
        mockWebSocketManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - ProjectsViewModel Tests
    
    func testProjectsViewModelLoadProjects() throws {
        // Given
        let viewModel = ProjectsViewModel(apiClient: mockAPIClient)
        let expectedProjects = [
            Project(name: "Project1", fullPath: "/path/1"),
            Project(name: "Project2", fullPath: "/path/2")
        ]
        mockAPIClient.projectsToReturn = expectedProjects
        
        var receivedProjects: [Project] = []
        var loadingStates: [Bool] = []
        
        // When
        viewModel.$projects
            .sink { receivedProjects = $0 }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)
        
        viewModel.loadProjects()
        
        // Then
        XCTAssertEqual(receivedProjects.count, 2)
        XCTAssertEqual(receivedProjects[0].name, "Project1")
        XCTAssertEqual(receivedProjects[1].name, "Project2")
        
        // Verify loading states: false (initial) -> true (loading) -> false (completed)
        XCTAssertEqual(loadingStates, [false, true, false])
    }
    
    func testProjectsViewModelLoadProjectsError() throws {
        // Given
        let viewModel = ProjectsViewModel(apiClient: mockAPIClient)
        mockAPIClient.shouldReturnError = true
        mockAPIClient.errorToReturn = APIError.networkError(URLError(.notConnectedToInternet))
        
        var errorReceived: Error?
        var loadingStates: [Bool] = []
        
        // When
        viewModel.$error
            .sink { errorReceived = $0 }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)
        
        viewModel.loadProjects()
        
        // Then
        XCTAssertNotNil(errorReceived)
        XCTAssertTrue(errorReceived is APIError)
        XCTAssertEqual(loadingStates, [false, true, false])
    }
    
    func testProjectsViewModelCreateProject() throws {
        // Given
        let viewModel = ProjectsViewModel(apiClient: mockAPIClient)
        let newProject = Project(name: "NewProject", fullPath: "/new/path")
        mockAPIClient.projectToReturn = newProject
        
        var projectsReceived: [[Project]] = []
        
        // When
        viewModel.$projects
            .sink { projectsReceived.append($0) }
            .store(in: &cancellables)
        
        viewModel.createProject(name: "NewProject", path: "/new/path")
        
        // Then
        XCTAssertEqual(projectsReceived.last?.count, 1)
        XCTAssertEqual(projectsReceived.last?.first?.name, "NewProject")
    }
    
    func testProjectsViewModelDeleteProject() throws {
        // Given
        let viewModel = ProjectsViewModel(apiClient: mockAPIClient)
        let initialProjects = [
            Project(name: "Project1", fullPath: "/path/1"),
            Project(name: "Project2", fullPath: "/path/2")
        ]
        mockAPIClient.projectsToReturn = initialProjects
        viewModel.loadProjects()
        
        var finalProjects: [Project] = []
        
        // When
        viewModel.$projects
            .sink { finalProjects = $0 }
            .store(in: &cancellables)
        
        viewModel.deleteProject("Project1")
        
        // Then
        XCTAssertEqual(finalProjects.count, 1)
        XCTAssertEqual(finalProjects.first?.name, "Project2")
    }
    
    // MARK: - SessionListViewModel Tests
    
    func testSessionListViewModelLoadSessions() throws {
        // Given
        let viewModel = SessionListViewModel(
            projectName: "TestProject",
            apiClient: mockAPIClient
        )
        
        let expectedSessions = [
            Session(projectId: UUID(), title: "Session 1"),
            Session(projectId: UUID(), title: "Session 2")
        ]
        mockAPIClient.sessionsToReturn = expectedSessions
        
        var receivedSessions: [Session] = []
        
        // When
        viewModel.$sessions
            .sink { receivedSessions = $0 }
            .store(in: &cancellables)
        
        viewModel.loadSessions()
        
        // Then
        XCTAssertEqual(receivedSessions.count, 2)
        XCTAssertEqual(receivedSessions[0].title, "Session 1")
        XCTAssertEqual(receivedSessions[1].title, "Session 2")
    }
    
    func testSessionListViewModelCreateSession() throws {
        // Given
        let viewModel = SessionListViewModel(
            projectName: "TestProject",
            apiClient: mockAPIClient
        )
        
        let newSession = Session(projectId: UUID(), title: "New Session")
        mockAPIClient.sessionToReturn = newSession
        
        var sessionsReceived: [[Session]] = []
        
        // When
        viewModel.$sessions
            .sink { sessionsReceived.append($0) }
            .store(in: &cancellables)
        
        viewModel.createSession(title: "New Session")
        
        // Then
        XCTAssertEqual(sessionsReceived.last?.count, 1)
        XCTAssertEqual(sessionsReceived.last?.first?.title, "New Session")
    }
    
    func testSessionListViewModelDeleteSession() throws {
        // Given
        let viewModel = SessionListViewModel(
            projectName: "TestProject",
            apiClient: mockAPIClient
        )
        
        let initialSessions = [
            Session(projectId: UUID(), title: "Session 1"),
            Session(projectId: UUID(), title: "Session 2")
        ]
        mockAPIClient.sessionsToReturn = initialSessions
        viewModel.loadSessions()
        
        var finalSessions: [Session] = []
        
        // When
        viewModel.$sessions
            .sink { finalSessions = $0 }
            .store(in: &cancellables)
        
        if let sessionToDelete = initialSessions.first {
            viewModel.deleteSession(sessionToDelete)
        }
        
        // Then
        XCTAssertEqual(finalSessions.count, 1)
        XCTAssertEqual(finalSessions.first?.title, "Session 2")
    }
    
    // MARK: - ChatViewModel Tests
    
    func testChatViewModelLoadMessages() throws {
        // Given
        let viewModel = ChatViewModel(
            projectName: "TestProject",
            sessionId: "session123",
            apiClient: mockAPIClient,
            webSocketManager: mockWebSocketManager
        )
        
        let expectedMessages = [
            Message(sessionId: UUID(), content: "Hello", isFromUser: true),
            Message(sessionId: UUID(), content: "Hi there!", isFromUser: false)
        ]
        mockAPIClient.messagesToReturn = expectedMessages
        
        var receivedMessages: [Message] = []
        
        // When
        viewModel.$messages
            .sink { receivedMessages = $0 }
            .store(in: &cancellables)
        
        viewModel.loadMessages()
        
        // Then
        XCTAssertEqual(receivedMessages.count, 2)
        XCTAssertEqual(receivedMessages[0].content, "Hello")
        XCTAssertTrue(receivedMessages[0].isFromUser)
        XCTAssertEqual(receivedMessages[1].content, "Hi there!")
        XCTAssertFalse(receivedMessages[1].isFromUser)
    }
    
    func testChatViewModelSendMessage() throws {
        // Given
        let viewModel = ChatViewModel(
            projectName: "TestProject",
            sessionId: "session123",
            apiClient: mockAPIClient,
            webSocketManager: mockWebSocketManager
        )
        
        var messagesReceived: [[Message]] = []
        var connectionStateChanges: [WebSocketConnectionState] = []
        
        // When
        viewModel.$messages
            .sink { messagesReceived.append($0) }
            .store(in: &cancellables)
        
        viewModel.$connectionState
            .sink { connectionStateChanges.append($0) }
            .store(in: &cancellables)
        
        mockWebSocketManager.connectionState = .connected
        viewModel.sendMessage("Test message")
        
        // Then
        XCTAssertTrue(mockWebSocketManager.sentMessages.count > 0)
        XCTAssertEqual(messagesReceived.last?.last?.content, "Test message")
        XCTAssertTrue(messagesReceived.last?.last?.isFromUser == true)
    }
    
    func testChatViewModelWebSocketReconnection() throws {
        // Given
        let viewModel = ChatViewModel(
            projectName: "TestProject",
            sessionId: "session123",
            apiClient: mockAPIClient,
            webSocketManager: mockWebSocketManager
        )
        
        var connectionStates: [WebSocketConnectionState] = []
        
        // When
        viewModel.$connectionState
            .sink { connectionStates.append($0) }
            .store(in: &cancellables)
        
        // Simulate connection state changes
        mockWebSocketManager.connectionState = .connecting
        mockWebSocketManager.notifyDelegateOfStateChange()
        
        mockWebSocketManager.connectionState = .connected
        mockWebSocketManager.notifyDelegateOfStateChange()
        
        mockWebSocketManager.connectionState = .disconnected
        mockWebSocketManager.notifyDelegateOfStateChange()
        
        // Then
        XCTAssertTrue(connectionStates.contains(.connecting))
        XCTAssertTrue(connectionStates.contains(.connected))
        XCTAssertTrue(connectionStates.contains(.disconnected))
    }
    
    func testChatViewModelMessageStatusUpdates() throws {
        // Given
        let viewModel = ChatViewModel(
            projectName: "TestProject",
            sessionId: "session123",
            apiClient: mockAPIClient,
            webSocketManager: mockWebSocketManager
        )
        
        var messagesReceived: [[Message]] = []
        
        // When
        viewModel.$messages
            .sink { messagesReceived.append($0) }
            .store(in: &cancellables)
        
        mockWebSocketManager.connectionState = .connected
        viewModel.sendMessage("Test message")
        
        // Simulate status updates
        if let sentMessage = messagesReceived.last?.last {
            viewModel.updateMessageStatus(sentMessage, status: .sent)
            viewModel.updateMessageStatus(sentMessage, status: .delivered)
            viewModel.updateMessageStatus(sentMessage, status: .read)
        }
        
        // Then
        let finalMessage = messagesReceived.last?.last
        XCTAssertEqual(finalMessage?.status, .read)
    }
    
    // MARK: - SearchViewModel Tests
    
    func testSearchViewModelPerformSearch() throws {
        // Given
        let viewModel = SearchViewModel(apiClient: mockAPIClient)
        let expectedResults = [
            SearchResult(filename: "test.swift", content: "func test() {}", lineNumber: 1),
            SearchResult(filename: "main.swift", content: "print(\"hello\")", lineNumber: 5)
        ]
        mockAPIClient.searchResultsToReturn = expectedResults
        
        var receivedResults: [SearchResult] = []
        var loadingStates: [Bool] = []
        
        // When
        viewModel.$searchResults
            .sink { receivedResults = $0 }
            .store(in: &cancellables)
        
        viewModel.$isSearching
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)
        
        viewModel.performSearch(query: "test", scope: .currentProject)
        
        // Then
        XCTAssertEqual(receivedResults.count, 2)
        XCTAssertEqual(receivedResults[0].filename, "test.swift")
        XCTAssertEqual(receivedResults[1].filename, "main.swift")
        XCTAssertEqual(loadingStates, [false, true, false])
    }
    
    func testSearchViewModelClearResults() throws {
        // Given
        let viewModel = SearchViewModel(apiClient: mockAPIClient)
        mockAPIClient.searchResultsToReturn = [
            SearchResult(filename: "test.swift", content: "test", lineNumber: 1)
        ]
        viewModel.performSearch(query: "test", scope: .currentProject)
        
        var finalResults: [SearchResult] = []
        
        // When
        viewModel.$searchResults
            .sink { finalResults = $0 }
            .store(in: &cancellables)
        
        viewModel.clearResults()
        
        // Then
        XCTAssertTrue(finalResults.isEmpty)
    }
    
    // MARK: - TerminalViewModel Tests
    
    func testTerminalViewModelExecuteCommand() throws {
        // Given
        let viewModel = TerminalViewModel(webSocketManager: mockWebSocketManager)
        var outputReceived: [String] = []
        
        // When
        viewModel.$output
            .sink { outputReceived.append($0) }
            .store(in: &cancellables)
        
        mockWebSocketManager.connectionState = .connected
        viewModel.executeCommand("ls -la")
        
        // Simulate command output
        let mockOutput = "total 16\ndrwxr-xr-x 3 user staff 96 Jan 1 12:00 ."
        mockWebSocketManager.simulateReceivedMessage(mockOutput)
        
        // Then
        XCTAssertTrue(mockWebSocketManager.sentCommands.contains("ls -la"))
        XCTAssertTrue(outputReceived.last?.contains("total 16") == true)
    }
    
    func testTerminalViewModelCommandHistory() throws {
        // Given
        let viewModel = TerminalViewModel(webSocketManager: mockWebSocketManager)
        mockWebSocketManager.connectionState = .connected
        
        // When
        viewModel.executeCommand("ls")
        viewModel.executeCommand("pwd")
        viewModel.executeCommand("cd ..")
        
        let history = viewModel.commandHistory
        
        // Then
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history[0], "ls")
        XCTAssertEqual(history[1], "pwd")
        XCTAssertEqual(history[2], "cd ..")
    }
    
    func testTerminalViewModelClearOutput() throws {
        // Given
        let viewModel = TerminalViewModel(webSocketManager: mockWebSocketManager)
        mockWebSocketManager.connectionState = .connected
        
        viewModel.executeCommand("echo hello")
        mockWebSocketManager.simulateReceivedMessage("hello")
        
        var finalOutput: String = ""
        
        // When
        viewModel.$output
            .sink { finalOutput = $0 }
            .store(in: &cancellables)
        
        viewModel.clearOutput()
        
        // Then
        XCTAssertTrue(finalOutput.isEmpty)
    }
    
    // MARK: - SettingsViewModel Tests
    
    func testSettingsViewModelLoadSettings() throws {
        // Given
        let viewModel = SettingsViewModel()
        
        var settingsReceived: AppSettings?
        
        // When
        viewModel.$settings
            .sink { settingsReceived = $0 }
            .store(in: &cancellables)
        
        viewModel.loadSettings()
        
        // Then
        XCTAssertNotNil(settingsReceived)
        XCTAssertEqual(settingsReceived?.theme, .cyberpunk)
        XCTAssertEqual(settingsReceived?.fontSize, .medium)
    }
    
    func testSettingsViewModelUpdateTheme() throws {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.loadSettings()
        
        var updatedSettings: AppSettings?
        
        // When
        viewModel.$settings
            .sink { updatedSettings = $0 }
            .store(in: &cancellables)
        
        viewModel.updateTheme(.light)
        
        // Then
        XCTAssertEqual(updatedSettings?.theme, .light)
    }
    
    func testSettingsViewModelExportSettings() throws {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.loadSettings()
        
        // When
        let exportData = viewModel.exportSettings()
        
        // Then
        XCTAssertNotNil(exportData)
        XCTAssertTrue(exportData.count > 0)
        
        // Verify it's valid JSON
        let decoded = try JSONSerialization.jsonObject(with: exportData) as? [String: Any]
        XCTAssertNotNil(decoded)
        XCTAssertNotNil(decoded?["theme"])
        XCTAssertNotNil(decoded?["fontSize"])
    }
    
    func testSettingsViewModelImportSettings() throws {
        // Given
        let viewModel = SettingsViewModel()
        let settingsDict: [String: Any] = [
            "theme": "light",
            "fontSize": "large",
            "enableHapticFeedback": false
        ]
        let importData = try JSONSerialization.data(withJSONObject: settingsDict)
        
        var importedSettings: AppSettings?
        
        // When
        viewModel.$settings
            .sink { importedSettings = $0 }
            .store(in: &cancellables)
        
        try viewModel.importSettings(data: importData)
        
        // Then
        XCTAssertEqual(importedSettings?.theme, .light)
        XCTAssertEqual(importedSettings?.fontSize, .large)
        XCTAssertFalse(importedSettings?.enableHapticFeedback ?? true)
    }
    
    // MARK: - Performance Tests
    
    func testViewModelMemoryUsage() throws {
        measure {
            let viewModel = ProjectsViewModel(apiClient: mockAPIClient)
            mockAPIClient.projectsToReturn = Array(0..<1000).map { 
                Project(name: "Project\($0)", fullPath: "/path/\($0)")
            }
            
            viewModel.loadProjects()
            
            // Simulate heavy usage
            for _ in 0..<100 {
                viewModel.refreshProjects()
            }
        }
    }
    
    func testViewModelBindingPerformance() throws {
        let viewModel = ProjectsViewModel(apiClient: mockAPIClient)
        
        measure {
            var subscriptions: [AnyCancellable] = []
            
            // Create many bindings
            for _ in 0..<1000 {
                viewModel.$projects
                    .sink { _ in }
                    .store(in: &subscriptions)
            }
            
            // Update the published property
            mockAPIClient.projectsToReturn = [Project(name: "Test", fullPath: "/test")]
            viewModel.loadProjects()
            
            subscriptions.removeAll()
        }
    }
}

// MARK: - Mock API Client

class MockAPIClient: APIClientProtocol {
    var shouldReturnError = false
    var errorToReturn: Error = APIError.networkError(URLError(.notConnectedToInternet))
    
    var projectsToReturn: [Project] = []
    var projectToReturn: Project?
    var sessionsToReturn: [Session] = []
    var sessionToReturn: Session?
    var messagesToReturn: [Message] = []
    var searchResultsToReturn: [SearchResult] = []
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        if shouldReturnError {
            throw errorToReturn
        }
        
        switch endpoint {
        case .getProjects:
            return projectsToReturn as! T
        case .createProject:
            return projectToReturn as! T
        case .getSessions:
            return sessionsToReturn as! T
        case .createSession:
            return sessionToReturn as! T
        case .getSessionMessages:
            return messagesToReturn as! T
        case .search:
            return searchResultsToReturn as! T
        default:
            throw APIError.notFound("Not implemented")
        }
    }
    
    func request(_ endpoint: APIEndpoint) async throws -> Data {
        if shouldReturnError {
            throw errorToReturn
        }
        return Data()
    }
    
    func requestVoid(_ endpoint: APIEndpoint) async throws {
        if shouldReturnError {
            throw errorToReturn
        }
    }
}

// MARK: - Mock WebSocket Manager

class MockWebSocketManager: WebSocketProtocol {
    var delegate: WebSocketManagerDelegate?
    var connectionState: WebSocketConnectionState = .disconnected
    var sentMessages: [WebSocketMessage] = []
    var sentCommands: [String] = []
    
    func connect(to url: URL, withJWT token: String?) {
        connectionState = .connecting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.connectionState = .connected
            self.delegate?.webSocketConnectionStateChanged(.connected)
        }
    }
    
    func disconnect() {
        connectionState = .disconnected
        delegate?.webSocketConnectionStateChanged(.disconnected)
    }
    
    func send(message: WebSocketMessage) {
        sentMessages.append(message)
        
        if message.type == .shellCommand {
            sentCommands.append(message.content)
        }
    }
    
    func notifyDelegateOfStateChange() {
        delegate?.webSocketConnectionStateChanged(connectionState)
    }
    
    func simulateReceivedMessage(_ content: String) {
        let message = WebSocketMessage(type: .assistantResponse, content: content)
        delegate?.webSocketDidReceiveMessage(message)
    }
}

// MARK: - Test Models

struct SearchResult: Codable {
    let filename: String
    let content: String
    let lineNumber: Int
}

// MARK: - ViewModel Implementations (Placeholders)

class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func loadProjects() {
        isLoading = true
        
        Task {
            do {
                let projects: [Project] = try await apiClient.request(.getProjects)
                
                await MainActor.run {
                    self.projects = projects
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshProjects() {
        loadProjects()
    }
    
    func createProject(name: String, path: String) {
        Task {
            do {
                let project: Project = try await apiClient.request(.createProject(name: name, path: path))
                
                await MainActor.run {
                    self.projects.append(project)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    func deleteProject(_ name: String) {
        Task {
            do {
                try await apiClient.requestVoid(.deleteProject(name: name))
                
                await MainActor.run {
                    self.projects.removeAll { $0.name == name }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
}

class SessionListViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let projectName: String
    private let apiClient: APIClientProtocol
    
    init(projectName: String, apiClient: APIClientProtocol) {
        self.projectName = projectName
        self.apiClient = apiClient
    }
    
    func loadSessions() {
        isLoading = true
        
        Task {
            do {
                let sessions: [Session] = try await apiClient.request(.getSessions(projectName: projectName))
                
                await MainActor.run {
                    self.sessions = sessions
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    func createSession(title: String) {
        Task {
            do {
                let session: Session = try await apiClient.request(.createSession(projectName: projectName, title: title))
                
                await MainActor.run {
                    self.sessions.append(session)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    func deleteSession(_ session: Session) {
        sessions.removeAll { $0.persistentModelID == session.persistentModelID }
    }
}

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var connectionState: WebSocketConnectionState = .disconnected
    @Published var isLoading = false
    
    private let projectName: String
    private let sessionId: String
    private let apiClient: APIClientProtocol
    private let webSocketManager: WebSocketProtocol
    
    init(projectName: String, sessionId: String, apiClient: APIClientProtocol, webSocketManager: WebSocketProtocol) {
        self.projectName = projectName
        self.sessionId = sessionId
        self.apiClient = apiClient
        self.webSocketManager = webSocketManager
        
        webSocketManager.delegate = self
    }
    
    func loadMessages() {
        isLoading = true
        
        Task {
            do {
                let messages: [Message] = try await apiClient.request(.getSessionMessages(projectName: projectName, sessionId: sessionId))
                
                await MainActor.run {
                    self.messages = messages
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func sendMessage(_ content: String) {
        let message = Message(sessionId: UUID(), content: content, isFromUser: true)
        messages.append(message)
        
        let webSocketMessage = WebSocketMessage(type: .claudeCommand, content: content)
        webSocketManager.send(message: webSocketMessage)
    }
    
    func updateMessageStatus(_ message: Message, status: MessageStatus) {
        if let index = messages.firstIndex(where: { $0.persistentModelID == message.persistentModelID }) {
            messages[index].status = status
        }
    }
}

class SearchViewModel: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func performSearch(query: String, scope: SearchScope) {
        isSearching = true
        
        Task {
            do {
                let results: [SearchResult] = try await apiClient.request(.search(query: query, scope: scope))
                
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.isSearching = false
                }
            }
        }
    }
    
    func clearResults() {
        searchResults = []
    }
}

class TerminalViewModel: ObservableObject {
    @Published var output: String = ""
    @Published var commandHistory: [String] = []
    
    private let webSocketManager: WebSocketProtocol
    
    init(webSocketManager: WebSocketProtocol) {
        self.webSocketManager = webSocketManager
        webSocketManager.delegate = self
    }
    
    func executeCommand(_ command: String) {
        commandHistory.append(command)
        
        let message = WebSocketMessage(type: .shellCommand, content: command)
        webSocketManager.send(message: message)
    }
    
    func clearOutput() {
        output = ""
    }
}

class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings = AppSettings()
    
    func loadSettings() {
        // Load settings from UserDefaults or other persistence
        settings = AppSettings()
    }
    
    func updateTheme(_ theme: AppTheme) {
        settings.theme = theme
        saveSettings()
    }
    
    func exportSettings() -> Data {
        let encoder = JSONEncoder()
        return (try? encoder.encode(settings)) ?? Data()
    }
    
    func importSettings(data: Data) throws {
        let decoder = JSONDecoder()
        settings = try decoder.decode(AppSettings.self, from: data)
        saveSettings()
    }
    
    private func saveSettings() {
        // Save to UserDefaults or other persistence
    }
}

// MARK: - WebSocketManagerDelegate Implementations

extension ChatViewModel: WebSocketManagerDelegate {
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        connectionState = state
    }
    
    func webSocketDidReceiveMessage(_ message: WebSocketMessage) {
        let chatMessage = Message(sessionId: UUID(), content: message.content, isFromUser: false)
        messages.append(chatMessage)
    }
    
    func webSocketDidReceiveError(_ error: Error) {
        // Handle error
    }
    
    func webSocketMaxReconnectAttemptsReached() {
        // Handle max reconnect attempts
    }
}

extension TerminalViewModel: WebSocketManagerDelegate {
    func webSocketConnectionStateChanged(_ state: WebSocketConnectionState) {
        // Handle connection state changes
    }
    
    func webSocketDidReceiveMessage(_ message: WebSocketMessage) {
        output += message.content + "\n"
    }
    
    func webSocketDidReceiveError(_ error: Error) {
        output += "Error: \(error.localizedDescription)\n"
    }
    
    func webSocketMaxReconnectAttemptsReached() {
        output += "Connection failed: Max reconnect attempts reached\n"
    }
}

// MARK: - Enums for Testing

enum SearchScope {
    case currentProject
    case allProjects
    case currentFile
}

enum AppTheme: String, Codable {
    case cyberpunk = "cyberpunk"
    case light = "light"
    case dark = "dark"
}

enum FontSize: String, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case custom(CGFloat)
    
    var rawValue: String {
        switch self {
        case .small: return "small"
        case .medium: return "medium"
        case .large: return "large"
        case .custom(let size): return "custom:\(size)"
        }
    }
}

struct AppSettings: Codable {
    var theme: AppTheme = .cyberpunk
    var fontSize: FontSize = .medium
    var enableHapticFeedback = true
    var enableAnimations = true
    var offlineMode = false
    var maxMessageHistory = 1000
}

// MARK: - Additional API Endpoints

extension APIEndpoint {
    case getSessions(projectName: String)
    case createSession(projectName: String, title: String)
    case getSessionMessages(projectName: String, sessionId: String)
    case search(query: String, scope: SearchScope)
    case createProject(name: String, path: String)
    case deleteProject(name: String)
}