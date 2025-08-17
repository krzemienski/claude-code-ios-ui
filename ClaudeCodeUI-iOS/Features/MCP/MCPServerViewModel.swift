//
//  MCPServerViewModel.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import Foundation
import SwiftUI
import Combine

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
                // Load from backend API
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
    
    func updateServerAsync(_ server: MCPServer) async throws {
        // First update locally
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            // If this is set as default, unset other defaults
            if server.isDefault && !servers[index].isDefault {
                for i in servers.indices where i != index {
                    servers[i].isDefault = false
                }
            }
            
            servers[index] = server
            saveServersToStorage()
        }
        
        // Then update on backend (will throw if fails)
        let updatedServer = try await APIClient.shared.updateMCPServer(server)
        
        // Update local server with response
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = updatedServer
            saveServersToStorage()
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
        do {
            // Test the connection using the API
            let result = try await APIClient.shared.testMCPServer(id: server.id)
            
            // Update the server's connection status
            if let index = servers.firstIndex(where: { $0.id == server.id }) {
                servers[index].isConnected = result.success
                servers[index].lastConnected = result.success ? Date() : servers[index].lastConnected
                saveServersToStorage()
            }
            
            return result
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
    
    // MARK: - API Methods
    
    private func loadServersFromAPI() async {
        do {
            // Load servers from the backend API
            let apiServers = try await APIClient.shared.getMCPServers()
            self.servers = apiServers
            saveServersToStorage() // Cache locally
        } catch {
            // If API fails, error is already handled in calling method
            print("Failed to load MCP servers from API: \(error)")
        }
    }
    
    private func saveServerToAPI(_ server: MCPServer) async {
        do {
            let savedServer = try await APIClient.shared.addMCPServer(server)
            // Update local server with any backend-generated fields
            if let index = servers.firstIndex(where: { $0.id == server.id }) {
                servers[index] = savedServer
                saveServersToStorage()
            }
        } catch {
            errorMessage = "Failed to save server: \(error.localizedDescription)"
        }
    }
    
    private func updateServerOnAPI(_ server: MCPServer) async {
        do {
            let updatedServer = try await APIClient.shared.updateMCPServer(server)
            // Update local server with response
            if let index = servers.firstIndex(where: { $0.id == server.id }) {
                servers[index] = updatedServer
                saveServersToStorage()
            }
        } catch {
            errorMessage = "Failed to update server: \(error.localizedDescription)"
        }
    }
    
    private func deleteServerFromAPI(_ server: MCPServer) async {
        do {
            try await APIClient.shared.deleteMCPServer(id: server.id)
        } catch {
            errorMessage = "Failed to delete server: \(error.localizedDescription)"
        }
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