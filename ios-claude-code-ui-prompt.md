# iOS Claude Code UI: Comprehensive Development Prompt

## Original Repository
**Clone this first:** https://github.com/siteboon/claudecodeui.git

## Executive Summary

Build a native iOS application in Swift that replicates and enhances the functionality of the claudecodeui web application, providing a mobile-first interface for Claude Code CLI with real-time WebSocket communication, dark cyberpunk aesthetics, and comprehensive session management capabilities.

## Project Directory Structure
```
workspace/
├── claudecodeui-reference/     # Original web app (for reference only)
│   ├── backend/
│   ├── frontend/
│   └── package.json
└── ClaudeCodeUI-iOS/          # Your iOS project (main working directory)
    ├── App/
    ├── Core/
    ├── Features/
    ├── Design/
    ├── Resources/
    └── Documentation/
        └── Analysis/          # Analysis of original codebase
```

## 0. Pre-Development Setup

### 0.1 Git Branch Creation
```bash
# First, ensure we're on the main branch
git checkout main
git pull origin main

# Create and checkout new feature branch
git checkout -b feature/ios-claude-code-ui

# Initial commit
git add .gitignore
git commit -m "chore: initialize iOS Claude Code UI project"
```

### 0.2 MCP Server Initialization
**MANDATORY BEFORE STARTING:**
1. **Activate Sequential Thinking MCP** for systematic task breakdown
2. **Activate Context7 MCP** for real-time documentation access
3. **Activate Memory MCP** for storing project context and decisions
4. **Set up Claude Code Todo Tracking**:
   ```
   claude todo add "iOS Claude Code UI Development"
   claude todo add "Phase 1: Foundation Setup"
   claude todo add "Phase 2: Authentication & Projects"
   claude todo add "Phase 3: Chat Interface"
   claude todo add "Phase 4: File Explorer"
   claude todo add "Phase 5: Terminal Implementation"
   claude todo add "Phase 6: Polish & Optimization"
   ```

## 1. Mandatory Code Base Analysis Phase

### 1.1 Pre-Development Requirements
**BEFORE ANY CODING BEGINS:**
- Clone the claudecodeui repository (already done in step 0.1)
- Create new git branch for the iOS project
- Set up Claude Code todo structure
- Analyze the complete claudecodeui repository structure
- Map every dependency and API endpoint
- Document all WebSocket message formats
- Extract all UI components and their interactions
- Understand the Claude Code CLI integration patterns
- Save complete analysis to memory MCP

### 1.2 Detailed Analysis Tasks
```bash
# Navigate to cloned repository
cd ../claudecodeui-reference

# 1. Analyze Backend Structure
echo "=== Backend Analysis ===" >> ../ClaudeCodeUI-iOS/Documentation/Analysis/backend-analysis.md
cat backend/server.js >> ../ClaudeCodeUI-iOS/Documentation/Analysis/backend-analysis.md

# 2. Extract WebSocket Message Types
grep -h "ws.send\|socket.send" backend/*.js | sort | uniq >> ../ClaudeCodeUI-iOS/Documentation/Analysis/websocket-messages.md

# 3. Document API Endpoints
echo "=== API Endpoints ===" >> ../ClaudeCodeUI-iOS/Documentation/Analysis/api-endpoints.md
grep -E "(app\.|router\.)(get|post|put|delete|patch)" backend/*.js >> ../ClaudeCodeUI-iOS/Documentation/Analysis/api-endpoints.md

# 4. Analyze Claude CLI Integration
echo "=== Claude CLI Integration ===" >> ../ClaudeCodeUI-iOS/Documentation/Analysis/claude-cli.md
grep -r "spawn\|exec\|claude" backend/ >> ../ClaudeCodeUI-iOS/Documentation/Analysis/claude-cli.md

# 5. Extract Frontend WebSocket Client Logic
echo "=== Frontend WebSocket Logic ===" >> ../ClaudeCodeUI-iOS/Documentation/Analysis/frontend-websocket.md
find frontend/src -type f -name "*.js" -exec grep -l "WebSocket" {} \; | xargs cat >> ../ClaudeCodeUI-iOS/Documentation/Analysis/frontend-websocket.md

# 6. Document Data Models
echo "=== Data Models ===" >> ../ClaudeCodeUI-iOS/Documentation/Analysis/data-models.md
find . -name "*.ts" -o -name "types.js" | xargs cat >> ../ClaudeCodeUI-iOS/Documentation/Analysis/data-models.md

# Return to iOS project
cd ../ClaudeCodeUI-iOS

# Commit analysis
git add Documentation/Analysis/
git commit -m "docs: complete claudecodeui codebase analysis"
claude todo complete "Analyze original claudecodeui codebase"
```

### 1.3 Claude Code Todo Structure
```bash
# Main project todo (already created in step 0.4)
claude todo list --project "ios-app"

# Add specific analysis subtasks
claude todo add "Extract WebSocket protocol" --parent "Analyze original claudecodeui codebase"
claude todo add "Document API endpoints" --parent "Analyze original claudecodeui codebase"
claude todo add "Analyze streaming implementation" --parent "Analyze original claudecodeui codebase"
claude todo add "Map UI components to iOS equivalents" --parent "Analyze original claudecodeui codebase"

# Complete as you analyze
claude todo complete "Extract WebSocket protocol"
claude todo complete "Document API endpoints"
# etc...
```

### 1.4 Core Components to Analyze
```
claudecodeui-reference/
├── backend/
│   ├── server.js (Express + WebSocket server)
│   ├── claudeCliManager.js (Process spawning)
│   ├── sessionManager.js (JSONL parsing)
│   └── fileSystemAPI.js (File operations)
├── frontend/
│   ├── components/ (React components to map to iOS)
│   ├── stores/ (State management patterns)
│   └── services/ (WebSocket client implementation)
├── shared/
│   └── types/ (Data models to convert to Swift)
└── package.json (Dependencies to understand)
```

### 1.5 Save Analysis to Memory MCP
```bash
# After completing analysis, store in Memory MCP
memory store "claudecodeui-project-structure" "Backend: Express.js, Frontend: React/Vite, WebSocket: ws library..."
memory store "websocket-message-types" "connection, session:start, session:message, session:end, project:list..."
memory store "api-endpoint-patterns" "RESTful: GET /api/projects, POST /api/sessions, WebSocket: /ws"
memory store "streaming-implementation" "Uses chunked responses with stream:start, stream:chunk, stream:end events"
memory store "ui-component-mapping" "ProjectCard → iOS UICollectionViewCell, Chat → iOS ChatViewController..."
```

## 2. Technical Architecture

### 2.1 Backend Server Configuration (From Original ClaudeCodeUI)
```swift
// Based on analysis of claudecodeui/backend/server.js
struct BackendConfiguration {
    let host: String = "localhost"
    let port: Int = 3001  // Default from original implementation
    let websocketPath: String = "/ws"
    let apiBasePath: String = "/api"
    let claudeProjectsPath: String = "~/.claude/projects/"
    
    // Endpoints discovered from backend analysis
    struct Endpoints {
        static let projects = "/api/projects"
        static let sessions = "/api/sessions"
        static let files = "/api/files"
        static let terminal = "/api/terminal"
    }
}

// Key implementation details from original
struct OriginalImplementationNotes {
    // The backend spawns Claude CLI processes
    // Sessions are stored as JSONL files
    // WebSocket handles real-time streaming
    // File operations use Node.js fs module
    // Project discovery from ~/.claude/projects/
}
```

