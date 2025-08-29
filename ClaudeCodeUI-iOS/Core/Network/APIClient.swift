//
//  APIClient.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation
import SwiftData

// MARK: - Temporary Type Definitions
// Session and SessionStatus are now imported from Models/Session.swift

// MARK: - Request Models
struct APIFeedbackData: Codable {
    let type: FeedbackType
    let message: String
    let email: String?
    let deviceInfo: String
    let appVersion: String
    let screenshot: Data?
}

enum FeedbackType: String, Codable {
    case bug = "bug"
    case feature = "feature"
    case general = "general"
}

// MARK: - API Client Protocol
protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func request(_ endpoint: APIEndpoint) async throws -> Data
    func requestVoid(_ endpoint: APIEndpoint) async throws
}

// MARK: - API Client
actor APIClient: APIClientProtocol {
    
    // MARK: - Singleton
    static let shared = APIClient()
    
    // MARK: - Properties
    private let baseURL: String
    private let session: URLSession
    private var authToken: String?
    private let offlineManager = OfflineManager.shared
    private let offlineStore = OfflineDataStore.shared
    
    // MARK: - Initialization
    init(baseURL: String = AppConfig.backendURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        
        // Initialize with token from secure storage if available
        // Token is now managed by AuthenticationManager and stored in Keychain
        Task {
            await loadAuthenticationToken()
        }
    }
    
    // MARK: - Private Methods
    private func loadAuthenticationToken() async {
        // Try to get token from KeychainManager (secure storage)
        // Load saved token from secure Keychain storage
        do {
            if let token = try KeychainManager.shared.getAuthToken() {
                self.authToken = token
                print("🔐 [APIClient] Loaded authentication token from secure storage")
            } else {
                print("🔓 [APIClient] No authentication token found in secure storage")
            }
        } catch {
            print("⚠️ [APIClient] Failed to load authentication token: \(error)")
            // Fallback: Try to migrate from UserDefaults if exists
            if let oldToken = UserDefaults.standard.string(forKey: "authToken") {
                self.authToken = oldToken
                // Migrate to Keychain
                try? KeychainManager.shared.saveAuthToken(oldToken)
                // Remove from insecure storage
                UserDefaults.standard.removeObject(forKey: "authToken")
                print("🔄 [APIClient] Migrated authentication token to secure storage")
            }
        }
    }
    
    // MARK: - Authentication
    func setAuthToken(_ token: String?) {
        self.authToken = token
        
        // Store token securely in Keychain instead of UserDefaults
        Task {
            do {
                if let token = token {
                    // Save to secure Keychain storage
                    try KeychainManager.shared.saveAuthToken(token)
                    print("🔐 [APIClient] Saved authentication token to secure storage")
                    
                    // Also notify other components about token change
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("authenticationChanged"),
                            object: nil,
                            userInfo: ["token": token]
                        )
                    }
                } else {
                    // Remove token from secure storage
                    try KeychainManager.shared.delete(key: .authToken)
                    print("🔓 [APIClient] Removed authentication token from secure storage")
                    
                    // Notify about logout
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("authenticationChanged"),
                            object: nil,
                            userInfo: ["token": NSNull()]
                        )
                    }
                }
            } catch {
                print("⚠️ [APIClient] Failed to update authentication token: \(error)")
            }
        }
    }
    
    func getAuthToken() async -> String? {
        return authToken
    }
    
    // MARK: - Authentication API Methods
    
    /// Login with username and password
    /// - Parameters:
    ///   - username: User's username
    ///   - password: User's password
    /// - Returns: Dictionary containing authentication response (token, user info, etc.)
    func login(username: String, password: String) async throws -> [String: Any] {
        let credentials = ["username": username, "password": password]
        let bodyData = try JSONSerialization.data(withJSONObject: credentials)
        
        var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/login")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        guard let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        return responseData
    }
    
    /// Logout the current user
    func logout() async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/logout")!)
        request.httpMethod = "POST"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: Data())
        }
    }
    
    /// Refresh the authentication token
    /// - Parameter refreshToken: The refresh token
    /// - Returns: Dictionary containing new token and expiry info
    func refreshToken(_ refreshToken: String) async throws -> [String: Any] {
        let body = ["refreshToken": refreshToken]
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/refresh")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        guard let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        return responseData
    }
    
    /// Check authentication status
    /// - Returns: Dictionary containing auth status and user info
    func checkAuthStatus() async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/status")!)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        guard let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        return responseData
    }
    
    // MARK: - Convenience Methods
    func fetchProjects() async throws -> [Project] {
        print("🔍 [APIClient] fetchProjects() called")
        print("🔍 [APIClient] Using baseURL: \(baseURL)")
        print("🔍 [APIClient] Full URL will be: \(baseURL)/api/projects")
        
        // Check if offline
        if await offlineManager.isOffline {
            print("📵 [APIClient] Offline - loading projects from cache")
            let offlineProjects = await offlineStore.fetchOfflineProjects()
            return offlineProjects.compactMap { offline in
                guard let id = offline.id,
                      let name = offline.name,
                      let path = offline.path else { return nil }
                return Project(
                    id: id,
                    name: name,
                    path: path,
                    displayName: name,
                    createdAt: offline.createdAt ?? Date(),
                    updatedAt: offline.lastModified ?? Date(),
                    actualSessionCount: 0
                )
            }
        }
        
        do {
            let dtos: [ProjectDTO] = try await request(.getProjects())
            print("✅ [APIClient] Successfully decoded \(dtos.count) ProjectDTOs")
            
            let projects = dtos.map { dto in
                // Calculate session count from sessions array or sessionMeta
                let sessionCount = dto.sessions?.count ?? dto.sessionMeta?.total ?? 0
                print("📊 [APIClient] Project '\(dto.name)' has \(sessionCount) sessions")
                
                return Project(
                    id: dto.name, // Use name as ID since backend doesn't provide ID
                    name: dto.name,
                    path: dto.path,
                    displayName: dto.displayName ?? dto.name,
                    createdAt: Date(), // Default to current date since backend doesn't provide
                    updatedAt: Date(),  // Default to current date since backend doesn't provide
                    actualSessionCount: sessionCount
                )
            }
            
            // Cache projects for offline use
            for project in projects {
                await offlineStore.saveProject(project, isOffline: false)
            }
            
            return projects
        } catch {
            // If network fails, try offline cache
            print("⚠️ [APIClient] Network request failed, falling back to offline cache")
            let offlineProjects = await offlineStore.fetchOfflineProjects()
            return offlineProjects.compactMap { offline in
                guard let id = offline.id,
                      let name = offline.name,
                      let path = offline.path else { return nil }
                return Project(
                    id: id,
                    name: name,
                    path: path,
                    displayName: name,
                    createdAt: offline.createdAt ?? Date(),
                    updatedAt: offline.lastModified ?? Date(),
                    actualSessionCount: 0
                )
            }
        }
    }
    
    func createProject(name: String, path: String) async throws -> Project {
        let dto: ProjectDTO = try await request(.createProject(name: name, path: path))
        return Project(
            id: dto.name, // Use name as ID since backend doesn't provide ID
            name: dto.name,
            path: dto.path,
            displayName: dto.displayName ?? dto.name,
            createdAt: Date(), // Default to current date since backend doesn't provide
            updatedAt: Date()  // Default to current date since backend doesn't provide
        )
    }
    
    func deleteProject(id: String) async throws {
        try await requestVoid(.deleteProject(id: id))
    }
    
    func renameProject(id: String, name: String) async throws -> Project {
        // Use PUT /api/projects/:projectName/rename endpoint
        let bodyData = try? JSONSerialization.data(withJSONObject: ["name": name], options: [])
        let endpoint = APIEndpoint(path: "/api/projects/\(id)/rename", method: .put, body: bodyData)
        return try await request(endpoint)
    }
    
    func submitFeedback(_ feedback: APIFeedbackData, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await requestVoid(.submitFeedback(feedback))
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func fetchSessions(projectName: String, limit: Int = 5, offset: Int = 0) async throws -> [Session] {
        // Log the request for debugging
        print("📋 Fetching sessions for project: \(projectName)")
        
        // Use the standard endpoint with authentication
        let response: SessionsResponse = try await request(.getSessions(projectName: projectName, limit: limit, offset: offset))
        return response.sessions.map { dto in
            // Use the projectName as projectId since backend doesn't include it in the response
            let session = Session(
                id: dto.id,
                projectId: projectName,
                summary: dto.summary,
                messageCount: dto.messageCount ?? 0,
                lastActivity: dto.lastActivity,
                cwd: dto.cwd,
                status: SessionStatus(rawValue: dto.status ?? "active") ?? .active
            )
            return session
        }
    }
    
    func fetchSessionMessages(projectName: String, sessionId: String, limit: Int = 50, offset: Int = 0) async throws -> [Message] {
        // Update endpoint to include limit and offset parameters
        let endpoint = APIEndpoint(
            path: "/api/projects/\(projectName)/sessions/\(sessionId)/messages?limit=\(limit)&offset=\(offset)",
            method: .get
        )
        
        // Backend returns complex nested structure with content array for assistant messages
        struct BackendMessage: Codable {
            let uuid: String
            let timestamp: String
            let sessionId: String?
            let type: String?
            let message: MessagePayload?
            
            struct MessagePayload: Codable {
                let role: String
                let content: AnyCodable?  // Can be string or array
                
                private enum CodingKeys: String, CodingKey {
                    case role
                    case content
                }
            }
            
            struct ContentItem: Codable {
                let type: String
                let text: String?
                let name: String?  // For tool_use
                let input: AnyCodable?  // For tool_use parameters
                let id: String?  // For tool_use
            }
        }
        
        struct MessagesResponse: Codable {
            let messages: [BackendMessage]
            let total: Int?
            let hasMore: Bool?
        }
        
        do {
            let response: MessagesResponse = try await request(endpoint)
            
            print("📥 Fetched \(response.messages.count) messages for session \(sessionId)")
            
            return response.messages.compactMap { backendMsg in
                // Safely extract content based on message structure
                var messageContent = ""
                var messageType = "text"
                
                if let messagePayload = backendMsg.message,
                   let content = messagePayload.content {
                    
                    // Handle string content (user messages)
                    if let stringContent = content.value as? String {
                        messageContent = stringContent
                    }
                    // Handle array content (assistant messages with multiple parts)
                    else if let arrayContent = content.value as? [[String: Any]] {
                        var contentParts: [String] = []
                        
                        for item in arrayContent {
                            if let type = item["type"] as? String {
                                switch type {
                                case "text":
                                    if let text = item["text"] as? String {
                                        contentParts.append(text)
                                    }
                                case "tool_use":
                                    messageType = "tool_use"
                                    if let name = item["name"] as? String {
                                        var toolText = "🔧 Using tool: \(name)"
                                        if let id = item["id"] as? String {
                                            toolText += " (\(id))"
                                        }
                                        if let input = item["input"] {
                                            toolText += "\n📝 Input: \(String(describing: input))"
                                        }
                                        contentParts.append(toolText)
                                    }
                                case "tool_result":
                                    messageType = "tool_result"
                                    if let content = item["content"] as? String {
                                        contentParts.append("✅ Result: \(content)")
                                    } else if let content = item["content"] as? [[String: Any]] {
                                        // Handle nested content in tool results
                                        for resultItem in content {
                                            if let text = resultItem["text"] as? String {
                                                contentParts.append("✅ Result: \(text)")
                                            }
                                        }
                                    }
                                case "thinking":
                                    messageType = "thinking"
                                    if let text = item["text"] as? String {
                                        contentParts.append("💭 \(text)")
                                    }
                                default:
                                    // Handle unknown content types
                                    contentParts.append("[\(type) content]")
                                }
                            }
                        }
                        
                        messageContent = contentParts.joined(separator: "\n\n")
                    }
                    // Handle direct object content
                    else if let dictContent = content.value as? [String: Any] {
                        if let text = dictContent["text"] as? String {
                            messageContent = text
                        } else if let type = dictContent["type"] as? String {
                            messageContent = "[\(type) content]" 
                        } else {
                            messageContent = String(describing: dictContent)
                        }
                    }
                }
                
                // Default to showing type if no content found
                if messageContent.isEmpty {
                    if let type = backendMsg.type {
                        messageContent = "[\(type) message]"
                    } else {
                        messageContent = "[Empty message]"
                    }
                }
                
                let message = Message(
                    id: backendMsg.uuid,
                    role: MessageRole(rawValue: backendMsg.message?.role ?? "user") ?? .user,
                    content: messageContent
                )
                
                // Store message type in metadata for UI differentiation
                message.metadata = MessageMetadata(
                    model: nil,
                    tokens: nil,
                    processingTime: nil,
                    error: nil,
                    streamCompleted: false,
                    projectPath: nil,
                    sessionId: sessionId,
                    commandType: nil,
                    aborted: false,
                    resumedFrom: nil
                )
                
                // Parse timestamp from ISO string
                if let date = ISO8601DateFormatter().date(from: backendMsg.timestamp) {
                    message.timestamp = date
                } else {
                    message.timestamp = Date()
                }
                
                return message
            }
        } catch {
            print("❌ Failed to fetch messages: \(error)")
            // Check if it's a 404 (session/project doesn't exist yet)
            if let urlError = error as? URLError, urlError.code == .fileDoesNotExist {
                // Return empty array for new sessions
                return []
            }
            throw error
        }
    }
    
    func createSession(projectName: String) async throws -> Session {
        // Create a new session for the project
        let response: SessionDTO = try await request(.createSession(projectName: projectName))
        let session = Session(
            id: response.id,
            projectId: projectName,
            summary: response.summary,
            messageCount: response.messageCount ?? 0,
            lastActivity: response.lastActivity,
            cwd: response.cwd,
            status: SessionStatus(rawValue: response.status ?? "active") ?? .active
        )
        
        // Backend fields are already mapped in the Session initializer
        
        // Store sessionId for the project
        UserDefaults.standard.set(response.id, forKey: "currentSessionId_\(projectName)")
        
        return session
    }
    
    func deleteSession(projectName: String, sessionId: String) async throws {
        try await requestVoid(.deleteSession(projectName: projectName, sessionId: sessionId))
        
        // Clear stored sessionId if it matches
        let storedSessionId = UserDefaults.standard.string(forKey: "currentSessionId_\(projectName)")
        if storedSessionId == sessionId {
            UserDefaults.standard.removeObject(forKey: "currentSessionId_\(projectName)")
        }
    }
    
    // MARK: - MCP Server Methods
    
    func getMCPServers() async throws -> [MCPServer] {
        // Backend likely returns array directly, not wrapped in object
        // Try direct array first, fall back to wrapped response if needed
        do {
            // First try: backend returns array directly
            let servers: [MCPServer] = try await request(.getMCPServers())
            return servers
        } catch {
            // Fallback: backend returns wrapped response
            struct MCPServersResponse: Codable {
                let servers: [MCPServer]
            }
            let response: MCPServersResponse = try await request(.getMCPServers())
            return response.servers
        }
    }
    
    func addMCPServer(_ server: MCPServer) async throws -> MCPServer {
        // Backend likely returns the server directly, not wrapped
        // Try direct server first, fall back to wrapped response if needed
        do {
            // First try: backend returns server directly
            let savedServer: MCPServer = try await request(.addMCPServer(server))
            return savedServer
        } catch {
            // Fallback: backend returns wrapped response
            struct MCPServerResponse: Codable {
                let server: MCPServer
            }
            let response: MCPServerResponse = try await request(.addMCPServer(server))
            return response.server
        }
    }
    
    func updateMCPServer(_ server: MCPServer) async throws -> MCPServer {
        // Backend likely returns the server directly, not wrapped
        // Try direct server first, fall back to wrapped response if needed
        do {
            // First try: backend returns server directly
            let updatedServer: MCPServer = try await request(.updateMCPServer(server))
            return updatedServer
        } catch {
            // Fallback: backend returns wrapped response
            struct MCPServerResponse: Codable {
                let server: MCPServer
            }
            let response: MCPServerResponse = try await request(.updateMCPServer(server))
            return response.server
        }
    }
    
    func deleteMCPServer(id: String) async throws {
        try await requestVoid(.deleteMCPServer(id: id))
    }
    
    func testMCPServer(id: String) async throws -> ConnectionTestResult {
        // Test endpoint likely needs special handling for connection testing
        struct TestResponse: Codable {
            let success: Bool
            let message: String
            let latency: Double?
        }
        
        do {
            let response: TestResponse = try await request(.testMCPServer(id: id))
            return ConnectionTestResult(
                success: response.success,
                message: response.message,
                latency: response.latency
            )
        } catch {
            // If test fails at network level, return failure result
            return ConnectionTestResult(
                success: false,
                message: "Connection test failed: \(error.localizedDescription)",
                latency: nil
            )
        }
    }
    
    func executeMCPCommand(command: String, args: [String]? = nil) async throws -> String {
        struct CommandResponse: Codable {
            let output: String
            let success: Bool
        }
        let response: CommandResponse = try await request(.executeMCPCommand(command: command, args: args))
        if !response.success {
            throw APIError.serverError("Command execution failed: \(response.output)")
        }
        return response.output
    }
    
    // MARK: - Git Methods
    
    func getGitStatus(projectPath: String) async throws -> GitStatusResponse {
        return try await request(.gitStatus(projectPath: projectPath))
    }
    
    func commitChanges(projectPath: String, message: String) async throws -> GitCommitResponse {
        return try await request(.gitCommit(projectPath: projectPath, message: message))
    }
    
    func getBranches(projectPath: String) async throws -> GitBranchesResponse {
        return try await request(.gitBranches(projectPath: projectPath))
    }
    
    func checkoutBranch(projectPath: String, branch: String) async throws -> GitActionResponse {
        return try await request(.gitCheckout(projectPath: projectPath, branch: branch))
    }
    
    func createBranch(projectPath: String, branch: String, from: String? = nil) async throws -> GitActionResponse {
        return try await request(.gitCreateBranch(projectPath: projectPath, branch: branch, from: from))
    }
    
    func pushChanges(projectPath: String) async throws -> GitActionResponse {
        return try await request(.gitPush(projectPath: projectPath))
    }
    
    func pullChanges(projectPath: String) async throws -> GitActionResponse {
        return try await request(.gitPull(projectPath: projectPath))
    }
    
    func fetchChanges(projectPath: String) async throws -> GitActionResponse {
        return try await request(.gitFetch(projectPath: projectPath))
    }
    
    func getDiff(projectPath: String, cached: Bool = false) async throws -> GitDiffResponse {
        return try await request(.gitDiff(projectPath: projectPath, cached: cached))
    }
    
    func getLog(projectPath: String, limit: Int = 10) async throws -> GitLogResponse {
        return try await request(.gitLog(projectPath: projectPath, limit: limit))
    }
    
    func addFiles(projectPath: String, files: [String]) async throws -> GitActionResponse {
        return try await request(.gitAdd(projectPath: projectPath, files: files))
    }
    
    func resetFiles(projectPath: String, files: [String]? = nil) async throws -> GitActionResponse {
        return try await request(.gitReset(projectPath: projectPath, files: files))
    }
    
    func stash(projectPath: String, action: String = "push", message: String? = nil) async throws -> GitActionResponse {
        return try await request(.gitStash(projectPath: projectPath, action: action, message: message))
    }
    
    func generateCommitMessage(projectPath: String) async throws -> GitCommitMessageResponse {
        return try await request(.gitGenerateCommitMessage(projectPath: projectPath))
    }
    
    // MARK: - Additional Git Methods (missing endpoints)
    
    func getCommits(projectPath: String, limit: Int = 20) async throws -> GitLogResponse {
        // Use the existing GitLogResponse type which contains commits
        return try await request(.gitCommits(projectPath: projectPath, limit: limit))
    }
    
    func getCommitDiff(projectPath: String, commitHash: String) async throws -> GitDiffResponse {
        // Use the existing GitDiffResponse type
        return try await request(.gitCommitDiff(projectPath: projectPath, commitHash: commitHash))
    }
    
    func getRemoteStatus(projectPath: String) async throws -> GitRemoteStatusResponse {
        // This needs the extended model from GitModels.swift
        return try await request(.gitRemoteStatus(projectPath: projectPath))
    }
    
    func publishBranch(projectPath: String, branch: String) async throws -> GitActionResponse {
        return try await request(.gitPublish(projectPath: projectPath, branch: branch))
    }
    
    func discardChanges(projectPath: String, files: [String]) async throws -> GitActionResponse {
        return try await request(.gitDiscard(projectPath: projectPath, files: files))
    }
    
    func deleteUntrackedFiles(projectPath: String) async throws -> GitActionResponse {
        return try await request(.gitDeleteUntracked(projectPath: projectPath))
    }
    
    // MARK: - File Management Methods
    
    func updateProject(_ project: Project) async throws {
        // Update project on backend
        let body = try? JSONEncoder().encode(["name": project.displayName ?? project.name])
        let endpoint = APIEndpoint(
            path: "/api/projects/\(project.name)/rename",
            method: .put,
            body: body
        )
        try await requestVoid(endpoint)
    }
    
    func fetchFileTree(projectId: String) async throws -> FileNode {
        // Fetch file tree for project
        let endpoint = APIEndpoint(
            path: "/api/projects/\(projectId)/files",
            method: .get
        )
        return try await request(endpoint)
    }
    
    func createFile(path: String, content: String?) async throws {
        // Create a new file in the project
        let components = path.components(separatedBy: "/")
        guard let projectId = components.first else {
            throw NetworkError.invalidRequest
        }
        let filePath = components.dropFirst().joined(separator: "/")
        
        let body = try? JSONEncoder().encode(["path": filePath, "content": content ?? ""])
        let endpoint = APIEndpoint(
            path: "/api/projects/\(projectId)/files",
            method: .post,
            body: body
        )
        try await requestVoid(endpoint)
    }
    
    func deleteFile(path: String) async throws {
        // Delete a file from the project
        let components = path.components(separatedBy: "/")
        guard let projectId = components.first else {
            throw NetworkError.invalidRequest
        }
        let filePath = components.dropFirst().joined(separator: "/")
        
        let endpoint = APIEndpoint(
            path: "/api/projects/\(projectId)/files?path=\(filePath)",
            method: .delete
        )
        try await requestVoid(endpoint)
    }
    
    func renameFile(from: String, to: String) async throws {
        // Rename a file in the project
        let components = from.components(separatedBy: "/")
        guard let projectId = components.first else {
            throw NetworkError.invalidRequest
        }
        let fromPath = components.dropFirst().joined(separator: "/")
        let toPath = to.components(separatedBy: "/").dropFirst().joined(separator: "/")
        
        let body = try? JSONEncoder().encode(["from": fromPath, "to": toPath])
        let endpoint = APIEndpoint(
            path: "/api/projects/\(projectId)/files/rename",
            method: .put,
            body: body
        )
        try await requestVoid(endpoint)
    }
    
    // MARK: - File Operations (Fixed API Endpoints)
    
    func readFile(projectName: String, filePath: String) async throws -> String {
        // Read file content from the backend
        // Backend expects: GET /api/projects/:projectName/file?path=:filePath
        let encodedPath = filePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? filePath
        let endpoint = APIEndpoint(
            path: "/api/projects/\(projectName)/file?path=\(encodedPath)",
            method: .get
        )
        
        struct FileResponse: Codable {
            let content: String
            let path: String?
        }
        
        let response: FileResponse = try await request(endpoint)
        return response.content
    }
    
    func saveFile(projectName: String, filePath: String, content: String) async throws {
        // Save file content to the backend
        // Backend expects: PUT /api/projects/:projectName/file
        struct SaveFileRequest: Codable {
            let path: String
            let content: String
        }
        
        let requestBody = SaveFileRequest(path: filePath, content: content)
        let body = try? JSONEncoder().encode(requestBody)
        
        let endpoint = APIEndpoint(
            path: "/api/projects/\(projectName)/file",
            method: .put,
            body: body
        )
        
        try await requestVoid(endpoint)
    }
    
    func getFileTree(projectName: String) async throws -> FileNode {
        // Get the file tree for a project
        // Backend expects: GET /api/projects/:projectName/files
        let endpoint = APIEndpoint(
            path: "/api/projects/\(projectName)/files",
            method: .get
        )
        
        return try await request(endpoint)
    }
    
    // MARK: - Terminal Methods
    
    func executeTerminalCommand(_ command: String, projectId: String) async throws -> TerminalOutput {
        // Execute terminal command in project context
        let body = try? JSONEncoder().encode(["command": command])
        let endpoint = APIEndpoint(
            path: "/api/projects/\(projectId)/terminal",
            method: .post,
            body: body
        )
        return try await request(endpoint)
    }
    
    
    // MARK: - Completion Handler Methods for Legacy Support
    
    func getSessionMessages(sessionId: String, completion: @escaping (Result<[MessageDTO], Error>) -> Void) {
        Task {
            do {
                // Extract project ID from session ID or use a default
                // For now, we'll use the session endpoint directly
                let messages: [MessageDTO] = try await request(.getSessionMessages(sessionId: sessionId))
                completion(.success(messages))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Request Methods
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        print("🌐 [APIClient] Making request to: \(baseURL)\(endpoint.path)")
        print("🌐 [APIClient] Method: \(endpoint.method)")
        print("🌐 [APIClient] Auth token present: \(authToken != nil)")
        
        let data = try await requestWithRetry(endpoint)
        
        print("📦 [APIClient] Received data: \(data.count) bytes")
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 format with fractional seconds first (e.g., "2025-08-13T04:23:58.130Z")
            let isoFormatterWithMillis = ISO8601DateFormatter()
            isoFormatterWithMillis.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds
            ]
            if let date = isoFormatterWithMillis.date(from: dateString) {
                return date
            }
            
            // Try basic ISO8601 format without fractional seconds
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Try custom format from backend: "YYYY-MM-DD HH:mm:ss"
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Request with Retry Logic
    private func requestWithRetry(_ endpoint: APIEndpoint, maxRetries: Int = 3) async throws -> Data {
        var lastError: Error?
        var retryDelay: UInt64 = 1_000_000_000 // 1 second in nanoseconds
        
        for attempt in 0..<maxRetries {
            do {
                return try await request(endpoint)
            } catch let error as APIError {
                // Don't retry on client errors (4xx)
                if case .httpError(let statusCode, _) = error, (400..<500).contains(statusCode) {
                    throw error
                }
                lastError = error
            } catch {
                lastError = error
            }
            
            // Don't delay after the last attempt
            if attempt < maxRetries - 1 {
                print("⚠️ Request failed (attempt \(attempt + 1)/\(maxRetries)). Retrying in \(Double(retryDelay) / 1_000_000_000) seconds...")
                try await Task.sleep(nanoseconds: retryDelay)
                retryDelay = min(retryDelay * 2, 10_000_000_000) // Exponential backoff, max 10 seconds
            }
        }
        
        throw lastError ?? APIError.networkError(NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request failed after \(maxRetries) attempts"]))
    }
    
    func request(_ endpoint: APIEndpoint) async throws -> Data {
        let urlRequest = try createRequest(for: endpoint)
        
        let requestStart = Date()
        print("🌐 [REQUEST START] Making request to: \(urlRequest.url?.absoluteString ?? "nil")")
        print("   Method: \(urlRequest.httpMethod ?? "GET")")
        print("   Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
        print("   Timeout: \(urlRequest.timeoutInterval) seconds")
        
        print("⏳ [WAITING] Starting network call...")
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            let responseTime = Date().timeIntervalSince(requestStart)
            print("✅ [RESPONSE RECEIVED] Response received after \(String(format: "%.2f", responseTime)) seconds")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [ERROR] Invalid response type (not HTTPURLResponse)")
                throw APIError.invalidResponse
            }
            
            print("📦 [RESPONSE STATUS] HTTP \(httpResponse.statusCode)")
            print("   Headers: \(httpResponse.allHeaderFields)")
        
        // Log response data but truncate if too long
        if let responseString = String(data: data, encoding: .utf8) {
            let maxLength = 500
            if responseString.count > maxLength {
                print("📦 Response data (truncated): \(responseString.prefix(maxLength))...")
            } else {
                print("📦 Response data: \(responseString)")
            }
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
            return data
        } catch let error {
            let responseTime = Date().timeIntervalSince(requestStart)
            print("❌ [ERROR] Request failed after \(String(format: "%.2f", responseTime)) seconds")
            print("   Error: \(error.localizedDescription)")
            print("   Full error: \(error)")
            throw error
        }
    }
    
    func requestVoid(_ endpoint: APIEndpoint) async throws {
        _ = try await request(endpoint) as Data
    }
    
    // MARK: - Private Methods
    private func createRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeout
        
        // Add headers
        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add auth token if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if present
        if let body = endpoint.body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
    
    // MARK: - Settings Sync API
    
    /// Fetch user settings from backend
    /// - Returns: Dictionary containing user settings
    func fetchSettings() async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/settings")!)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        guard let settings = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        return settings
    }
    
    /// Sync local settings to backend
    /// - Parameter settings: Dictionary containing settings to sync
    func syncSettings(_ settings: [String: Any]) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/settings")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: settings, options: [])
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: Data())
        }
    }
    
    // MARK: - Search API
    
    /// Search project files for a query
    /// - Parameters:
    ///   - projectName: Name of the project to search in
    ///   - query: Search query string
    ///   - fileTypes: Optional array of file extensions to filter by
    ///   - caseSensitive: Whether search is case-sensitive
    ///   - useRegex: Whether to use regex for search
    /// - Returns: Search results with file information and matched content
    func searchProject(
        projectName: String,
        query: String,
        fileTypes: [String] = [],
        caseSensitive: Bool = false,
        useRegex: Bool = false
    ) async throws -> SearchResponse {
        let requestBody = SearchRequest(
            query: query,
            scope: "project",
            fileTypes: fileTypes,
            includeArchived: false,
            caseSensitive: caseSensitive,
            useRegex: useRegex,
            contextLines: 2,
            maxResults: 100
        )
        
        let body = try JSONEncoder().encode(requestBody)
        let endpoint = APIEndpoint(
            path: "/api/projects/\(projectName)/search",
            method: .post,
            body: body
        )
        
        return try await request(endpoint)
    }
    
    // MARK: - Transcription API
    
    /// Transcribe audio to text using backend service
    /// - Parameters:
    ///   - audioData: The audio data to transcribe
    ///   - format: The audio format (e.g., "m4a", "wav", "mp3")
    /// - Returns: Transcription response with text and confidence
    func transcribeAudio(audioData: Data, format: String = "m4a") async throws -> TranscriptionResponse {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/transcribe")!)
        request.httpMethod = "POST"
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add audio file part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.\(format)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/\(format)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add format parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"format\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(format)\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Add authentication
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Send request
        let (data, response) = try await session.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        // Decode response
        let transcription = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return transcription
    }
}

