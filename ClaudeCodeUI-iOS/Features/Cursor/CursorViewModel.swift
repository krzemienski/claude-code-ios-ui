//
//  CursorViewModel.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import Foundation
import Combine

// MARK: - Cursor ViewModel
@MainActor
final class CursorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var config: CursorConfig?
    @Published var mcpServers: [CursorMCPServer] = []
    @Published var sessions: [CursorSession] = []
    @Published var selectedSession: CursorSession?
    @Published var settings: CursorSettings?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Search and filter
    @Published var searchText = ""
    @Published var showOnlyEnabledServers = false
    
    // MARK: - Computed Properties
    var filteredMCPServers: [CursorMCPServer] {
        var filtered = mcpServers
        
        if showOnlyEnabledServers {
            filtered = filtered.filter { $0.enabled }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { server in
                server.name.localizedCaseInsensitiveContains(searchText) ||
                server.command.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var filteredSessions: [CursorSession] {
        guard !searchText.isEmpty else { return sessions }
        
        return sessions.filter { session in
            // Use name instead of title, and search in name/projectPath
            (session.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (session.projectPath?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var totalTokenCount: Int {
        sessions.compactMap { $0.metadata?.totalTokens }.reduce(0, +)
    }
    
    var estimatedCost: Double {
        sessions.compactMap { $0.metadata?.cost }.reduce(0, +)
    }
    
    // MARK: - Private Properties
    private let service = CursorService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Auto-clear messages after delay
        $successMessage
            .compactMap { $0 }
            .delay(for: .seconds(3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.successMessage = nil
            }
            .store(in: &cancellables)
        
        $errorMessage
            .compactMap { $0 }
            .delay(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.errorMessage = nil
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Configuration Methods
    func loadConfiguration() async {
        isLoading = true
        errorMessage = nil
        
        do {
            config = try await service.getConfiguration()
            successMessage = "Configuration loaded successfully"
        } catch {
            errorMessage = "Failed to load configuration: \(error.localizedDescription)"
            print("❌ Error loading Cursor config: \(error)")
        }
        
        isLoading = false
    }
    
    func updateConfiguration(_ newConfig: CursorConfig) async {
        isLoading = true
        errorMessage = nil
        
        do {
            config = try await service.updateConfiguration(newConfig)
            successMessage = "Configuration updated successfully"
        } catch {
            errorMessage = "Failed to update configuration: \(error.localizedDescription)"
            print("❌ Error updating Cursor config: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - MCP Server Methods
    func loadMCPServers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            mcpServers = try await service.getMCPServers()
            successMessage = "Loaded \(mcpServers.count) MCP servers"
        } catch {
            errorMessage = "Failed to load MCP servers: \(error.localizedDescription)"
            print("❌ Error loading MCP servers: \(error)")
        }
        
        isLoading = false
    }
    
    func addMCPServer(name: String, command: String, args: [String]? = nil, env: [String: String]? = nil) async {
        isLoading = true
        errorMessage = nil
        
        let serverConfig = CursorMCPServerConfig(
            name: name,
            command: command,
            args: args,
            env: env
        )
        
        do {
            let newServer = try await service.addMCPServer(serverConfig)
            mcpServers.append(newServer)
            successMessage = "Added MCP server: \(name)"
        } catch {
            errorMessage = "Failed to add MCP server: \(error.localizedDescription)"
            print("❌ Error adding MCP server: \(error)")
        }
        
        isLoading = false
    }
    
    func removeMCPServer(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.removeMCPServer(id: id)
            mcpServers.removeAll { $0.id == id }
            successMessage = "Removed MCP server"
        } catch {
            errorMessage = "Failed to remove MCP server: \(error.localizedDescription)"
            print("❌ Error removing MCP server: \(error)")
        }
        
        isLoading = false
    }
    
    func toggleMCPServer(_ server: CursorMCPServer) {
        if let index = mcpServers.firstIndex(where: { $0.id == server.id }) {
            mcpServers[index].enabled.toggle()
            
            // Optionally save the change
            Task {
                await saveMCPServerChanges()
            }
        }
    }
    
    private func saveMCPServerChanges() async {
        // This would typically sync with backend
        // For now, it's handled locally through the service
    }
    
    // MARK: - Session Methods
    func loadSessions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            sessions = try await service.getSessions()
            successMessage = "Loaded \(sessions.count) sessions"
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            print("❌ Error loading sessions: \(error)")
        }
        
        isLoading = false
    }
    
    func selectSession(_ session: CursorSession) async {
        isLoading = true
        errorMessage = nil
        
        do {
            selectedSession = try await service.getSession(id: session.id)
            successMessage = "Loaded session: \(session.title)"
        } catch {
            errorMessage = "Failed to load session: \(error.localizedDescription)"
            print("❌ Error loading session: \(error)")
        }
        
        isLoading = false
    }
    
    func restoreSession(_ session: CursorSession) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let restoredSession = try await service.restoreSession(id: session.id)
            selectedSession = restoredSession
            successMessage = "Restored session: \(session.title)"
        } catch {
            errorMessage = "Failed to restore session: \(error.localizedDescription)"
            print("❌ Error restoring session: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Settings Methods
    func loadSettings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            settings = try await service.getSettings()
            successMessage = "Settings loaded successfully"
        } catch {
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
            print("❌ Error loading settings: \(error)")
        }
        
        isLoading = false
    }
    
    func updateSettings(_ newSettings: CursorSettings) async {
        isLoading = true
        errorMessage = nil
        
        do {
            settings = try await service.updateSettings(newSettings)
            successMessage = "Settings updated successfully"
        } catch {
            errorMessage = "Failed to update settings: \(error.localizedDescription)"
            print("❌ Error updating settings: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Initial Load
    func loadAllData() async {
        await loadConfiguration()
        await loadMCPServers()
        await loadSessions()
        await loadSettings()
    }
    
    // MARK: - Refresh
    func refresh() async {
        searchText = ""
        showOnlyEnabledServers = false
        await loadAllData()
    }
}