### 2.2 WebSocket Message Protocol (Based on Original Implementation)
```swift
// Extract from claudecodeui backend analysis
enum WebSocketMessageType: String, Codable {
    case connection = "connection"
    case sessionStart = "session:start"
    case sessionMessage = "session:message"
    case sessionEnd = "session:end"
    case projectList = "project:list"
    case projectCreate = "project:create"
    case projectDelete = "project:delete"
    case fileOperation = "file:operation"
    case streamingResponse = "stream:response"
    case streamStart = "stream:start"
    case streamChunk = "stream:chunk"
    case streamEnd = "stream:end"
    case error = "error"
}

struct WebSocketMessage: Codable {
    let type: WebSocketMessageType
    let payload: [String: Any]
    let timestamp: Date
    let sessionId: String?
}

// Based on claudecodeui/backend/server.js WebSocket implementation
class WebSocketProtocol {
    static let defaultPort = 3001
    static let websocketPath = "/ws"
    static let heartbeatInterval: TimeInterval = 30.0
    static let reconnectDelay: TimeInterval = 5.0
}
```

### 2.3 Streaming JSON Response Handler
```swift
protocol StreamingJSONParser {
    func parseChunk(_ data: Data) -> StreamingResponse?
    func handlePartialJSON(_ partial: String)
    func assembleCompleteResponse() -> ClaudeResponse
}

struct StreamingResponse {
    let content: String
    let isComplete: Bool
    let metadata: ResponseMetadata
}
```

## 3. iOS Application Architecture

### 3.1 Core Frameworks
- **UIKit/SwiftUI**: Hybrid approach for optimal performance
- **Combine**: Reactive programming for data flow
- **URLSession**: WebSocket implementation
- **SwiftData**: Modern persistence framework for iOS 17+
- **KeychainServices**: Secure credential storage
- **Observation**: Swift's new observation framework

### 3.2 Project Structure
```
ClaudeCodeUI-iOS/
├── App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── Configuration/
├── Core/
│   ├── Network/
│   │   ├── WebSocketManager.swift
│   │   ├── APIClient.swift
│   │   └── StreamingParser.swift
│   ├── Data/
│   │   ├── Models/
│   │   ├── SwiftDataContainer.swift
│   │   └── Repositories/
│   └── Services/
│       ├── ClaudeCodeService.swift
│       ├── SessionManager.swift
│       └── FileSystemService.swift
├── Features/
│   ├── Projects/
│   ├── Chat/
│   ├── FileExplorer/
│   ├── Terminal/
│   └── Settings/
├── Design/
│   ├── Theme/
│   ├── Components/
│   └── Extensions/
└── Resources/
```

## 4. Detailed Screen Specifications

