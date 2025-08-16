//
//  MCPServerListView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import SwiftUI

struct MCPServerListView: View {
    @StateObject private var viewModel = MCPServerViewModel()
    @State private var showingAddServer = false
    @State private var selectedServer: MCPServer?
    @State private var searchText = ""
    
    var filteredServers: [MCPServer] {
        if searchText.isEmpty {
            return viewModel.servers
        } else {
            return viewModel.servers.filter { server in
                server.name.localizedCaseInsensitiveContains(searchText) ||
                server.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Cyberpunk background
            LinearGradient(
                colors: [
                    Color(UIColor(hex: "#0A0A0F")!),
                    Color(UIColor(hex: "#1A1A2E")!)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search bar
                searchBar
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // Server list or empty state
                if viewModel.isLoading {
                    loadingView
                } else if filteredServers.isEmpty {
                    emptyStateView
                } else {
                    serverList
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddServer) {
            AddMCPServerView(viewModel: viewModel)
        }
        .sheet(item: $selectedServer) { server in
            MCPServerDetailView(server: server, viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadServers()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MCP Servers")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textPrimary))
                
                Text("\(viewModel.servers.count) servers configured")
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary))
            }
            
            Spacer()
            
            Button(action: { showingAddServer = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.primaryCyan))
                    .shadow(color: Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.6), radius: 4)
            }
        }
        .padding()
        .background(
            Color(UIColor.CyberpunkTheme.surface)
                .opacity(0.3)
        )
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary))
            
            TextField("Search servers...", text: $searchText)
                .foregroundColor(Color(UIColor.CyberpunkTheme.textPrimary))
                .accentColor(Color(UIColor.CyberpunkTheme.primaryCyan))
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.CyberpunkTheme.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var serverList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredServers) { server in
                    MCPServerRow(server: server) {
                        selectedServer = server
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor.CyberpunkTheme.primaryCyan)))
                .scaleEffect(1.5)
            
            Text("Loading servers...")
                .font(.system(size: 16))
                .foregroundColor(Color(UIColor.CyberpunkTheme.textSecondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "server.rack")
                .font(.system(size: 64))
                .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary))
            
            VStack(spacing: 8) {
                Text("No MCP Servers")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textPrimary))
                
                Text("Add your first MCP server to get started")
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textSecondary))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddServer = true }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Server")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(UIColor.CyberpunkTheme.primaryCyan),
                            Color(UIColor.CyberpunkTheme.gradientBlue)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.4), radius: 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct MCPServerRow: View {
    let server: MCPServer
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Status indicator
                Circle()
                    .fill(server.isConnected ? Color(UIColor.CyberpunkTheme.success) : Color(UIColor.CyberpunkTheme.textTertiary))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(server.isConnected ? Color(UIColor.CyberpunkTheme.success) : Color.clear, lineWidth: 2)
                            .frame(width: 16, height: 16)
                            .opacity(server.isConnected ? 0.5 : 0)
                    )
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: server.isConnected)
                
                // Server info
                VStack(alignment: .leading, spacing: 4) {
                    Text(server.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.CyberpunkTheme.textPrimary))
                    
                    Text(server.description)
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.CyberpunkTheme.textSecondary))
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label(server.type.rawValue, systemImage: server.type.icon)
                            .font(.system(size: 11))
                            .foregroundColor(Color(UIColor.CyberpunkTheme.primaryCyan))
                        
                        if server.isDefault {
                            Label("Default", systemImage: "star.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(UIColor.CyberpunkTheme.warning))
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textTertiary))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.CyberpunkTheme.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                server.isConnected ? 
                                Color(UIColor.CyberpunkTheme.primaryCyan).opacity(0.3) :
                                Color(UIColor.CyberpunkTheme.border),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Add Server View
struct AddMCPServerView: View {
    @ObservedObject var viewModel: MCPServerViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var url = ""
    @State private var description = ""
    @State private var selectedType = MCPServerType.rest
    @State private var apiKey = ""
    @State private var isDefault = false
    
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
                    VStack(spacing: 20) {
                        // Form fields
                        formField(title: "Server Name", text: $name, placeholder: "My MCP Server")
                        formField(title: "URL", text: $url, placeholder: "https://api.example.com")
                        formField(title: "Description", text: $description, placeholder: "Optional description")
                        
                        // Server type picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Server Type")
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor.CyberpunkTheme.textSecondary))
                            
                            Picker("Type", selection: $selectedType) {
                                ForEach(MCPServerType.allCases, id: \.self) { type in
                                    Label(type.rawValue, systemImage: type.icon)
                                        .tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        formField(title: "API Key (Optional)", text: $apiKey, placeholder: "Your API key", isSecure: true)
                        
                        Toggle(isOn: $isDefault) {
                            Text("Set as default server")
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor.CyberpunkTheme.textPrimary))
                        }
                        .tint(Color(UIColor.CyberpunkTheme.primaryCyan))
                    }
                    .padding()
                }
            }
            .navigationTitle("Add MCP Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(UIColor.CyberpunkTheme.textSecondary))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let server = MCPServer(
                            id: UUID().uuidString,
                            name: name,
                            url: url,
                            description: description,
                            type: selectedType,
                            apiKey: apiKey.isEmpty ? nil : apiKey,
                            isDefault: isDefault,
                            isConnected: false
                        )
                        viewModel.addServer(server)
                        dismiss()
                    }
                    .foregroundColor(Color(UIColor.CyberpunkTheme.primaryCyan))
                    .disabled(name.isEmpty || url.isEmpty)
                }
            }
        }
    }
    
    private func formField(title: String, text: Binding<String>, placeholder: String, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color(UIColor.CyberpunkTheme.textSecondary))
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.CyberpunkTheme.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(UIColor.CyberpunkTheme.border), lineWidth: 1)
                    )
            )
            .foregroundColor(Color(UIColor.CyberpunkTheme.textPrimary))
            .accentColor(Color(UIColor.CyberpunkTheme.primaryCyan))
        }
    }
}