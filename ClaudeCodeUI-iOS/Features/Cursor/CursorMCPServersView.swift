//
//  CursorMCPServersView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import SwiftUI

// MARK: - Cursor MCP Servers View
struct CursorMCPServersView: View {
    @ObservedObject var viewModel: CursorViewModel
    @State private var showAddServer = false
    @State private var selectedServer: CursorMCPServer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("MCP Servers")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Manage Model Context Protocol servers for Cursor")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            
            // Search and Filter
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.white.opacity(0.5))
                    
                    TextField("Search servers...", text: $viewModel.searchText)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                
                // Filter Toggle
                HStack {
                    Toggle(isOn: $viewModel.showOnlyEnabledServers) {
                        Text("Show only enabled")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                    .toggleStyle(CyberpunkToggleStyle())
                    
                    Spacer()
                    
                    // Add Button
                    Button(action: { showAddServer = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Server")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0, green: 0.85, blue: 1), Color(red: 0, green: 0.65, blue: 0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // Servers List
            if viewModel.filteredMCPServers.isEmpty {
                EmptyStateView(
                    icon: "server.rack",
                    title: viewModel.searchText.isEmpty ? "No MCP Servers" : "No Results",
                    message: viewModel.searchText.isEmpty ? 
                        "Add your first MCP server to get started" : 
                        "No servers match your search"
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.filteredMCPServers) { server in
                            MCPServerCard(
                                server: server,
                                onTap: { selectedServer = server },
                                onToggle: { viewModel.toggleMCPServer(server) },
                                onDelete: {
                                    Task {
                                        await viewModel.removeMCPServer(id: server.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showAddServer) {
            CursorAddMCPServerView(viewModel: viewModel, isPresented: $showAddServer)
        }
        .sheet(item: $selectedServer) { server in
            CursorMCPServerDetailView(server: server, viewModel: viewModel)
        }
    }
}

// MARK: - MCP Server Card
struct MCPServerCard: View {
    let server: CursorMCPServer
    let onTap: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Status Indicator
                Circle()
                    .fill(server.enabled ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                // Server Name
                Text(server.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Enable Toggle
                Toggle("", isOn: Binding(
                    get: { server.enabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0, green: 0.85, blue: 1)))
                .scaleEffect(0.8)
            }
            
            // Command Info
            HStack {
                Image(systemName: "terminal")
                    .foregroundColor(Color.white.opacity(0.5))
                    .font(.system(size: 12))
                
                Text(server.command)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.7))
                
                if let args = server.args, !args.isEmpty {
                    Text(args.joined(separator: " "))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            
            // Last Connected
            if let lastConnected = server.lastConnected {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(Color.white.opacity(0.5))
                        .font(.system(size: 12))
                    
                    Text("Last connected: \(lastConnected, formatter: relativeDateFormatter)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onTap) {
                    Text("Details")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                }
                
                Spacer()
                
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(Color(red: 1, green: 0, blue: 0.43))
                        .font(.system(size: 14))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(server.enabled ? 
                       Color(red: 0, green: 0.85, blue: 1).opacity(0.3) : 
                       Color.white.opacity(0.1), 
                       lineWidth: 1)
        )
        .alert("Delete Server?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Are you sure you want to delete '\(server.name)'? This action cannot be undone.")
        }
    }
    
    private var relativeDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Add MCP Server View
struct CursorAddMCPServerView: View {
    @ObservedObject var viewModel: CursorViewModel
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var command = ""
    @State private var args = ""
    @State private var envVars = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Server Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.8))
                            
                            TextField("e.g., Claude Flow", text: $name)
                                .textFieldStyle(CyberpunkTextFieldStyle())
                        }
                        
                        // Command Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Command")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.8))
                            
                            TextField("e.g., npx", text: $command)
                                .textFieldStyle(CyberpunkTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        
                        // Arguments Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Arguments (space-separated)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.8))
                            
                            TextField("e.g., claude-flow@alpha mcp start", text: $args)
                                .textFieldStyle(CyberpunkTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        
                        // Environment Variables
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Environment Variables (KEY=value, one per line)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.8))
                            
                            TextEditor(text: $envVars)
                                .frame(height: 100)
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .font(.system(size: 14, design: .monospaced))
                        }
                        
                        // Example Templates
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Templates")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                            
                            HStack(spacing: 8) {
                                TemplateButton(title: "Claude Flow") {
                                    name = "Claude Flow"
                                    command = "npx"
                                    args = "claude-flow@alpha mcp start"
                                }
                                
                                TemplateButton(title: "Memory") {
                                    name = "Memory"
                                    command = "npx"
                                    args = "@modelcontextprotocol/server-memory"
                                }
                                
                                TemplateButton(title: "Filesystem") {
                                    name = "Filesystem"
                                    command = "npx"
                                    args = "@modelcontextprotocol/server-filesystem /"
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add MCP Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            let argsArray = args.isEmpty ? nil : args.components(separatedBy: " ")
                            let envDict = parseEnvironmentVariables(envVars)
                            
                            await viewModel.addMCPServer(
                                name: name,
                                command: command,
                                args: argsArray,
                                env: envDict.isEmpty ? nil : envDict
                            )
                            
                            isPresented = false
                        }
                    }
                    .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                    .disabled(name.isEmpty || command.isEmpty)
                }
            }
        }
    }
    
    private func parseEnvironmentVariables(_ text: String) -> [String: String] {
        var dict: [String: String] = [:]
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let parts = line.components(separatedBy: "=")
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                if !key.isEmpty && !value.isEmpty {
                    dict[key] = value
                }
            }
        }
        
        return dict
    }
}

// MARK: - Template Button
struct TemplateButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 0, green: 0.85, blue: 1).opacity(0.1))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0, green: 0.85, blue: 1).opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - MCP Server Detail View
struct CursorMCPServerDetailView: View {
    let server: CursorMCPServer
    @ObservedObject var viewModel: CursorViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Status
                        HStack {
                            Circle()
                                .fill(server.enabled ? Color.green : Color.gray)
                                .frame(width: 12, height: 12)
                            
                            Text(server.enabled ? "Enabled" : "Disabled")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(server.enabled ? Color.green : Color.gray)
                        }
                        
                        // Command Details
                        DetailSection(title: "Command") {
                            CodeBlock(text: server.command)
                        }
                        
                        if let args = server.args, !args.isEmpty {
                            DetailSection(title: "Arguments") {
                                CodeBlock(text: args.joined(separator: " "))
                            }
                        }
                        
                        if let env = server.env, !env.isEmpty {
                            DetailSection(title: "Environment Variables") {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(env.keys.sorted()), id: \.self) { key in
                                        HStack {
                                            Text(key)
                                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                                .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                                            
                                            Text("=")
                                                .foregroundColor(Color.white.opacity(0.5))
                                            
                                            Text(env[key] ?? "")
                                                .font(.system(size: 14, design: .monospaced))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                        
                        if let lastConnected = server.lastConnected {
                            DetailSection(title: "Last Connected") {
                                Text(lastConnected, style: .dateTime)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(server.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                }
            }
        }
    }
}

// MARK: - Detail Section
struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.8))
            
            content
        }
    }
}

// MARK: - Code Block
struct CodeBlock: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
    }
}

// MARK: - Cyberpunk Text Field Style
struct CyberpunkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(Color.white.opacity(0.08))
            .cornerRadius(8)
            .foregroundColor(.white)
            .font(.system(size: 14))
    }
}