### 4.1 Launch Screen
**Design Requirements:**
- Dark background (#0A0A0F)
- "CLAUDE CODE" text in cyan (#00D9FF) with large, bold typography
- Blue to purple gradient blocks animation
- Grid pattern background with subtle lines
- Face ID icon animation for authentication
- Smooth transition to main app

**Technical Implementation:**
```swift
class LaunchViewController: UIViewController {
    // Display CLAUDE CODE branding
    // Animate gradient blocks
    // Show Face ID authentication
    // Grid background pattern
    // WebSocket connection initialization
}
```

### 4.2 Projects Dashboard
**Wireframe:**
```
┌─────────────────────────────────┐
│ CLAUDE CODE              [···]  │ (Cyan text, ellipsis menu)
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ [▶] Project Name           │ │ (Play icon, white text)
│ │ Body text description      │ │ (Gray text)
│ │ Caption • 2h ago           │ │ (Lighter gray)
│ │ ■ ■                        │ │ (Blue/Purple gradient blocks)
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ [▶] Another Project        │ │
│ │ Body text here            │ │
│ │ Caption • 1d ago          │ │
│ │ ■ ■                       │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ [🏠] [💬] [👤] [⚙]            │ (Bottom nav: home, chat, user, settings)
└─────────────────────────────────┘
```

### 4.3 Chat Interface (Claude Code Design)
**Wireframe:**
```
┌─────────────────────────────────┐
│ [←] Chat Session         [···]  │
├─────────────────────────────────┤
│ ╔═══════════════════════════╗   │
│ ║ Claude:                  ║   │ (Cyan accent border)
│ ║ Title text               ║   │ (White text)
│ ║ Body response here...    ║   │ (Light gray)
│ ║ ```swift                 ║   │
│ ║ // Code block           ║   │ (Cyan syntax)
│ ║ ```                     ║   │
│ ╚═══════════════════════════╝   │
│                                  │
│         ╔═══════════════╗       │
│         ║ You:         ║       │ (Pink accent)
│         ║ Message text ║       │
│         ╚═══════════════╝       │
├─────────────────────────────────┤
│ [+] [Type message...]      [▶]  │ (Cyan icons)
└─────────────────────────────────┘
```

### 4.4 Authentication Screen (Sign In)
**Wireframe:**
```
┌─────────────────────────────────┐
│                                 │
│        CLAUDE CODE              │ (Large cyan text)
│                                 │
│        ■    ■                   │ (Blue/Purple gradients)
│                                 │
│     ╔═══════════════════╗      │
│     ║                   ║      │
│     ║    [Face ID]      ║      │ (Cyan Face ID icon)
│     ║                   ║      │
│     ║    Sign In        ║      │ (Cyan text)
│     ║                   ║      │
│     ╚═══════════════════╝      │ (Cyan border with glow)
│                                 │
│   Title                         │ (Typography examples)
│   Body                          │
│   Caption                       │
│                                 │
│   [🔑] Use Passcode            │ (Alternative option)
└─────────────────────────────────┘
(Grid pattern background throughout)
```

**API Calls:**
```swift
// GET /api/projects
func fetchProjects() async throws -> [Project]

// POST /api/projects
func createProject(_ project: ProjectCreationRequest) async throws -> Project

// DELETE /api/projects/:id
func deleteProject(_ projectId: String) async throws

// Project cell implementation with Claude Code design
struct ProjectCell: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "play.fill")
                    .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                Text(project.name)
                    .font(.title3)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(project.description)
                .font(.body)
                .foregroundColor(Color(CyberpunkTheme.textSecondary))
            
            HStack {
                Text("\(project.sessions.count) sessions • Updated \(project.updatedAt.timeAgo())")
                    .font(.caption)
                    .foregroundColor(Color(CyberpunkTheme.textTertiary))
                
                Spacer()
                
                GradientBlockPair()
                    .scaleEffect(0.6)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(CyberpunkTheme.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(CyberpunkTheme.primaryCyan).opacity(0.3), lineWidth: 1)
                )
        )
    }
}
```

### 4.3 Chat Interface
**Wireframe:**
```
┌─────────────────────────────────┐
│ ←  iOS Banking App         ⚙️   │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ Claude: I'll help you      │ │
│ │ implement the login screen. │ │
│ │ Here's the Swift code...    │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │ class LoginViewController│ │ │
│ │ │   // Code block         │ │ │
│ │ └─────────────────────────┘ │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ You: Add biometric auth    │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ [📎] [Type message...]     [→]  │
└─────────────────────────────────┘
```

**Streaming Implementation:**
```swift
class ChatViewController: UIViewController {
    private var webSocketConnection: WebSocketConnection?
    private var streamingParser: StreamingJSONParser
    
    func sendMessage(_ content: String) {
        let message = WebSocketMessage(
            type: .sessionMessage,
            payload: ["content": content],
            timestamp: Date(),
            sessionId: currentSessionId
        )
        webSocketConnection?.send(message)
    }
    
    func handleStreamingResponse(_ data: Data) {
        if let response = streamingParser.parseChunk(data) {
            updateChatUI(with: response)
        }
    }
}

// Claude Code Chat Bubble Design
struct ChatBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .assistant {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Claude:")
                        .font(.caption)
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(CyberpunkTheme.primaryCyan), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(CyberpunkTheme.surface).opacity(0.5))
                                )
                        )
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("You:")
                        .font(.caption)
                        .foregroundColor(Color(CyberpunkTheme.accentPink))
                    
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(CyberpunkTheme.accentPink), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(CyberpunkTheme.surface).opacity(0.5))
                                )
                        )
                }
            }
        }
        .padding(.horizontal)
    }
}
```

### 4.4 File Explorer
**Wireframe:**
```
┌─────────────────────────────────┐
│ ←  File Explorer          [📁+] │
├─────────────────────────────────┤
│ 📁 src/                         │
│   📁 controllers/               │
│     📄 AuthController.swift     │
│     📄 UserController.swift     │
│   📁 models/                    │
│     📄 User.swift               │
│   📁 views/                     │
│     📄 LoginView.swift          │
├─────────────────────────────────┤
│ File: AuthController.swift      │
│ ┌─────────────────────────────┐ │
│ │ import UIKit                │ │
│ │ class AuthController {      │ │
│ │   // Syntax highlighted     │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### 4.5 Terminal Interface
**Wireframe:**
```
┌─────────────────────────────────┐
│ Terminal                    [X] │
├─────────────────────────────────┤
│ $ claude --version              │
│ Claude Code v1.2.0              │
│ $ claude chat                   │
│ Starting new session...         │
│ > Help me optimize this code    │
│ Claude: I'll analyze your...    │
│ █                               │
└─────────────────────────────────┘
```

## 5. Dark Cyberpunk Theme Specification (Based on Claude Code Design System)

### Design System Implementation Requirements
**CRITICAL**: The app MUST exactly match the Claude Code design system shown in the reference images. No deviations or "creative interpretations" are allowed. Every color, spacing, corner radius, and effect must be pixel-perfect.

### 5.1 Color Palette
```swift
struct CyberpunkTheme {
    // Primary Colors (from design system)
    static let background = UIColor(hex: "#0A0A0F") // Near black
    static let surface = UIColor(hex: "#1A1A2E") // Dark blue-gray
    static let primaryCyan = UIColor(hex: "#00D9FF") // Bright cyan (main brand color)
    static let accentPink = UIColor(hex: "#FF006E") // Hot pink accent
    static let gradientBlue = UIColor(hex: "#0066FF") // Gradient start
    static let gradientPurple = UIColor(hex: "#9933FF") // Gradient end
    
    // Text Colors
    static let textPrimary = UIColor(hex: "#FFFFFF") // Pure white for headers
    static let textSecondary = UIColor(hex: "#E0E0E0") // Light gray for body
    static let textTertiary = UIColor(hex: "#A0A0A0") // Medium gray for captions
    static let textCyan = UIColor(hex: "#00D9FF") // Cyan for interactive text
    
    // Icon Colors
    static let iconCyan = UIColor(hex: "#00D9FF") // Primary icon color
    static let iconPink = UIColor(hex: "#FF006E") // Accent icon color
    
    // Effects
    static let glowColor = UIColor(hex: "#00D9FF").withAlphaComponent(0.6)
    static let gridLineColor = UIColor(hex: "#1A1A2E").withAlphaComponent(0.5)
    static let borderRadius: CGFloat = 16.0
    static let glowIntensity: CGFloat = 0.8
    static let animationDuration: TimeInterval = 0.3
}

// Typography System
struct Typography {
    // Dynamic Type Scale (from design system)
    static let largeTitle = UIFont.systemFont(ofSize: 34, weight: .bold) // "CLAUDE CODE"
    static let title = UIFont.systemFont(ofSize: 28, weight: .semibold) // "Title"
    static let body = UIFont.systemFont(ofSize: 17, weight: .regular) // "Body"
    static let caption = UIFont.systemFont(ofSize: 12, weight: .regular) // "Caption"
    
    // Dynamic Type examples from design
    static let mudium = UIFont.systemFont(ofSize: 20, weight: .medium) // "Mudium"
    static let small = UIFont.systemFont(ofSize: 14, weight: .regular) // "abcde"
    
    // Dynamic Type Support
    static func scaledFont(for style: UIFont.TextStyle) -> UIFont {
        return UIFont.preferredFont(forTextStyle: style)
    }
}
```

### 5.2 Icon System
```swift
struct IconSystem {
    // Icon set from design system
    enum Icons: String {
        // Top row
        case search = "magnifyingglass"
        case back = "chevron.backward"
        case forward = "chevron.forward" 
        case play = "play.circle"
        case ellipsis = "ellipsis.circle"
        
        // Middle row
        case location = "location"
        case comment = "bubble.left"
        case playFill = "play.fill"
        case chat = "message"
        case user = "person.circle"
        
        // Bottom row (first set)
        case upload = "arrow.up.circle"
        case message = "bubble.right"
        case circle = "circle"
        case wand = "wand.and.rays"
        case settings = "gearshape"
        
        // Bottom row (second set)
        case home = "house"
        case shield = "shield"
        case lock = "lock"
        case person = "person"
        case flower = "camera.macro"
        
        // Additional icons from second image
        case trash = "trash"
        case cloud = "cloud"
        case folder = "folder"
        case wifi = "wifi"
        case wifiMedium = "wifi.medium"
        case wifiFull = "wifi"
        case volume = "speaker.wave.3"
        case key = "key"
        case lockOpen = "lock.open"
        case plus = "plus"
        case minus = "minus"
        case camera = "camera"
    }
    
    static func icon(_ icon: Icons, size: CGFloat = 24) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: .regular)
        return UIImage(systemName: icon.rawValue, withConfiguration: config)
    }
}
```

### 5.3 UI Components
```swift
// Gradient Blocks (from design system)
struct GradientBlock: View {
    let colors: [Color]
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 60, height: 60)
    }
}

// Neon Button (Sign In style)
struct NeonButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                }
                Text(title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(CyberpunkTheme.primaryCyan))
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(CyberpunkTheme.primaryCyan), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(CyberpunkTheme.surface).opacity(0.3))
                    )
                    .shadow(color: Color(CyberpunkTheme.primaryCyan).opacity(0.5), radius: 10)
            )
        }
    }
}

// Face ID Authentication Button
struct FaceIDSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        NeonButton(
            title: "Sign In",
            icon: "faceid",
            action: action
        )
    }
}

