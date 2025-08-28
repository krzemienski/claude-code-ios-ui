//
//  MCPServerDetailView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import SwiftUI

struct MCPServerDetailView: View {
    let server: MCPServer
    @ObservedObject var viewModel: MCPServerViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var testingConnection = false
    @State private var connectionTestResult: ConnectionTestResult?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    // Editing states
    @State private var editedName: String
    @State private var editedUrl: String
    @State private var editedDescription: String
    @State private var editedApiKey: String
    @State private var editedIsDefault: Bool
    
    // Helper computed properties to simplify complex views
    private var statusGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(server.isConnected ? CyberpunkTheme.success : CyberpunkTheme.textTertiary),
                Color(server.isConnected ? CyberpunkTheme.success : CyberpunkTheme.textTertiary).opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var statusIconName: String {
        server.isConnected ? "checkmark.circle" : "xmark.circle"
    }
    
    private var statusOverlayColor: Color {
        server.isConnected ? Color(CyberpunkTheme.success) : Color.clear
    }
    
    init(server: MCPServer, viewModel: MCPServerViewModel) {
        self.server = server
        self.viewModel = viewModel
        
        // Initialize editing states
        _editedName = State(initialValue: server.name)
        _editedUrl = State(initialValue: server.url)
        _editedDescription = State(initialValue: server.description)
        _editedApiKey = State(initialValue: server.apiKey ?? "")
        _editedIsDefault = State(initialValue: server.isDefault)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(UIColor(hex: "#0A0A0F")!),
                        Color(UIColor(hex: "#1A1A2E")!)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Server Status Card
                        statusCard
                        
                        // Connection Test
                        connectionTestSection
                        
                        // Server Details
                        if isEditing {
                            editableDetailsSection
                        } else {
                            readOnlyDetailsSection
                        }
                        
                        // Configuration
                        configurationSection
                        
                        // Actions
                        actionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle(server.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(CyberpunkTheme.textSecondary))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(CyberpunkTheme.primaryCyan)))
                                .scaleEffect(0.8)
                        } else {
                            Button("Save") {
                                saveChanges()
                            }
                            .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                        }
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    }
                }
            }
            .alert("Delete Server", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteServer(server)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this MCP server? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var statusCard: some View {
        VStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusGradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: statusIconName)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            .overlay(
                Circle()
                    .stroke(statusOverlayColor, lineWidth: 2)
                    .frame(width: 90, height: 90)
                    .opacity(server.isConnected ? 0.5 : 0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: server.isConnected)
            )
            
            VStack(spacing: 4) {
                Text(server.isConnected ? "Connected" : "Disconnected")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(CyberpunkTheme.textPrimary))
                
                Text(server.type.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textSecondary))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(CyberpunkTheme.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            server.isConnected ?
                            Color(CyberpunkTheme.success).opacity(0.3) :
                            Color(CyberpunkTheme.border),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private var connectionTestSection: some View {
        VStack(spacing: 12) {
            Button(action: testConnection) {
                HStack {
                    if testingConnection {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "network")
                    }
                    
                    Text(testingConnection ? "Testing..." : "Test Connection")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(CyberpunkTheme.primaryCyan),
                            Color(CyberpunkTheme.gradientBlue)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(testingConnection)
            }
            
            if let result = connectionTestResult {
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.success ? Color(CyberpunkTheme.success) : Color(CyberpunkTheme.error))
                    
                    Text(result.message)
                        .font(.system(size: 12))
                        .foregroundColor(Color(CyberpunkTheme.textSecondary))
                    
                    Spacer()
                    
                    if let latency = result.latency {
                        Text("\(Int(latency))ms")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(CyberpunkTheme.surface).opacity(0.5))
                )
            }
        }
    }
    
    private var readOnlyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            detailRow(label: "Name", value: server.name)
            detailRow(label: "URL", value: server.url)
            detailRow(label: "Description", value: server.description.isEmpty ? "No description" : server.description)
            detailRow(label: "API Key", value: server.apiKey != nil ? "••••••••" : "Not configured")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(CyberpunkTheme.surface))
        )
    }
    
    private var editableDetailsSection: some View {
        VStack(spacing: 16) {
            editableField(label: "Name", text: $editedName)
            editableField(label: "URL", text: $editedUrl)
            editableField(label: "Description", text: $editedDescription)
            editableField(label: "API Key", text: $editedApiKey, isSecure: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(CyberpunkTheme.surface))
        )
    }
    
    private var configurationSection: some View {
        VStack(spacing: 12) {
            Toggle(isOn: isEditing ? $editedIsDefault : .constant(server.isDefault)) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color(CyberpunkTheme.warning))
                    Text("Default Server")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.textPrimary))
                }
            }
            .tint(Color(CyberpunkTheme.primaryCyan))
            .disabled(!isEditing)
            
            Divider()
                .background(Color(CyberpunkTheme.border))
            
            HStack {
                Text("Auto-connect")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textSecondary))
                
                Spacer()
                
                Text("Enabled")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.primaryCyan))
            }
            
            HStack {
                Text("Last Connected")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textSecondary))
                
                Spacer()
                
                Text("2 hours ago")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textTertiary))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(CyberpunkTheme.surface))
        )
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if isEditing {
                Button(action: { isEditing = false }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(CyberpunkTheme.textTertiary), lineWidth: 1)
                        )
                        .foregroundColor(Color(CyberpunkTheme.textSecondary))
                }
            }
            
            Button(action: { showingDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Server")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Color(CyberpunkTheme.error).opacity(0.2)
                )
                .foregroundColor(Color(CyberpunkTheme.error))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(CyberpunkTheme.error).opacity(0.5), lineWidth: 1)
                )
            }
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(CyberpunkTheme.textTertiary))
            
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(Color(CyberpunkTheme.textPrimary))
        }
    }
    
    private func editableField(label: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(CyberpunkTheme.textTertiary))
            
            Group {
                if isSecure {
                    SecureField("Enter \(label.lowercased())", text: text)
                } else {
                    TextField("Enter \(label.lowercased())", text: text)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(CyberpunkTheme.background))
            )
            .foregroundColor(Color(CyberpunkTheme.textPrimary))
            .accentColor(Color(CyberpunkTheme.primaryCyan))
        }
    }
    
    private func testConnection() {
        testingConnection = true
        connectionTestResult = nil
        
        Task {
            let result = await viewModel.testConnection(for: server)
            await MainActor.run {
                testingConnection = false
                connectionTestResult = result
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        var updatedServer = server
        updatedServer.name = editedName
        updatedServer.url = editedUrl
        updatedServer.description = editedDescription
        updatedServer.apiKey = editedApiKey.isEmpty ? nil : editedApiKey
        updatedServer.isDefault = editedIsDefault
        
        Task {
            do {
                // Use async method to update server
                try await viewModel.updateServerAsync(updatedServer)
                await MainActor.run {
                    isSaving = false
                    isEditing = false
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save server: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
}

// ConnectionTestResult moved to MCPServerViewModel.swift