// MARK: - API Endpoint
struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?
    let timeout: TimeInterval
    
    init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 30
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - API Endpoints Extension
extension APIEndpoint {
    // Auth endpoints
    static func login(username: String, password: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["username": username, "password": password])
        return APIEndpoint(path: "/api/auth/login", method: .post, body: body)
    }
    
    static func logout() -> APIEndpoint {
        return APIEndpoint(path: "/api/auth/logout", method: .post)
    }
    
    static func checkAuth() -> APIEndpoint {
        return APIEndpoint(path: "/api/auth/status", method: .get)
    }
    
    static func register(username: String, password: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["username": username, "password": password])
        return APIEndpoint(path: "/api/auth/register", method: .post, body: body)
    }
    
    // Project endpoints
    static func getProjects() -> APIEndpoint {
        // Increase timeout to 120 seconds since this endpoint can be slow with many projects
        return APIEndpoint(path: "/api/projects", method: .get, timeout: 120)
    }
    
    static func createProject(name: String, path: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["name": name, "path": path])
        return APIEndpoint(path: "/api/projects", method: .post, body: body)
    }
    
    static func deleteProject(id: String) -> APIEndpoint {
        return APIEndpoint(path: "/api/projects/\(id)", method: .delete)
    }
    
    // Session endpoints
    static func getSessions(projectName: String, limit: Int = 5, offset: Int = 0) -> APIEndpoint {
        // Also increase timeout for sessions since they might be slow with many sessions
        return APIEndpoint(path: "/api/projects/\(projectName)/sessions?limit=\(limit)&offset=\(offset)", method: .get, timeout: 120)
    }
    
    static func createSession(projectName: String) -> APIEndpoint {
        // Create session with empty body - backend creates the session ID
        let emptyBody = try? JSONEncoder().encode([String: String]())
        return APIEndpoint(path: "/api/projects/\(projectName)/sessions", method: .post, body: emptyBody)
    }
    
    static func deleteSession(projectName: String, sessionId: String) -> APIEndpoint {
        return APIEndpoint(path: "/api/projects/\(projectName)/sessions/\(sessionId)", method: .delete)
    }
    
    static func getMessages(projectName: String, sessionId: String) -> APIEndpoint {
        // Increase timeout for messages which can be large
        return APIEndpoint(path: "/api/projects/\(projectName)/sessions/\(sessionId)/messages", method: .get, timeout: 120)
    }
    
    // Session endpoints (direct)
    static func getSessionMessages(sessionId: String) -> APIEndpoint {
        // Increase timeout for messages which can be large
        return APIEndpoint(path: "/api/sessions/\(sessionId)/messages", method: .get, timeout: 120)
    }
    
    // File endpoints
    static func getFiles(projectId: String, path: String) -> APIEndpoint {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        return APIEndpoint(path: "/api/projects/\(projectId)/files?path=\(encodedPath)", method: .get)
    }
    
    static func readFile(projectId: String, path: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["path": path])
        return APIEndpoint(path: "/api/projects/\(projectId)/files/read", method: .post, body: body)
    }
    
    static func writeFile(projectId: String, path: String, content: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["path": path, "content": content])
        return APIEndpoint(path: "/api/projects/\(projectId)/files/write", method: .post, body: body)
    }
    
    static func deleteFile(projectId: String, path: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["path": path])
        return APIEndpoint(path: "/api/projects/\(projectId)/files/delete", method: .post, body: body)
    }
    
    // Feedback endpoints
    static func submitFeedback(_ feedback: APIFeedbackData) -> APIEndpoint {
        let body = try? JSONEncoder().encode([
            "type": feedback.type.rawValue,
            "message": feedback.message,
            "email": feedback.email ?? "",
            "deviceInfo": feedback.deviceInfo,
            "appVersion": feedback.appVersion,
            "hasScreenshot": String(feedback.screenshot != nil)
        ])
        return APIEndpoint(path: "/api/feedback", method: .post, body: body)
    }
    
    // MARK: - Git Endpoints
    static func gitStatus(projectPath: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath])
        return APIEndpoint(path: "/api/git/status", method: .post, body: body)
    }
    
    static func gitCommit(projectPath: String, message: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath, "message": message])
        return APIEndpoint(path: "/api/git/commit", method: .post, body: body)
    }
    
    static func gitBranches(projectPath: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath])
        return APIEndpoint(path: "/api/git/branches", method: .post, body: body)
    }
    
    static func gitCheckout(projectPath: String, branch: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath, "branch": branch])
        return APIEndpoint(path: "/api/git/checkout", method: .post, body: body)
    }
    
    static func gitCreateBranch(projectPath: String, branch: String, from: String? = nil) -> APIEndpoint {
        var params = ["projectPath": projectPath, "branch": branch]
        if let from = from {
            params["from"] = from
        }
        let body = try? JSONEncoder().encode(params)
        return APIEndpoint(path: "/api/git/create-branch", method: .post, body: body)
    }
    
    static func gitPush(projectPath: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath])
        return APIEndpoint(path: "/api/git/push", method: .post, body: body)
    }
    
    static func gitPull(projectPath: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath])
        return APIEndpoint(path: "/api/git/pull", method: .post, body: body)
    }
    
    static func gitFetch(projectPath: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath])
        return APIEndpoint(path: "/api/git/fetch", method: .post, body: body)
    }
    
    static func gitDiff(projectPath: String, cached: Bool = false) -> APIEndpoint {
        let params: [String: Any] = ["projectPath": projectPath, "cached": cached]
        let body = try? JSONSerialization.data(withJSONObject: params)
        return APIEndpoint(path: "/api/git/diff", method: .post, body: body)
    }
    
    static func gitLog(projectPath: String, limit: Int = 10) -> APIEndpoint {
        let params: [String: Any] = ["projectPath": projectPath, "limit": limit]
        let body = try? JSONSerialization.data(withJSONObject: params)
        return APIEndpoint(path: "/api/git/log", method: .post, body: body)
    }
    
    static func gitAdd(projectPath: String, files: [String]) -> APIEndpoint {
        let params: [String: Any] = ["projectPath": projectPath, "files": files]
        let body = try? JSONSerialization.data(withJSONObject: params)
        return APIEndpoint(path: "/api/git/add", method: .post, body: body)
    }
    
    static func gitReset(projectPath: String, files: [String]? = nil) -> APIEndpoint {
        var params = ["projectPath": projectPath]
        if let files = files {
            params["files"] = files.joined(separator: ",")
        }
        let body = try? JSONEncoder().encode(params)
        return APIEndpoint(path: "/api/git/reset", method: .post, body: body)
    }
    
    static func gitStash(projectPath: String, action: String = "push", message: String? = nil) -> APIEndpoint {
        var params = ["projectPath": projectPath, "action": action]
        if let message = message {
            params["message"] = message
        }
        let body = try? JSONEncoder().encode(params)
        return APIEndpoint(path: "/api/git/stash", method: .post, body: body)
    }
    
    static func gitGenerateCommitMessage(projectPath: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath])
        return APIEndpoint(path: "/api/git/generate-commit-message", method: .post, body: body)
    }
    
    // Missing Git endpoints
    static func gitCommits(projectPath: String, limit: Int = 20) -> APIEndpoint {
        let params: [String: Any] = ["projectPath": projectPath, "limit": limit]
        let body = try? JSONSerialization.data(withJSONObject: params)
        return APIEndpoint(path: "/api/git/commits", method: .post, body: body)
    }
    
    static func gitCommitDiff(projectPath: String, commitHash: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath, "commitHash": commitHash])
        return APIEndpoint(path: "/api/git/commit-diff", method: .post, body: body)
    }
    
    static func gitRemoteStatus(projectPath: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath])
        return APIEndpoint(path: "/api/git/remote-status", method: .post, body: body)
    }
    
    static func gitPublish(projectPath: String, branch: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath, "branch": branch])
        return APIEndpoint(path: "/api/git/publish", method: .post, body: body)
    }
    
    static func gitDiscard(projectPath: String, files: [String]) -> APIEndpoint {
        let params: [String: Any] = ["projectPath": projectPath, "files": files]
        let body = try? JSONSerialization.data(withJSONObject: params)
        return APIEndpoint(path: "/api/git/discard", method: .post, body: body)
    }
    
    static func gitDeleteUntracked(projectPath: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["projectPath": projectPath])
        return APIEndpoint(path: "/api/git/delete-untracked", method: .post, body: body)
    }
    
    // MARK: - MCP Server Endpoints
    static func getMCPServers() -> APIEndpoint {
        return APIEndpoint(path: "/api/mcp/servers", method: .get)
    }
    
    static func addMCPServer(_ server: MCPServer) -> APIEndpoint {
        let body = try? JSONEncoder().encode(server)
        return APIEndpoint(path: "/api/mcp/servers", method: .post, body: body)
    }
    
    static func updateMCPServer(_ server: MCPServer) -> APIEndpoint {
        let body = try? JSONEncoder().encode(server)
        return APIEndpoint(path: "/api/mcp/servers/\(server.id)", method: .put, body: body)
    }
    
    static func deleteMCPServer(id: String) -> APIEndpoint {
        return APIEndpoint(path: "/api/mcp/servers/\(id)", method: .delete)
    }
    
    static func testMCPServer(id: String) -> APIEndpoint {
        return APIEndpoint(path: "/api/mcp/servers/\(id)/test", method: .post)
    }
    
    static func executeMCPCommand(command: String, args: [String]? = nil) -> APIEndpoint {
        var params = ["command": command]
        if let args = args {
            params["args"] = args.joined(separator: " ")
        }
        let body = try? JSONEncoder().encode(params)
        return APIEndpoint(path: "/api/mcp/cli", method: .post, body: body)
    }
    
}

