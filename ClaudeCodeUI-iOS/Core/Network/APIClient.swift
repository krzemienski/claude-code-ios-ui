//
//  APIClient.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation

// MARK: - API Client Protocol
protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func request(_ endpoint: APIEndpoint) async throws -> Data
    func request(_ endpoint: APIEndpoint) async throws
}

// MARK: - API Client
actor APIClient: APIClientProtocol {
    
    // MARK: - Properties
    private let baseURL: String
    private let session: URLSession
    private var authToken: String?
    
    // MARK: - Initialization
    init(baseURL: String = AppConfig.backendURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    // MARK: - Authentication
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    // MARK: - Convenience Methods
    func fetchProjects() async throws -> [Project] {
        let response: ProjectsResponse = try await request(.getProjects())
        return response.projects.map { dto in
            Project(
                id: dto.id,
                name: dto.name,
                path: dto.path,
                displayName: dto.displayName,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt
            )
        }
    }
    
    // MARK: - Request Methods
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let data = try await request(endpoint)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func request(_ endpoint: APIEndpoint) async throws -> Data {
        let request = try createRequest(for: endpoint)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return data
    }
    
    func request(_ endpoint: APIEndpoint) async throws {
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
    static func login(email: String, password: String) -> APIEndpoint {
        let body = try? JSONEncoder().encode(["email": email, "password": password])
        return APIEndpoint(path: "/api/auth/login", method: .post, body: body)
    }
    
    static func logout() -> APIEndpoint {
        return APIEndpoint(path: "/api/auth/logout", method: .post)
    }
    
    static func checkAuth() -> APIEndpoint {
        return APIEndpoint(path: "/api/auth/check", method: .get)
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
}

// MARK: - Response Models
struct AuthResponse: Codable {
    let success: Bool
    let token: String?
    let user: User?
}

struct User: Codable {
    let id: String
    let email: String
    let name: String?
}

struct ProjectsResponse: Codable {
    let projects: [ProjectDTO]
}

struct ProjectDTO: Codable {
    let id: String
    let name: String
    let path: String
    let displayName: String?
    let createdAt: Date
    let updatedAt: Date
}

struct SessionsResponse: Codable {
    let sessions: [SessionDTO]
    let total: Int
}

struct SessionDTO: Codable {
    let id: String
    let projectId: String
    let startedAt: Date
    let lastActiveAt: Date
    let status: String
}

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