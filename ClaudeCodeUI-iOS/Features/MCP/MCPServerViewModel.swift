//
//  MCPServerViewModel.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import Foundation
import SwiftUI
import Combine

// MARK: - MCP Server Model
struct MCPServer: Identifiable, Codable {
    let id: String
    var name: String
    var url: String
    var description: String
    var type: MCPServerType
    var apiKey: String?
    var isDefault: Bool
    var isConnected: Bool
    var lastConnected: Date?
    var configuration: [String: String]?
}

enum MCPServerType: String, CaseIterable, Codable {
    case rest = "REST API"
    case graphql = "GraphQL"
    case websocket = "WebSocket"
    case grpc = "gRPC"
    
    var icon: String {
        switch self {
        case .rest: return "cloud"
        case .graphql: return "hexagon"
        case .websocket: return "bolt"
        case .grpc: return "cpu"
        }
    }
}

// MARK: - View Model
@MainActor
class MCPServerViewModel: ObservableObject {
    @Published var servers: [MCPServer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let serversKey = "mcpServers"
    
    init() {
        loadServersFromStorage()
    }
    
    // MARK: - Public Methods
    
    func loadServers() {
        isLoading = true
        
        Task {
            do {
                // In production, this would call the API
                // For now, we'll use mock data and local storage
                try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
                
                // Try to load from backend API
                await loadServersFromAPI()
                
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
                
                // Fall back to local storage
                loadServersFromStorage()
            }
        }
    }
    
    func addServer(_ server: MCPServer) {
        // If this is set as default, unset other defaults
        if server.isDefault {
            for i in servers.indices {
                servers[i].isDefault = false
            }
        }
        
        servers.append(server)
        saveServersToStorage()
        
        // In production, also save to backend
        Task {
            await saveServerToAPI(server)
        }
    }
    
    func updateServer(_ server: MCPServer) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            // If this is set as default, unset other defaults
            if server.isDefault && !servers[index].isDefault {
                for i in servers.indices where i != index {
                    servers[i].isDefault = false
                }
            }
            
            servers[index] = server
            saveServersToStorage()
            
            // In production, also update on backend
            Task {
                await updateServerOnAPI(server)
            }
        }
    }
    
    func deleteServer(_ server: MCPServer) {
        servers.removeAll { $0.id == server.id }
        saveServersToStorage()
        
        // In production, also delete from backend
        Task {
            await deleteServerFromAPI(server)
        }
    }
    
    func testConnection(for server: MCPServer) async -> ConnectionTestResult {
        // Simulate connection test
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // In production, actually test the connection
            let success = Bool.random()
            let latency = Double.random(in: 20...200)
            
            return ConnectionTestResult(
                success: success,
                message: success ? "Connection successful" : "Connection failed",
                latency: success ? latency : nil
            )
        } catch {
            return ConnectionTestResult(
                success: false,
                message: "Test failed: \(error.localizedDescription)",
                latency: nil
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func loadServersFromStorage() {
        if let data = userDefaults.data(forKey: serversKey),
           let decoded = try? JSONDecoder().decode([MCPServer].self, from: data) {
            self.servers = decoded
        } else {
            // Load default servers if none exist
            loadDefaultServers()
        }
    }
    
    private func saveServersToStorage() {
        if let encoded = try? JSONEncoder().encode(servers) {
            userDefaults.set(encoded, forKey: serversKey)
        }
    }
    
    private func loadDefaultServers() {
        servers = [
            MCPServer(
                id: UUID().uuidString,
                name: "Claude MCP",
                url: "https://api.anthropic.com/mcp",
                description: "Official Claude Model Context Protocol server",
                type: .rest,
                apiKey: nil,
                isDefault: true,
                isConnected: false
            ),
            MCPServer(
                id: UUID().uuidString,
                name: "Local Development",
                url: "http://localhost:3004/mcp",
                description: "Local MCP server for development",
                type: .websocket,
                apiKey: nil,
                isDefault: false,
                isConnected: true
            ),
            MCPServer(
                id: UUID().uuidString,
                name: "GitHub Copilot",
                url: "https://api.github.com/copilot",
                description: "GitHub Copilot integration server",
                type: .graphql,
                apiKey: nil,
                isDefault: false,
                isConnected: false
            )
        ]
    }
    
    // MARK: - API Methods (Placeholder for backend integration)
    
    private func loadServersFromAPI() async {
        // In production, this would call:
        // GET /api/mcp/servers
        
        // For now, just use local storage
        // The API implementation would look like:
        /*
        do {
            let response = try await APIClient.shared.request(.getMCPServers())
            self.servers = response.servers
            saveServersToStorage() // Cache locally
        } catch {
            throw error
        }
        */
    }
    
    private func saveServerToAPI(_ server: MCPServer) async {
        // In production, this would call:
        // POST /api/mcp/servers
        
        // Implementation would look like:
        /*
        do {
            _ = try await APIClient.shared.request(.addMCPServer(server))
        } catch {
            errorMessage = "Failed to save server: \(error.localizedDescription)"
        }
        */
    }
    
    private func updateServerOnAPI(_ server: MCPServer) async {
        // In production, this would call:
        // PUT /api/mcp/servers/:id
        
        // Implementation would look like:
        /*
        do {
            _ = try await APIClient.shared.request(.updateMCPServer(server))
        } catch {
            errorMessage = "Failed to update server: \(error.localizedDescription)"
        }
        */
    }
    
    private func deleteServerFromAPI(_ server: MCPServer) async {
        // In production, this would call:
        // DELETE /api/mcp/servers/:id
        
        // Implementation would look like:
        /*
        do {
            _ = try await APIClient.shared.requestVoid(.deleteMCPServer(id: server.id))
        } catch {
            errorMessage = "Failed to delete server: \(error.localizedDescription)"
        }
        */
    }
}

// MARK: - UIKit Bridge
// Bridge for UIKit integration if needed
class MCPServerListViewController: UIViewController {
    private var hostingController: UIHostingController<MCPServerListView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SwiftUI view
        let mcpView = MCPServerListView()
        hostingController = UIHostingController(rootView: mcpView)
        
        if let hostingController = hostingController {
            addChild(hostingController)
            view.addSubview(hostingController.view)
            
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
        }
        
        // Customize navigation
        title = "MCP Servers"
        navigationItem.largeTitleDisplayMode = .automatic
    }
}