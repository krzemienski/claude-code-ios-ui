//
//  ChatViewController_Part2.swift
//  ClaudeCodeUI
//
//  Continuation of ChatViewController test messages
//

import Foundation
import UIKit

extension ChatViewController {
    
    // MARK: - Test Message Creation (Continuation)
    
    internal func createTestMessages() -> [EnhancedChatMessage] {
        var testMessages: [EnhancedChatMessage] = []
        let baseTime = Date().addingTimeInterval(-3600) // Start 1 hour ago
        
        // Create diverse test messages to demonstrate all message types
        for i in 0..<120 {
            let time = baseTime.addingTimeInterval(TimeInterval(i * 30)) // 30 seconds apart
            
            switch i % 10 {
            case 0:
                // User message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Can you help me implement a REST API with authentication? Message #\(i)",
                    isUser: true,
                    timestamp: time,
                    status: .sent
                )
                testMessages.append(msg)
                
            case 1:
                // Claude thinking
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "I'll help you implement a REST API with authentication. Let me break this down into steps...",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .thinking
                testMessages.append(msg)
                
            case 2:
                // Tool use message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Using tool to analyze project structure",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .toolUse
                msg.toolUseData = ToolUseData(
                    name: "Read",
                    parameters: ["file": "package.json", "lines": "1-50"],
                    result: "Successfully read package.json",
                    status: "success"
                )
                testMessages.append(msg)
                
            case 3:
                // Todo update message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Updated project tasks",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .todoUpdate
                msg.todos = [
                    TodoItem(
                        id: "todo-1",
                        title: "Set up Express server",
                        description: "Initialize Express with middleware",
                        status: .completed,
                        priority: .high
                    ),
                    TodoItem(
                        id: "todo-2",
                        title: "Implement JWT authentication",
                        description: "Add JWT token generation and validation",
                        status: .inProgress,
                        priority: .high
                    ),
                    TodoItem(
                        id: "todo-3",
                        title: "Create user endpoints",
                        description: "CRUD operations for users",
                        status: .pending,
                        priority: .medium
                    ),
                    TodoItem(
                        id: "todo-4",
                        title: "Add input validation",
                        description: "Validate request data",
                        status: .pending,
                        priority: .low
                    )
                ]
                testMessages.append(msg)
                
            case 4:
                // Code message with proper Swift code
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: """
                    Here's the authentication middleware in Swift:
                    
                    ```swift
                    import Foundation
                    import CryptoKit
                    
                    class JWTAuthenticator {
                        private let secret: String
                        
                        init(secret: String) {
                            self.secret = secret
                        }
                        
                        func generateToken(userId: String) -> String? {
                            let header = ["alg": "HS256", "typ": "JWT"]
                            let payload = [
                                "userId": userId,
                                "iat": Int(Date().timeIntervalSince1970),
                                "exp": Int(Date().addingTimeInterval(3600).timeIntervalSince1970)
                            ]
                            
                            // Implementation details...
                            return "generated.jwt.token"
                        }
                        
                        func verifyToken(_ token: String) -> Bool {
                            // Token verification logic
                            return true
                        }
                    }
                    ```
                    """,
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .code
                testMessages.append(msg)
                
            case 5:
                // Git operation message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "git commit -m 'Add authentication middleware'",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .gitOperation
                msg.gitChanges = [
                    "Added: auth/JWTAuthenticator.swift",
                    "Modified: Package.swift",
                    "Modified: README.md"
                ]
                testMessages.append(msg)
                
            case 6:
                // Terminal command
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "$ swift build",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .terminalCommand
                msg.terminalOutput = """
                Building for debugging...
                [1/3] Compiling Authentication JWTAuthenticator.swift
                [2/3] Compiling App main.swift
                [3/3] Linking App
                Build complete! (2.34s)
                """
                testMessages.append(msg)
                
            case 7:
                // File operation
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Created authentication files",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .fileOperation
                msg.fileOperations = [
                    "Created: Sources/Authentication/JWTAuthenticator.swift",
                    "Created: Sources/Authentication/UserModel.swift",
                    "Created: Tests/AuthenticationTests/JWTTests.swift"
                ]
                testMessages.append(msg)
                
            case 8:
                // Error message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Error: Failed to compile authentication module",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .error
                msg.errorDetails = "Missing required dependency: CryptoKit"
                testMessages.append(msg)
                
            case 9:
                // Claude response
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: """
                    I've successfully set up the authentication system with JWT tokens. The implementation includes:
                    
                    1. JWT token generation with proper expiration
                    2. Token verification middleware
                    3. Secure password hashing
                    4. User session management
                    
                    The authentication flow is now ready for testing. Would you like me to create some unit tests?
                    """,
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                msg.messageType = .claudeResponse
                testMessages.append(msg)
                
            default:
                // Regular assistant message
                let msg = EnhancedChatMessage(
                    id: "msg-\(i)",
                    content: "Processing request #\(i)...",
                    isUser: false,
                    timestamp: time,
                    status: .sent
                )
                testMessages.append(msg)
            }
        }
        
        return testMessages
    }
}