// Grid Background Pattern
struct GridBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 40
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Vertical lines
                for x in stride(from: 0, to: width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                
                // Horizontal lines
                for y in stride(from: 0, to: height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color(CyberpunkTheme.gridLineColor), lineWidth: 0.5)
        }
    }
}
```

### 5.6 Gradient Blocks (Signature Element)
```swift
// The blue and purple gradient blocks are a key visual element
struct GradientBlockPair: View {
    var body: some View {
        HStack(spacing: 12) {
            // Blue gradient block
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [
                        Color(hex: "#0066FF"),
                        Color(hex: "#0044CC")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 44, height: 44)
                .shadow(color: Color(hex: "#0066FF").opacity(0.5), radius: 8)
            
            // Purple gradient block
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [
                        Color(hex: "#9933FF"),
                        Color(hex: "#FF006E")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 44, height: 44)
                .shadow(color: Color(hex: "#9933FF").opacity(0.5), radius: 8)
        }
    }
}

// Usage: Add gradient blocks to project cards, authentication screens, etc.
```

### 5.7 Grid Background Implementation
```swift
// Grid pattern that appears throughout the app
extension UIView {
    func addClaudeCodeGridBackground() {
        let gridLayer = CAShapeLayer()
        let path = UIBezierPath()
        let gridSize: CGFloat = 40
        
        // Vertical lines
        for x in stride(from: 0, to: bounds.width, by: gridSize) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: bounds.height))
        }
        
        // Horizontal lines
        for y in stride(from: 0, to: bounds.height, by: gridSize) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: bounds.width, y: y))
        }
        
        gridLayer.path = path.cgPath
        gridLayer.strokeColor = CyberpunkTheme.gridLineColor.cgColor
        gridLayer.lineWidth = 0.5
        gridLayer.opacity = 0.3
        
        layer.insertSublayer(gridLayer, at: 0)
    }
}
```

## 6. Data Models (SwiftData)

### 6.1 Core Models with SwiftData
```swift
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: String
    var name: String
    var path: String
    @Relationship(deleteRule: .cascade) var sessions: [Session]
    var createdAt: Date
    var updatedAt: Date
    var metadata: ProjectMetadata
    
    init(id: String, name: String, path: String) {
        self.id = id
        self.name = name
        self.path = path
        self.sessions = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.metadata = ProjectMetadata()
    }
}

@Model
final class Session {
    @Attribute(.unique) var id: String
    var projectId: String
    @Relationship(deleteRule: .cascade) var messages: [Message]
    var startedAt: Date
    var lastActiveAt: Date
    var status: SessionStatus
    
    init(id: String, projectId: String) {
        self.id = id
        self.projectId = projectId
        self.messages = []
        self.startedAt = Date()
        self.lastActiveAt = Date()
        self.status = .active
    }
}

@Model
final class Message {
    @Attribute(.unique) var id: String
    var role: String // Will map to MessageRole enum
    var content: String
    var timestamp: Date
    var metadata: MessageMetadata?
    