// MARK: - Response Models
struct AuthResponse: Codable {
    let success: Bool
    let token: String?
    let user: User?
}

struct User: Codable {
    let id: Int
    let username: String
}

// MARK: - Git Response Models
struct GitStatusResponse: Codable {
    let success: Bool
    let status: GitStatus?
    let error: String?
}

struct GitStatus: Codable {
    let branch: String
    let ahead: Int
    let behind: Int
    let staged: [String]
    let modified: [String]
    let untracked: [String]
}

struct GitCommitResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

struct GitBranchesResponse: Codable {
    let success: Bool
    let branches: [APIGitBranch]?
    let error: String?
}

struct APIGitBranch: Codable {
    let name: String
    let current: Bool
}

struct GitActionResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

struct GitDiffResponse: Codable {
    let success: Bool
    let diff: String?
    let error: String?
}

struct GitLogResponse: Codable {
    let success: Bool
    let commits: [APIGitCommit]?
    let error: String?
}

struct APIGitCommit: Codable {
    let hash: String
    let author: String
    let date: String
    let message: String
}

struct GitCommitMessageResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

// MARK: - Git Remote Status Response
struct GitRemoteStatusResponse: Codable {
    let success: Bool
    let hasRemote: Bool
    let remoteUrl: String?
    let ahead: Int
    let behind: Int
    let diverged: Bool
    let error: String?
}

