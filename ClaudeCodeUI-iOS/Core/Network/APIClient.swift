//
//  APIClient.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation

// MARK: - Request Models
struct FeedbackData: Codable {
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
    
    // MARK: - Initialization
    init(baseURL: String = AppConfig.backendURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        
        // Load saved auth token
        if let savedToken = UserDefaults.standard.string(forKey: "authToken") {
            self.authToken = savedToken
        }
    }
    
    // MARK: - Authentication
    func setAuthToken(_ token: String?) {
        self.authToken = token
        if let token = token {
            UserDefaults.standard.set(token, forKey: "authToken")
        } else {
            UserDefaults.standard.removeObject(forKey: "authToken")
        }
    }
    
    // MARK: - Convenience Methods
    func fetchProjects() async throws -> [Project] {
        let dtos: [ProjectDTO] = try await request(.getProjects())
        return dtos.map { dto in
            Project(
                id: dto.name, // Use name as ID since backend doesn't provide ID
                name: dto.name,
                path: dto.path,
                displayName: dto.displayName ?? dto.name,
                createdAt: Date(), // Default to current date since backend doesn't provide
                updatedAt: Date()  // Default to current date since backend doesn't provide
            )
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
    
    func submitFeedback(_ feedback: FeedbackData, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await requestVoid(.submitFeedback(feedback))
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func fetchSessions(projectId: String, limit: Int = 5, offset: Int = 0) async throws -> [Session] {
        let response: SessionsResponse = try await request(.getSessions(projectId: projectId, limit: limit, offset: offset))
        return response.sessions.map { dto in
            // Use the projectId parameter since backend doesn't include it in the response
            let session = Session(id: dto.id, projectId: projectId)
            // Map backend fields to Session model
            if let lastActivity = dto.lastActivity {
                session.startedAt = lastActivity  // Use lastActivity as startedAt
                session.lastActiveAt = lastActivity  // Use lastActivity as lastActiveAt
            }
            session.status = SessionStatus(rawValue: dto.status ?? "active") ?? .active
            return session
        }
    }
    
    func fetchMessages(projectId: String, sessionId: String) async throws -> [Message] {
        let messages: [MessageDTO] = try await request(.getMessages(projectId: projectId, sessionId: sessionId))
        return messages.map { dto in
            let message = Message(
                id: dto.id ?? UUID().uuidString,
                role: MessageRole(rawValue: dto.role) ?? .user,
                content: dto.content
            )
            message.timestamp = dto.timestamp ?? Date()
            return message
        }
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
        let data = try await request(endpoint)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 format first
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
    
    func request(_ endpoint: APIEndpoint) async throws -> Data {
        let urlRequest = try createRequest(for: endpoint)
        
        print("🌐 Making request to: \(urlRequest.url?.absoluteString ?? "nil")")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📦 Response status: \(httpResponse.statusCode)")
        print("📦 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return data
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
        return APIEndpoint(path: "/api/projects", method: .get)
    }
    
    static func createProject(name: String, path: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["name": name, "path": path])
        return APIEndpoint(path: "/api/projects", method: .post, body: body)
    }
    
    static func deleteProject(id: String) -> APIEndpoint {
        return APIEndpoint(path: "/api/projects/\(id)", method: .delete)
    }
    
    // Session endpoints
    static func getSessions(projectId: String, limit: Int = 5, offset: Int = 0) -> APIEndpoint {
        return APIEndpoint(path: "/api/projects/\(projectId)/sessions?limit=\(limit)&offset=\(offset)", method: .get)
    }
    
    static func createSession(projectId: String) -> APIEndpoint {
        return APIEndpoint(path: "/api/projects/\(projectId)/sessions", method: .post)
    }
    
    static func deleteSession(projectId: String, sessionId: String) -> APIEndpoint {
        return APIEndpoint(path: "/api/projects/\(projectId)/sessions/\(sessionId)", method: .delete)
    }
    
    static func getMessages(projectId: String, sessionId: String) -> APIEndpoint {
        return APIEndpoint(path: "/api/projects/\(projectId)/sessions/\(sessionId)/messages", method: .get)
    }
    
    // Session endpoints (direct)
    static func getSessionMessages(sessionId: String) -> APIEndpoint {
        return APIEndpoint(path: "/api/sessions/\(sessionId)/messages", method: .get)
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
    static func submitFeedback(_ feedback: FeedbackData) -> APIEndpoint {
        let body = try? JSONEncoder().encode([
            "type": feedback.type.rawValue,
            "message": feedback.message,
            "email": feedback.email ?? "",
            "deviceInfo": feedback.deviceInfo,
            "appVersion": feedback.appVersion,
            "hasScreenshot": feedback.screenshot != nil
        ])
        return APIEndpoint(path: "/api/feedback", method: .post, body: body)
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

struct SessionDTO: Codable {
    let id: String
    let projectId: String?  // Optional since backend doesn't include it
    let summary: String?
    let messageCount: Int?
    let lastActivity: Date?  // Backend uses "lastActivity" instead of "startedAt" and "lastActiveAt"
    let cwd: String?
    let status: String?  // Make optional since backend response doesn't include it
}

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