    init(id: String, role: String, content: String) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

// SwiftData Container Setup
@MainActor
class SwiftDataContainer {
    static let shared = SwiftDataContainer()
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            Project.self,
            Session.self,
            Message.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.claudecodeui.ios")
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
```

### 6.2 WebSocket Models
```swift
struct WebSocketFrame: Codable {
    let op: OpCode
    let d: Data?
    let s: Int?
    let t: String?
}

enum OpCode: Int, Codable {
    case dispatch = 0
    case heartbeat = 1
    case identify = 2
    case statusUpdate = 3
    case voiceStateUpdate = 4
    case resume = 6
    case reconnect = 7
    case requestGuildMembers = 8
    case invalidSession = 9
    case hello = 10
    case heartbeatAck = 11
}
```

## 7. API Endpoints Specification

### 7.1 RESTful Endpoints
```
GET    /api/projects
POST   /api/projects
GET    /api/projects/:id
PUT    /api/projects/:id
DELETE /api/projects/:id

GET    /api/sessions
POST   /api/sessions
GET    /api/sessions/:id
DELETE /api/sessions/:id

GET    /api/files/:projectId/*path
POST   /api/files/:projectId/*path
PUT    /api/files/:projectId/*path
DELETE /api/files/:projectId/*path
```

### 7.2 WebSocket Events
```
Client → Server:
- session:start
- session:message
- session:end
- file:read
- file:write
- terminal:command

Server → Client:
- stream:start
- stream:chunk
- stream:end
- file:updated
- error:occurred
```

## 8. Sequential Development Tasks (100+)

### Pre-Task Setup
**Before EVERY task:**
1. Use **Sequential Thinking MCP** to break down the task
2. Use **Context7 MCP** to fetch latest documentation
3. Update Claude Code todo status
4. Commit completed work to git

### Phase 1: Foundation (Tasks 1-21)
### Phase 2: Authentication & Projects (Tasks 22-41)
### Phase 3: Chat Interface (Tasks 42-61)
### Phase 4: File Explorer (Tasks 62-76)
### Phase 5: Terminal & Advanced Features (Tasks 77-91)
### Phase 6: Polish & Optimization (Tasks 92-110+)

### Phase 1: Foundation (Tasks 1-20)
1. **Initialize iOS project** with proper folder structure
   ```bash
   # Context7: Search "iOS project structure best practices 2024"
   
   # Native macOS
   if [[ "$IOS_DEV_ENV" == "native" ]]; then
       xcodebuild -createProject -name ClaudeCodeUI -language Swift
   # Docker Linux
   else
       docker exec claude-code-ui-ios-dev xcodebuild -createProject -name ClaudeCodeUI -language Swift
   fi
   
   git add .
   git commit -m "feat: initialize iOS project structure"
   claude todo complete "Initialize iOS project"
   ```

2. **Configure build settings** for iOS 17+ deployment (SwiftData requirement)
   ```bash
   # Context7: Search "SwiftData iOS 17 configuration"
   
   # For Docker environment, edit files locally then build in container
   if [[ "$IOS_DEV_ENV" == "docker" ]]; then
       echo "Edit xcodeproj settings locally, Docker will build with them"
       docker exec claude-code-ui-ios-dev xcodebuild -showBuildSettings
   fi
   
   git add xcodeproj/
   git commit -m "chore: configure iOS 17+ build settings for SwiftData"
   claude todo complete "Configure build settings"
   ```

3. **Set up SwiftLint** and code formatting rules
   ```bash
   # Context7: Search "SwiftLint configuration 2024"
   
   # Install SwiftLint
   if [[ "$IOS_DEV_ENV" == "native" ]]; then
       brew install swiftlint
   else
       docker exec claude-code-ui-ios-dev apt-get install -y swiftlint
   fi
   
   git add .swiftlint.yml
   git commit -m "chore: add SwiftLint configuration"
   claude todo complete "Set up SwiftLint"
   ```

4. **Create CyberpunkTheme** class with color definitions
   ```bash
   # Context7: Search "iOS dark theme implementation Swift"
   # Implement exact colors from Claude Code design system
   # Colors: #00D9FF (cyan), #FF006E (pink), #0066FF (blue), #9933FF (purple)
   git add Design/Theme/CyberpunkTheme.swift
   git commit -m "feat: implement Claude Code design system theme"
   claude todo complete "Create CyberpunkTheme"
   ```

5. **Implement ThemeManager** for dynamic theming
   ```bash
   # Include gradient block components
   # Grid background pattern implementation
   # Glow effects for cyan elements
   git add Design/Theme/ThemeManager.swift
   git commit -m "feat: add theme manager with Claude Code aesthetics"
   claude todo complete "Implement ThemeManager"
   ```

6. **Build custom UI components** from design system
   ```bash
   # Create GradientBlock view
   # NeonButton with Face ID style
   # GridBackground pattern view
   # Typography system with dynamic type
   git add Design/Components/ClaudeCodeComponents.swift
   git commit -m "feat: implement Claude Code UI components"
   ```

7. **Create base UIViewController** with Claude Code theme
   ```bash
   # Include grid background by default
   # Set up cyan navigation elements
   # Configure dark background color
   git add Core/Base/BaseViewController.swift
   git commit -m "feat: create Claude Code themed base controller"
   ```

8. **Set up SwiftData container** for local persistence
   ```bash
   # Context7: Search "SwiftData ModelContainer setup iOS 17"
   git add Core/Data/SwiftDataContainer.swift
   git commit -m "feat: configure SwiftData persistence layer"
   claude todo complete "Set up SwiftData"
   ```

9. **Implement KeychainWrapper** for secure storage
   ```bash
   # Context7: Search "iOS Keychain Swift wrapper"
   git add Core/Security/KeychainWrapper.swift
   git commit -m "feat: add keychain wrapper for secure storage"
   ```

10. **Create NetworkManager** base class
    ```bash
    # Context7: Search "URLSession best practices Swift"
    git add Core/Network/NetworkManager.swift
    git commit -m "feat: implement base network manager"
    ```

11. **Build WebSocketConnection** class
    ```bash
    # Context7: Search "URLSessionWebSocketTask implementation"
    git add Core/Network/WebSocketConnection.swift
    git commit -m "feat: implement WebSocket connection handler"
    claude todo complete "WebSocket implementation"
    ```

12. **Implement StreamingJSONParser** protocol
    ```bash
    # Context7: Search "streaming JSON parser Swift"
    git add Core/Network/StreamingJSONParser.swift
    git commit -m "feat: add streaming JSON parser for Claude responses"
    ```

13. **Create APIClient** with async/await support
    ```bash
    # Context7: Search "Swift async await networking"
    git add Core/Network/APIClient.swift
    git commit -m "feat: implement async/await API client"
    ```

14. **Set up dependency injection** container
    ```bash
    # Context7: Search "dependency injection Swift"
    git add Core/DI/DIContainer.swift
    git commit -m "feat: add dependency injection container"
    ```

15. **Implement Logger** service
    ```bash
    # Context7: Search "iOS logging best practices OSLog"
    git add Core/Services/Logger.swift
    git commit -m "feat: implement unified logging service"
    ```

16. **Create ErrorHandler** with user-friendly messages
    ```bash
    git add Core/Services/ErrorHandler.swift
    git commit -m "feat: add error handling service"
    ```

17. **Build LoadingViewController** with animations
    ```bash
    # Context7: Search "iOS loading animations Swift"
    git add Design/Components/LoadingViewController.swift
    git commit -m "feat: create animated loading view"
    ```

18. **Set up app navigation** structure
    ```bash
    # Context7: Search "iOS navigation architecture"
    git add Core/Navigation/
    git commit -m "feat: implement app navigation structure"
    ```

19. **Create custom tab bar** with neon effects
    ```bash
    # Context7: Search "custom UITabBar Swift animations"
    git add Design/Components/NeonTabBar.swift
    git commit -m "feat: add custom neon tab bar"
    ```

20. **Verify foundation on iPhone 16 Pro Max simulator**
    ```bash
    # Native macOS verification
    if [[ "$IOS_DEV_ENV" == "native" ]]; then
        # Run app in simulator
        xcodebuild -project ClaudeCodeUI-iOS.xcodeproj \
          -scheme ClaudeCodeUI \
          -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
          run
        
        # Take screenshots
        xcrun simctl io booted screenshot foundation-test.png
    
    # Docker Linux verification
    else
        # Build and run in Docker
        ./build-in-docker.sh
        ./run-simulator-docker.sh
        
        # Connect via VNC to see simulator
        echo "Connect VNC client to localhost:5900 to view simulator"
        echo "Take screenshots using VNC client screenshot feature"
        
        # Or capture programmatically
        docker exec claude-code-ui-ios-dev \
          xcrun simctl io booted screenshot /workspace/foundation-test.png
        docker cp claude-code-ui-ios-dev:/workspace/foundation-test.png ./
    fi
    
    # Document verification
    git add README.md screenshots/
    git commit -m "docs: add foundation verification screenshots"
    claude todo complete "Phase 1: Foundation Setup"
    ```

### Phase 2: Authentication & Projects (Tasks 22-41)
22. **Build authentication flow** UI with Claude Code design
    ```bash
    # Context7: Search "iOS authentication flow SwiftUI"
    # Implement Face ID Sign In button style
    # Use cyan borders and glow effects
    git add Features/Authentication/
    git commit -m "feat: implement Claude Code authentication UI"
    claude todo add "Authentication implementation"
    ```

23. **Implement biometric authentication** with Face ID icon
    ```bash
    # Context7: Search "LocalAuthentication framework Swift"
    # Create animated Face ID glyph
    # Match Claude Code Sign In screen design
    git add Core/Security/BiometricAuth.swift
    git commit -m "feat: add Face ID authentication with custom UI"
    ```

24. **Create login screen** with Claude Code branding
    ```bash
    # Large "CLAUDE CODE" text in cyan
    # Gradient blocks (blue to purple)
    # Grid background pattern
    # Face ID Sign In button with glow
    git add Features/Authentication/LoginView.swift
    git commit -m "feat: create Claude Code branded login screen"
    ```

24. **Build secure token storage**
    ```bash
    # Context7: Search "JWT token storage iOS Keychain"
    git add Core/Security/TokenManager.swift
    git commit -m "feat: implement secure token management"
    ```

25. **Implement auto-refresh token** logic
    ```bash
    git add Core/Network/TokenRefreshInterceptor.swift
    git commit -m "feat: add automatic token refresh"
    claude todo complete "Authentication implementation"
    ```

26. **Create ProjectsViewController**
    ```bash
    # Context7: Search "UICollectionView compositional layout"
    git add Features/Projects/ProjectsViewController.swift
    git commit -m "feat: create projects list view controller"
    ```

27. **Build project card** component
    ```bash
    git add Features/Projects/Components/ProjectCard.swift
    git commit -m "feat: implement project card UI component"
    ```

28. **Implement project list** API integration
    ```bash
    # Context7: Search "Swift async await API calls"
    git add Features/Projects/ProjectsViewModel.swift
    git commit -m "feat: integrate projects API"
    ```

29. **Add pull-to-refresh** with custom animation
    ```bash
    # Context7: Search "UIRefreshControl custom animation"
    git add Features/Projects/RefreshAnimator.swift
    git commit -m "feat: add custom pull-to-refresh animation"
    ```

30. **Create project creation** flow
    ```bash
    git add Features/Projects/CreateProjectView.swift
    git commit -m "feat: implement project creation flow"
    ```

31. **Build project deletion** with confirmation
    ```bash
    git add Features/Projects/ProjectDeletionHandler.swift
    git commit -m "feat: add project deletion with confirmation"
    ```

32. **Implement project search** functionality
    ```bash
    # Context7: Search "UISearchController implementation"
    git add Features/Projects/ProjectSearchController.swift
    git commit -m "feat: add project search functionality"
    ```

33. **Add project sorting** options
    ```bash
    git add Features/Projects/ProjectSortingOptions.swift
    git commit -m "feat: implement project sorting"
    ```

34. **Create empty state** view
    ```bash
    git add Design/Components/EmptyStateView.swift
    git commit -m "feat: add empty state UI component"
    ```

35. **Build project metadata** display
    ```bash
    git add Features/Projects/ProjectMetadataView.swift
    git commit -m "feat: create project metadata display"
    ```

36. **Implement offline project** caching with SwiftData
    ```bash
    # Context7: Search "SwiftData offline caching strategy"
    git add Core/Data/ProjectCache.swift
    git commit -m "feat: add offline project caching"
    ```

37. **Add project synchronization**
    ```bash
    git add Core/Sync/ProjectSyncManager.swift
    git commit -m "feat: implement project sync manager"
    ```

38. **Create project export** functionality
    ```bash
    # Context7: Search "iOS share sheet implementation"
    git add Features/Projects/ProjectExporter.swift
    git commit -m "feat: add project export feature"
    ```

39. **Test projects feature** on simulator
    ```bash
    # Screenshot and document
    git add screenshots/projects/
    git commit -m "test: add project feature screenshots"
    ```

40. **Capture screenshots** for verification
    ```bash
    git add documentation/phase2-verification.md
    git commit -m "docs: complete Phase 2 verification"
    claude todo complete "Phase 2: Authentication & Projects"
    ```

### Phase 3: Chat Interface (Tasks 42-61)
42. **Create ChatViewController** structure
    ```bash
    # Context7: Search "iOS chat UI implementation Swift"
    git add Features/Chat/ChatViewController.swift
    git commit -m "feat: create chat view controller structure"
    claude todo add "Chat interface implementation"
    ```

42. **Build message bubble** components
    ```bash
    # Context7: Search "iOS message bubble UI design"
    git add Features/Chat/Components/MessageBubble.swift
    git commit -m "feat: implement message bubble components"
    ```

43. **Implement streaming response** UI updates
    ```bash
    # Context7: Search "iOS streaming text animation"
    git add Features/Chat/StreamingTextView.swift
    git commit -m "feat: add streaming response UI handler"
    claude todo add "Streaming response implementation"
    ```

44. **Create typing indicator** animation
    ```bash
    git add Features/Chat/Components/TypingIndicator.swift
    git commit -m "feat: add animated typing indicator"
    ```

45. **Build message input** toolbar
    ```bash
    # Context7: Search "iOS keyboard input accessory view"
    git add Features/Chat/MessageInputToolbar.swift
    git commit -m "feat: create message input toolbar"
    ```

46. **Implement file attachment** UI
    ```bash
    # Context7: Search "iOS document picker integration"
    git add Features/Chat/FileAttachmentHandler.swift
    git commit -m "feat: add file attachment functionality"
    ```

47. **Add code syntax highlighting**
    ```bash
    # Context7: Search "iOS code syntax highlighting library"
    git add Features/Chat/CodeHighlighter.swift
    git commit -m "feat: implement code syntax highlighting"
    ```

48. **Create message copy** functionality
    ```bash
    git add Features/Chat/MessageActions.swift
    git commit -m "feat: add message copy and actions"
    ```

49. **Build message search** feature
    ```bash
    # Context7: Search "iOS text search implementation"
    git add Features/Chat/MessageSearchController.swift
    git commit -m "feat: implement message search"
    ```

50. **Implement conversation history** with SwiftData
    ```bash
    # Context7: Search "SwiftData query predicates"
    git add Features/Chat/ConversationHistory.swift
    git commit -m "feat: add conversation history persistence"
    claude todo complete "Streaming response implementation"
    ```

51. **Add message pagination**
    ```bash
    git add Features/Chat/MessagePagination.swift
    git commit -m "feat: implement message pagination"
    ```

52. **Create message reactions** (if applicable)
    ```bash
    git add Features/Chat/MessageReactions.swift
    git commit -m "feat: add message reaction system"
    ```

53. **Build error message** UI
    ```bash
    git add Features/Chat/ErrorMessageView.swift
    git commit -m "feat: create error message display"
    ```

54. **Implement retry mechanism**
    ```bash
    git add Features/Chat/MessageRetryHandler.swift
    git commit -m "feat: add message retry functionality"
    ```

55. **Add message timestamps**
    ```bash
    git add Features/Chat/MessageTimestamp.swift
    git commit -m "feat: implement message timestamps"
    ```

56. **Create message grouping** logic
    ```bash
    git add Features/Chat/MessageGrouping.swift
    git commit -m "feat: add message grouping algorithm"
    ```

57. **Build keyboard handling**
    ```bash
    # Context7: Search "iOS keyboard avoidance Swift"
    git add Features/Chat/KeyboardManager.swift
    git commit -m "feat: implement keyboard handling"
    ```

58. **Implement haptic feedback**
    ```bash
    # Context7: Search "iOS haptic feedback patterns"
    git add Core/Haptics/HapticManager.swift
    git commit -m "feat: add haptic feedback system"
    ```

59. **Test chat on simulator**
    ```bash
    # Screenshot chat features
    git add screenshots/chat/
    git commit -m "test: add chat feature screenshots"
    ```

60. **Verify streaming responses**
    ```bash
    git add documentation/streaming-verification.md
    git commit -m "docs: verify streaming implementation"
    claude todo complete "Chat interface implementation"
    claude todo complete "Phase 3: Chat Interface"
    ```

### Phase 4: File Explorer (Tasks 62-76)
62. **Create FileExplorerViewController**
    ```bash
    git add Features/FileExplorer/FileExplorerViewController.swift
    git commit -m "feat: create file explorer view controller"
    ```

63. **Build file tree** component
63. **Implement folder expansion** animations
64. **Create file icon** system
65. **Build file preview** functionality
66. **Implement syntax highlighting** for code files
67. **Add file search** capability
68. **Create file operations** menu
69. **Build file upload** UI
70. **Implement file download**
71. **Add file sharing** options
72. **Create file version** history
73. **Build diff viewer**
74. **Test file operations**
75. **Screenshot file explorer**

### Phase 5: Terminal & Advanced Features (Tasks 77-91)
77. **Create TerminalViewController**
77. **Build terminal emulator** UI
78. **Implement command history**
79. **Add auto-completion**
80. **Create terminal themes**
81. **Build output formatting**
82. **Implement ANSI color** support
83. **Add terminal gestures**
84. **Create settings screen**
85. **Build preferences** management
86. **Implement app shortcuts**
87. **Add 3D Touch/Haptic** Touch menus
88. **Create widget extension**
89. **Build Siri shortcuts**
90. **Test all features**

### Phase 6: Polish & Optimization (Tasks 92-110+)
92. **Implement Claude Code design system** polish
    ```bash
    # Ensure all screens match design system exactly
    # Verify cyan color (#00D9FF) is used consistently
    # Check all gradient blocks are correct
    # Validate grid backgrounds on all screens
    git add Design/
    git commit -m "feat: polish UI with Claude Code design system"
    ```

92. **Add glow effects** to interactive elements
    ```bash
    # Cyan glow on buttons and active elements
    # Shadow effects on gradient blocks
    # Animated glows for loading states
    git add Design/Effects/GlowEffects.swift
    git commit -m "feat: add Claude Code glow effects"
    ```

93. **Optimize WebSocket** reconnection
    ```bash
    git add Core/Network/WebSocketReconnection.swift
    git commit -m "fix: improve WebSocket reconnection logic"
    ```
94. **Create crash reporting**
95. **Build analytics integration**
96. **Implement A/B testing** framework
97. **Add accessibility** features
98. **Create onboarding** flow
99. **Build app tour**
100. **Implement feedback** system
101. **Add export/import** settings
102. **Create backup** functionality
103. **Final testing** on all simulators
104. **Performance profiling**
105. **Memory leak** detection
106. **Battery usage** optimization
107. **Network efficiency** testing
108. **Security audit**
109. **Accessibility audit**
110. **Final screenshot** collection

## 9. Development Process & MCP Integration

### 9.1 Sequential Thinking MCP Usage
**For EVERY development task:**
1. Break down the task into subtasks using Sequential Thinking MCP
2. Identify dependencies and order of implementation
3. Document the reasoning in Memory MCP
4. Create a checklist for verification

Example:
```
Sequential Thinking: "Implement WebSocket Connection"
1. Research URLSessionWebSocketTask API (Context7)
2. Design WebSocketManager protocol
3. Implement connection establishment
4. Add reconnection logic
5. Handle message sending/receiving
6. Implement error handling
7. Add connection state management
8. Create unit tests
9. Test with actual backend
10. Document usage
```

### 9.2 Context7 MCP Integration
**Before implementing any feature:**
```bash
# Example Context7 queries for each component
context7 search "URLSessionWebSocketTask Swift example"
context7 search "SwiftData relationship management"
context7 search "iOS cyberpunk UI animation"
context7 search "Swift streaming JSON parser"
```

### 9.3 Memory MCP Usage
**Store these key decisions:**
- Architecture choices and rationale
- API design decisions
- Performance optimization strategies
- Security implementation details
- UI/UX decisions
- Third-party library selections

### 9.4 Development Workflow
1. **Start task** → Update Claude todo
2. **Use Sequential Thinking** → Break down task
3. **Use Context7** → Research latest docs
4. **Implement** → Follow best practices
5. **Test** → On iPhone 16 Pro Max simulator
6. **Commit** → With descriptive message
7. **Update Memory** → Store key decisions
8. **Complete todo** → Mark task done

## 10. Testing Protocol

### 9.1 Simulator Configuration
```bash
# iPhone 16 Pro Max Simulator Setup
xcrun simctl create "iPhone 16 Pro Max Test" \
  "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max" \
  "com.apple.CoreSimulator.SimRuntime.iOS-17-0"

# Launch simulator
open -a Simulator
xcrun simctl boot "iPhone 16 Pro Max Test"

# Install app
xcrun simctl install "iPhone 16 Pro Max Test" \
  "DerivedData/Build/Products/Debug-iphonesimulator/ClaudeCodeUI.app"
```

### 9.2 Testing Checklist
- [ ] App launches without crashes
- [ ] WebSocket connects successfully
- [ ] Projects load and display correctly
- [ ] Chat streaming works smoothly
- [ ] File operations complete successfully
- [ ] Terminal commands execute properly
- [ ] Theme applies consistently
- [ ] Animations run at 60fps
- [ ] Memory usage stays under 200MB
- [ ] No memory leaks detected
- [ ] SwiftData persistence works correctly
- [ ] Offline mode functions properly

### 9.3 Screenshot Requirements
Each major feature must be documented with screenshots:
1. Launch screen animation (record video)
2. Projects dashboard (empty and populated states)
3. Active chat session with streaming
4. Code syntax highlighting in chat
5. File explorer with folder structure
6. Terminal in active use
7. Settings screen with all options
8. Error states and recovery
9. Loading states and skeletons
10. Success confirmations
11. App in landscape mode
12. Dark mode variations

### 9.4 Screenshot Capture Process
```bash
# Capture screenshot
xcrun simctl io booted screenshot screenshot_name.png

# Record video
xcrun simctl io booted recordVideo feature_demo.mov

# Organize screenshots
mkdir -p screenshots/{launch,projects,chat,files,terminal,settings}
git add screenshots/
git commit -m "docs: add feature screenshots"
```

### 9.5 Performance Testing
```swift
// Add performance tracking
import os.signpost

let log = OSLog(subsystem: "com.claudecodeui.ios", category: "Performance")
let signpostID = OSSignpostID(log: log)

os_signpost(.begin, log: log, name: "WebSocket Connection", signpostID: signpostID)
// ... connection code ...
os_signpost(.end, log: log, name: "WebSocket Connection", signpostID: signpostID)
```

## 11. Documentation Requirements

### 10.1 Context7 Documentation Research
**Use Context7 MCP to research these before starting:**

#### Swift & iOS Development
- SwiftData framework documentation (iOS 17+)
- URLSessionWebSocketTask implementation guide
- Swift Observation framework
- iOS 17 Human Interface Guidelines
- Swift async/await patterns
- Swift Structured Concurrency

#### WebSocket & Networking
- WebSocket protocol RFC 6455
- URLSession advanced configuration
- Streaming JSON parsing techniques
- Network error handling best practices
- Certificate pinning implementation

#### UI/UX Libraries
- SwiftUI animation techniques
- UIKit performance optimization
- Compositional Layout patterns
- Custom tab bar implementations
- Cyberpunk UI design principles

#### Third-Party Libraries
- Swift Package Manager integration
- Popular Swift networking libraries
- Syntax highlighting libraries for iOS
- Terminal emulator implementations

### 10.2 Research Links
- [Claude Code CLI Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Swift WebSocket Implementation](https://developer.apple.com/documentation/foundation/urlsessionwebsockettask)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Cyberpunk UI Design Principles](https://www.behance.net/search/projects/?search=cyberpunk%20ui)
- [Streaming JSON Parsing](https://github.com/apple/swift-nio)

### 10.3 MCP Server Research
- Research all available MCP servers for iOS development
- Document Swift-specific MCP integrations
- Identify performance optimization MCPs
- Find UI/UX testing MCPs
- Locate security analysis MCPs

## 12. Git Workflow

### 11.1 Branch Strategy
```
main
├── develop
│   └── feature/ios-claude-code-ui (current working branch)
│       ├── feature/foundation
│       ├── feature/authentication
│       ├── feature/projects
│       ├── feature/chat
│       ├── feature/file-explorer
│       └── feature/terminal
└── release/1.0
```

### 11.2 Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>

Types: feat, fix, docs, style, refactor, test, chore
```

### 11.3 Git Workflow Commands
```bash
# Start each task
git status
git pull origin feature/ios-claude-code-ui

# After completing a task
git add <specific files>
git commit -m "type(scope): descriptive message"

# Regular pushes (every 5-10 commits)
git push origin feature/ios-claude-code-ui

# Create sub-feature branches for major components
git checkout -b feature/ios-claude-code-ui/chat-interface

# Merge back to main feature branch
git checkout feature/ios-claude-code-ui
git merge feature/ios-claude-code-ui/chat-interface
```

### 11.4 Commit Best Practices
- Commit after each completed task
- Include relevant files only (no .DS_Store, etc.)
- Write clear, descriptive commit messages
- Reference Claude todo items in commits
- Push regularly to avoid losing work
- Tag significant milestones

## 13. Performance Benchmarks

### 13.1 Target Metrics
- App launch: < 2 seconds
- WebSocket connection: < 500ms
- Message streaming latency: < 100ms
- UI response time: < 16ms (60fps)
- Memory footprint: < 200MB
- Battery drain: < 5% per hour active use

### 13.2 Optimization Strategies
- Implement lazy loading for projects
- Use NSCache for image caching
- Optimize WebSocket message batching
- Implement virtual scrolling for long lists
- Use Metal for complex animations
- Profile and eliminate retain cycles

## 14. Security Considerations

### 14.1 Implementation Requirements
- All API keys in Keychain
- Certificate pinning for API calls
- WebSocket encryption (WSS)
- Local data encryption
- Biometric authentication
- Session timeout handling
- Secure file storage

### 14.2 Privacy Features
- No analytics without consent
- Local data stays local
- Clear data export options
- GDPR compliance
- App Transport Security enabled

## 15. Deployment Preparation

### 15.1 App Store Assets
- App icon (1024x1024)
- Screenshot sets for all devices
- App preview video
- Detailed description
- Keywords optimization
- Privacy policy URL
- Support URL

### 15.2 TestFlight Setup
- Internal testing group
- External beta testers
- Feedback collection
- Crash report monitoring
- Performance tracking

## 16. Docker Development Commands

### 16.1 Essential Docker Commands for iOS Development
```bash
# Start development environment
./run-ios-docker.sh

# Build the iOS app
./build-in-docker.sh

# Run tests in Docker
docker exec claude-code-ui-ios-dev xcodebuild test \
  -project ClaudeCodeUI.xcodeproj \
  -scheme ClaudeCodeUI \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max,OS=17.0"

# Access Docker container shell
docker exec -it claude-code-ui-ios-dev bash

# View simulator via VNC
# Use any VNC client to connect to localhost:5900
# TigerVNC, RealVNC, or TightVNC recommended

# Copy files from container
docker cp claude-code-ui-ios-dev:/workspace/ClaudeCodeUI-iOS/build ./build

# View container logs
docker logs claude-code-ui-ios-dev

# Stop containers
docker-compose down
```

### 16.2 Docker-Specific Considerations
1. **File Editing**: Edit Swift files on your Linux host, they're mounted in the container
2. **Building**: Always build inside the container using Docker exec commands
3. **Simulator Viewing**: Use VNC client to see the iOS Simulator running in Docker
4. **Performance**: Docker adds overhead, expect slower build times
5. **Debugging**: Use Docker logs and exec for debugging build issues

### 16.4 Docker Performance Optimization
```bash
# Allocate more resources to Docker
# Edit Docker daemon settings to increase CPU and memory

# For better performance, use these Docker run options:
docker run -it \
  --cpus="4" \
  --memory="8g" \
  --memory-swap="16g" \
  -v /dev/kvm:/dev/kvm \
  -v /dev/net/tun:/dev/net/tun \
  --device /dev/kvm \
  --device /dev/net/tun \
  claude-code-ui-ios-dev

# Enable hardware acceleration if available
# Check if KVM is available
ls -la /dev/kvm

# If not available, install KVM
sudo apt-get install qemu-kvm libvirt-daemon-system
sudo usermod -aG kvm $USER
```

### 16.5 Best Practices for Docker iOS Development
1. **Use Volume Mounts**: Keep source code on host for faster editing
2. **Incremental Builds**: Leverage Xcode's build cache
3. **Resource Allocation**: Give Docker sufficient CPU/RAM
4. **Network Bridge**: Use host networking for better performance
5. **Build Artifacts**: Copy out important files regularly

### 16.6 CI/CD Integration
```yaml
# GitLab CI example for Linux runners with Docker
stages:
  - build
  - test
  - deploy

build-ios:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t ios-app -f Dockerfile.ios-dev .
    - docker run ios-app /usr/local/bin/build-ios.sh
    - docker cp $(docker ps -lq):/workspace/build ./build
  artifacts:
    paths:
      - build/
    expire_in: 1 week

test-ios:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker run ios-app xcodebuild test -scheme ClaudeCodeUI
```

This enhanced prompt provides a complete roadmap for building a production-ready iOS application that mirrors and enhances the claudecodeui functionality. 

### Key Workflow Enhancements:

1. **Cross-Platform Development**
   - Native Xcode on macOS
   - Docker-based development on Linux
   - Unified workflow for both environments
   - VNC access for Linux developers

2. **Git-First Development**
   - Start by creating feature branch
   - Commit after each completed task
   - Maintain clean git history
   - Use descriptive commit messages

3. **MCP-Driven Development**
   - Sequential Thinking for task breakdown
   - Context7 for real-time documentation
   - Memory for architectural decisions
   - Continuous learning and adaptation

4. **Claude Code Todo Integration**
   - Track all phases and tasks
   - Update progress in real-time
   - Maintain project visibility
   - Celebrate completed milestones

5. **SwiftData Modern Persistence**
   - Leverage iOS 17+ capabilities
   - Type-safe data modeling
   - Automatic iCloud sync support
   - Efficient query system

6. **Docker-Enabled Linux Development**
   - Full iOS development on Linux hosts
   - Containerized Xcode and simulators
   - VNC-based simulator viewing
   - Automated build scripts

7. **Continuous Testing**
   - Test on iPhone 16 Pro Max simulator
   - Document with screenshots
   - Verify performance metrics
   - No mocks - real implementation only

### Development Philosophy:
- **No placeholders** - Everything functional
- **Document everything** - Screenshots and commits
- **Test continuously** - Simulator verification
- **Cross-platform** - Works on macOS and Linux
- **Use latest tech** - SwiftData, Observation, iOS 17+
- **Maintain quality** - SwiftLint, performance monitoring
- **Follow design system** - Claude Code exact colors, typography, and components
- **Consistent aesthetics** - Cyan primary (#00D9FF), dark backgrounds, grid patterns

### Claude Code Design System Summary:
- **Colors**: Cyan (#00D9FF), Pink (#FF006E), Blue-Purple gradients
- **Typography**: Dynamic type with Title, Body, Caption hierarchy
- **Icons**: Comprehensive SF Symbols mapped to design system
- **Components**: Gradient blocks, neon buttons, grid backgrounds
- **Effects**: Glow on interactive elements, subtle animations
- **Layout**: Dark surfaces with cyan accents, consistent spacing

### Docker Workflow Summary (Linux):
1. Clone repos and set up directories
2. Run `./run-ios-docker.sh` to start environment
3. Connect VNC client to localhost:5900
4. Edit code on host, build in container
5. Use Docker exec for all Xcode commands
6. Test in containerized simulator

### Native Workflow Summary (macOS):
1. Clone repos and set up directories
2. Open project in Xcode
3. Build and run normally
4. Use native simulator
5. Standard iOS development workflow

Remember to leverage MCP servers throughout development, maintain comprehensive git history, and document all architectural decisions in the memory MCP for future reference.

The Claude Code design system should be implemented exactly as specified, with cyan (#00D9FF) as the primary color, dark backgrounds (#0A0A0F), grid patterns, and gradient blocks throughout. This creates a visually distinctive and functionally robust application that enhances the Claude Code experience on iOS devices, regardless of your development platform.