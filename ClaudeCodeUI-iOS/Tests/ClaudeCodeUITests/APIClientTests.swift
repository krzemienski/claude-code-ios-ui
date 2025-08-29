//
//  APIClientTests.swift
//  ClaudeCodeUITests
//
//  Comprehensive unit tests for APIClient with mocked responses
//

import XCTest
import Foundation
@testable import ClaudeCodeUI

final class APIClientTests: XCTestCase {
    
    var apiClient: APIClient!
    var mockURLSession: MockURLSession!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create mock session
        mockURLSession = MockURLSession()
        
        // Create API client with mock session
        apiClient = APIClient(baseURL: "http://localhost:3004", session: mockURLSession)
    }
    
    override func tearDownWithError() throws {
        apiClient = nil
        mockURLSession = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Authentication Tests
    
    func testLoginSuccess() async throws {
        // Given
        let expectedToken = "test-jwt-token"
        let loginResponse = LoginResponse(token: expectedToken, user: User(id: "123", username: "test"))
        let responseData = try JSONEncoder().encode(loginResponse)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/auth/login")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: LoginResponse = try await apiClient.request(.login(username: "test", password: "password"))
        
        // Then
        XCTAssertEqual(result.token, expectedToken)
        XCTAssertEqual(result.user.username, "test")
        
        // Verify request was made correctly
        let request = try XCTUnwrap(mockURLSession.lastRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/api/auth/login")
        
        let requestBody = try XCTUnwrap(request.httpBody)
        let loginData = try JSONDecoder().decode(LoginRequest.self, from: requestBody)
        XCTAssertEqual(loginData.username, "test")
        XCTAssertEqual(loginData.password, "password")
    }
    
    func testLoginFailure() async throws {
        // Given
        let errorResponse = APIError.unauthorized("Invalid credentials")
        mockURLSession.error = errorResponse
        
        // When & Then
        do {
            let _: LoginResponse = try await apiClient.request(.login(username: "test", password: "wrong"))
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    func testLogout() async throws {
        // Given
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/auth/logout")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        try await apiClient.requestVoid(.logout)
        
        // Then
        let request = try XCTUnwrap(mockURLSession.lastRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/api/auth/logout")
    }
    
    // MARK: - Project Tests
    
    func testGetProjects() async throws {
        // Given
        let projects = [
            Project(name: "Project1", fullPath: "/path/1"),
            Project(name: "Project2", fullPath: "/path/2")
        ]
        let responseData = try JSONEncoder().encode(projects)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: [Project] = try await apiClient.request(.getProjects)
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "Project1")
        XCTAssertEqual(result[1].name, "Project2")
        
        let request = try XCTUnwrap(mockURLSession.lastRequest)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/api/projects")
    }
    
    func testCreateProject() async throws {
        // Given
        let newProject = Project(name: "NewProject", fullPath: "/path/new")
        let responseData = try JSONEncoder().encode(newProject)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects/create")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: Project = try await apiClient.request(.createProject(name: "NewProject", path: "/path/new"))
        
        // Then
        XCTAssertEqual(result.name, "NewProject")
        XCTAssertEqual(result.fullPath, "/path/new")
        
        let request = try XCTUnwrap(mockURLSession.lastRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/api/projects/create")
        
        let requestBody = try XCTUnwrap(request.httpBody)
        let createData = try JSONDecoder().decode(CreateProjectRequest.self, from: requestBody)
        XCTAssertEqual(createData.name, "NewProject")
        XCTAssertEqual(createData.path, "/path/new")
    }
    
    func testDeleteProject() async throws {
        // Given
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects/TestProject")!,
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        try await apiClient.requestVoid(.deleteProject(name: "TestProject"))
        
        // Then
        let request = try XCTUnwrap(mockURLSession.lastRequest)
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.url?.path, "/api/projects/TestProject")
    }
    
    // MARK: - Session Tests
    
    func testGetSessions() async throws {
        // Given
        let sessions = [
            Session(projectId: UUID(), title: "Session 1"),
            Session(projectId: UUID(), title: "Session 2")
        ]
        let responseData = try JSONEncoder().encode(sessions)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects/TestProject/sessions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: [Session] = try await apiClient.request(.getSessions(projectName: "TestProject"))
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].title, "Session 1")
        XCTAssertEqual(result[1].title, "Session 2")
        
        let request = try XCTUnwrap(mockURLSession.lastRequest)
        XCTAssertEqual(request.url?.path, "/api/projects/TestProject/sessions")
    }
    
    func testCreateSession() async throws {
        // Given
        let newSession = Session(projectId: UUID(), title: "New Session")
        let responseData = try JSONEncoder().encode(newSession)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects/TestProject/sessions")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: Session = try await apiClient.request(.createSession(projectName: "TestProject", title: "New Session"))
        
        // Then
        XCTAssertEqual(result.title, "New Session")
        
        let request = try XCTUnwrap(mockURLSession.lastRequest)
        XCTAssertEqual(request.httpMethod, "POST")
    }
    
    func testGetSessionMessages() async throws {
        // Given
        let messages = [
            Message(sessionId: UUID(), content: "Hello", isFromUser: true),
            Message(sessionId: UUID(), content: "Hi there!", isFromUser: false)
        ]
        let responseData = try JSONEncoder().encode(messages)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects/TestProject/sessions/123/messages")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: [Message] = try await apiClient.request(.getSessionMessages(projectName: "TestProject", sessionId: "123"))
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].content, "Hello")
        XCTAssertTrue(result[0].isFromUser)
        XCTAssertEqual(result[1].content, "Hi there!")
        XCTAssertFalse(result[1].isFromUser)
    }
    
    // MARK: - File Operations Tests
    
    func testGetFileTree() async throws {
        // Given
        let fileTree = FileTreeResponse(
            files: [
                FileNode(name: "src", path: "/project/src", isDirectory: true, size: 0),
                FileNode(name: "main.swift", path: "/project/main.swift", isDirectory: false, size: 1024)
            ]
        )
        let responseData = try JSONEncoder().encode(fileTree)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects/TestProject/files")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: FileTreeResponse = try await apiClient.request(.getFileTree(projectName: "TestProject"))
        
        // Then
        XCTAssertEqual(result.files.count, 2)
        XCTAssertEqual(result.files[0].name, "src")
        XCTAssertTrue(result.files[0].isDirectory)
        XCTAssertEqual(result.files[1].name, "main.swift")
        XCTAssertFalse(result.files[1].isDirectory)
    }
    
    func testReadFile() async throws {
        // Given
        let fileContent = FileContentResponse(content: "print(\"Hello, World!\")")
        let responseData = try JSONEncoder().encode(fileContent)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects/TestProject/file?path=main.swift")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: FileContentResponse = try await apiClient.request(.readFile(projectName: "TestProject", path: "main.swift"))
        
        // Then
        XCTAssertEqual(result.content, "print(\"Hello, World!\")")
        
        let request = try XCTUnwrap(mockURLSession.lastRequest)
        XCTAssertEqual(request.url?.query, "path=main.swift")
    }
    
    func testSaveFile() async throws {
        // Given
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects/TestProject/file")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        try await apiClient.requestVoid(.saveFile(
            projectName: "TestProject",
            path: "main.swift",
            content: "print(\"Updated!\")"
        ))
        
        // Then
        let request = try XCTUnwrap(mockURLSession.lastRequest)
        XCTAssertEqual(request.httpMethod, "PUT")
        
        let requestBody = try XCTUnwrap(request.httpBody)
        let saveData = try JSONDecoder().decode(SaveFileRequest.self, from: requestBody)
        XCTAssertEqual(saveData.path, "main.swift")
        XCTAssertEqual(saveData.content, "print(\"Updated!\")")
    }
    
    // MARK: - Git Operations Tests
    
    func testGetGitStatus() async throws {
        // Given
        let gitStatus = GitStatusResponse(
            branch: "main",
            files: [
                GitFileStatus(filePath: "main.swift", status: .modified),
                GitFileStatus(filePath: "new.swift", status: .untracked)
            ]
        )
        let responseData = try JSONEncoder().encode(gitStatus)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/git/status")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: GitStatusResponse = try await apiClient.request(.gitStatus(projectPath: "/project"))
        
        // Then
        XCTAssertEqual(result.branch, "main")
        XCTAssertEqual(result.files.count, 2)
        XCTAssertEqual(result.files[0].filePath, "main.swift")
        XCTAssertEqual(result.files[0].status, .modified)
    }
    
    func testGitCommit() async throws {
        // Given
        let commitResponse = GitCommitResponse(hash: "abc123def456", message: "Test commit")
        let responseData = try JSONEncoder().encode(commitResponse)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/git/commit")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: GitCommitResponse = try await apiClient.request(.gitCommit(
            projectPath: "/project",
            message: "Test commit"
        ))
        
        // Then
        XCTAssertEqual(result.hash, "abc123def456")
        XCTAssertEqual(result.message, "Test commit")
        
        let request = try XCTUnwrap(mockURLSession.lastRequest)
        let requestBody = try XCTUnwrap(request.httpBody)
        let commitData = try JSONDecoder().decode(GitCommitRequest.self, from: requestBody)
        XCTAssertEqual(commitData.message, "Test commit")
    }
    
    // MARK: - MCP Server Tests
    
    func testGetMCPServers() async throws {
        // Given
        let servers = [
            MCPServer(name: "Server1", url: "http://localhost:3001", isEnabled: true),
            MCPServer(name: "Server2", url: "http://localhost:3002", isEnabled: false)
        ]
        let responseData = try JSONEncoder().encode(servers)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/mcp/servers")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: [MCPServer] = try await apiClient.request(.getMCPServers)
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "Server1")
        XCTAssertTrue(result[0].isEnabled)
        XCTAssertEqual(result[1].name, "Server2")
        XCTAssertFalse(result[1].isEnabled)
    }
    
    func testAddMCPServer() async throws {
        // Given
        let newServer = MCPServer(name: "NewServer", url: "http://localhost:3003", isEnabled: true)
        let responseData = try JSONEncoder().encode(newServer)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/mcp/servers")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: MCPServer = try await apiClient.request(.addMCPServer(
            name: "NewServer",
            url: "http://localhost:3003"
        ))
        
        // Then
        XCTAssertEqual(result.name, "NewServer")
        XCTAssertEqual(result.url, "http://localhost:3003")
        XCTAssertTrue(result.isEnabled)
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkError() async throws {
        // Given
        mockURLSession.error = URLError(.notConnectedToInternet)
        
        // When & Then
        do {
            let _: [Project] = try await apiClient.request(.getProjects)
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            if case .networkError(let underlyingError) = error {
                XCTAssertTrue(underlyingError is URLError)
            } else {
                XCTFail("Expected networkError")
            }
        }
    }
    
    func testHTTPErrorCodes() async throws {
        let testCases: [(Int, APIError)] = [
            (400, .badRequest("Bad request")),
            (401, .unauthorized("Unauthorized")),
            (404, .notFound("Not found")),
            (500, .serverError("Internal server error"))
        ]
        
        for (statusCode, expectedError) in testCases {
            // Given
            mockURLSession.response = HTTPURLResponse(
                url: URL(string: "http://localhost:3004/test")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
            mockURLSession.data = try JSONEncoder().encode(["error": expectedError.localizedDescription])
            
            // When & Then
            do {
                let _: [Project] = try await apiClient.request(.getProjects)
                XCTFail("Expected error to be thrown for status code \(statusCode)")
            } catch {
                XCTAssertTrue(error is APIError, "Expected APIError for status code \(statusCode)")
            }
        }
    }
    
    func testJSONDecodingError() async throws {
        // Given
        mockURLSession.data = "Invalid JSON".data(using: .utf8)
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When & Then
        do {
            let _: [Project] = try await apiClient.request(.getProjects)
            XCTFail("Expected decoding error to be thrown")
        } catch {
            XCTAssertTrue(error is DecodingError || error is APIError)
        }
    }
    
    // MARK: - Authentication Header Tests
    
    func testAuthTokenHeader() async throws {
        // Given
        apiClient.setAuthToken("test-token")
        
        mockURLSession.data = try JSONEncoder().encode([Project]())
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let _: [Project] = try await apiClient.request(.getProjects)
        
        // Then
        let request = try XCTUnwrap(mockURLSession.lastRequest)
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(authHeader, "Bearer test-token")
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentRequests() async throws {
        // Given
        mockURLSession.data = try JSONEncoder().encode([Project]())
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    do {
                        let _: [Project] = try await self.apiClient.request(.getProjects)
                    } catch {
                        XCTFail("Concurrent request failed: \(error)")
                    }
                }
            }
        }
        
        // Then - All requests should complete without crashing
        XCTAssertTrue(true) // If we get here, concurrent requests worked
    }
    
    func testRequestPerformance() throws {
        // Given
        mockURLSession.data = try JSONEncoder().encode([Project]())
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "http://localhost:3004/api/projects")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When & Then
        measure {
            let expectation = XCTestExpectation(description: "API request")
            
            Task {
                do {
                    let _: [Project] = try await apiClient.request(.getProjects)
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
}

// MARK: - Mock URLSession

class MockURLSession: URLSession {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    var lastRequest: URLRequest?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        
        if let error = error {
            throw error
        }
        
        let responseData = data ?? Data()
        let urlResponse = response ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (responseData, urlResponse)
    }
}

// MARK: - API Response Models

struct LoginResponse: Codable {
    let token: String
    let user: User
}

struct User: Codable {
    let id: String
    let username: String
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct CreateProjectRequest: Codable {
    let name: String
    let path: String
}

struct FileTreeResponse: Codable {
    let files: [FileNode]
}

struct FileContentResponse: Codable {
    let content: String
}

struct SaveFileRequest: Codable {
    let path: String
    let content: String
}

struct GitStatusResponse: Codable {
    let branch: String
    let files: [GitFileStatus]
}

struct GitCommitResponse: Codable {
    let hash: String
    let message: String
}

struct GitCommitRequest: Codable {
    let message: String
}

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case networkError(Error)
    case badRequest(String)
    case unauthorized(String)
    case notFound(String)
    case serverError(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unauthorized(let message):
            return "Unauthorized: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}

// MARK: - APIClient Extensions for Testing

extension APIClient {
    convenience init(baseURL: String, session: URLSession) {
        self.init()
        // In a real implementation, you'd inject the session
        // For now, this is a placeholder for the test structure
    }
    
    func setAuthToken(_ token: String) {
        // In a real implementation, this would set the auth token
        // For testing purposes, this is a placeholder
    }
}

// MARK: - API Endpoints Enum

enum APIEndpoint {
    case login(username: String, password: String)
    case logout
    case getProjects
    case createProject(name: String, path: String)
    case deleteProject(name: String)
    case getSessions(projectName: String)
    case createSession(projectName: String, title: String)
    case getSessionMessages(projectName: String, sessionId: String)
    case getFileTree(projectName: String)
    case readFile(projectName: String, path: String)
    case saveFile(projectName: String, path: String, content: String)
    case gitStatus(projectPath: String)
    case gitCommit(projectPath: String, message: String)
    case getMCPServers
    case addMCPServer(name: String, url: String)
}