struct ProjectsResponse: Codable {
    let projects: [ProjectDTO]
}

struct ProjectDTO: Codable {
    let name: String
    let path: String
    let displayName: String?
    let fullPath: String?
    let isCustomName: Bool?
    let sessions: [SessionDTO]?
    let sessionMeta: SessionMeta?
}

struct SessionMeta: Codable {
    let hasMore: Bool?
    let total: Int?
}

struct SessionsResponse: Codable {
    let sessions: [SessionDTO]
    let total: Int
}

// SessionDTO is now defined in Models/Session.swift

struct MessageDTO: Codable {
    let id: String?
    let role: String
    let content: String
    let timestamp: Date?
}

// File tree response structure moved to FileExplorerViewController.swift

struct FilesResponse: Codable {
    let files: [FileDTO]
    let directories: [DirectoryDTO]
}

struct FileDTO: Codable {
    let name: String
    let path: String
    let size: Int64
    let modifiedAt: Date
    let isDirectory: Bool
}

struct DirectoryDTO: Codable {
    let name: String
    let path: String
    let itemCount: Int
}

// MARK: - Missing API Endpoints TODOs

// TODO[CM-API-02]: Implement settings GET endpoint
// ENDPOINT: GET /api/settings
// RESPONSE: {theme: String, fontSize: Int, ...}
// PRIORITY: P2
// func getSettings() async throws -> SettingsResponse {
//     // Implementation needed
// }

// TODO[CM-API-03]: Implement settings POST endpoint
// ENDPOINT: POST /api/settings
// REQUEST: {theme: String, fontSize: Int, ...}
// PRIORITY: P2
// func updateSettings(_ settings: SettingsRequest) async throws {
//     // Implementation needed
// }

// MARK: - Search Models
struct SearchRequest: Codable {
    let query: String
    let scope: String
    let fileTypes: [String]
    let includeArchived: Bool
    let caseSensitive: Bool
    let useRegex: Bool
    let contextLines: Int
    let maxResults: Int
}

struct SearchResponse: Codable {
    let results: [SearchResult]
    let totalCount: Int
    let searchTime: Double
    let truncated: Bool
    let query: String
    let scope: String
    let fileTypes: [String]
}

struct SearchResult: Codable {
    let fileName: String
    let filePath: String
    let absolutePath: String
    let lineNumber: Int
    let lineContent: String
    let context: String
    let projectName: String
}

// MARK: - Cursor Integration Models
// Models are defined in Core/Data/Models/CursorModels.swift