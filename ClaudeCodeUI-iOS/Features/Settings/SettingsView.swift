//
//  SettingsView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingResetAlert = false
    @State private var exportedFileURL: URL?
    
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Appearance Settings
                    appearanceSection
                    
                    // Editor Settings
                    editorSection
                    
                    // API Configuration
                    apiSection
                    
                    // Data Management
                    dataManagementSection
                    
                    // About Section
                    aboutSection
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleImportResult(result)
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetToDefaults()
            }
        } message: {
            Text("Are you sure you want to reset all settings to their default values? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Color(CyberpunkTheme.textPrimary))
            
            Text("Customize your Claude Code experience")
                .font(.system(size: 14))
                .foregroundColor(Color(CyberpunkTheme.textSecondary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Appearance", icon: "paintbrush")
            
            // Theme Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textSecondary))
                
                HStack(spacing: 12) {
                    ThemeOption(
                        name: "Cyberpunk",
                        colors: [Color(CyberpunkTheme.primaryCyan), Color(CyberpunkTheme.accentPink)],
                        isSelected: viewModel.selectedTheme == .cyberpunk
                    ) {
                        viewModel.selectedTheme = .cyberpunk
                    }
                    
                    ThemeOption(
                        name: "Dark",
                        colors: [Color(UIColor.darkGray), Color(UIColor.systemGray)],
                        isSelected: viewModel.selectedTheme == .dark
                    ) {
                        viewModel.selectedTheme = .dark
                    }
                    
                    ThemeOption(
                        name: "Light",
                        colors: [Color.white, Color(UIColor.systemBlue)],
                        isSelected: viewModel.selectedTheme == .light
                    ) {
                        viewModel.selectedTheme = .light
                    }
                }
            }
            
            // Font Size Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Font Size")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.textSecondary))
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.fontSize))pt")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                }
                
                Slider(value: $viewModel.fontSize, in: 10...20, step: 1)
                    .accentColor(Color(CyberpunkTheme.primaryCyan))
                
                // Preview text
                Text("Preview: The quick brown fox jumps over the lazy dog")
                    .font(.system(size: CGFloat(viewModel.fontSize)))
                    .foregroundColor(Color(CyberpunkTheme.textPrimary))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(CyberpunkTheme.surface).opacity(0.5))
                    )
            }
            
            // Glow Effects Toggle
            Toggle(isOn: $viewModel.glowEffectsEnabled) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    Text("Glow Effects")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.textPrimary))
                }
            }
            .tint(Color(CyberpunkTheme.primaryCyan))
            
            // Animations Toggle
            Toggle(isOn: $viewModel.animationsEnabled) {
                HStack {
                    Image(systemName: "wand.and.rays")
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    Text("Animations")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.textPrimary))
                }
            }
            .tint(Color(CyberpunkTheme.primaryCyan))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(CyberpunkTheme.surface))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Editor Section
    
    private var editorSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Editor", icon: "doc.text")
            
            // Line Numbers Toggle
            Toggle(isOn: $viewModel.showLineNumbers) {
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    Text("Show Line Numbers")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.textPrimary))
                }
            }
            .tint(Color(CyberpunkTheme.primaryCyan))
            
            // Syntax Highlighting Toggle
            Toggle(isOn: $viewModel.syntaxHighlighting) {
                HStack {
                    Image(systemName: "paintbrush.pointed")
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    Text("Syntax Highlighting")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.textPrimary))
                }
            }
            .tint(Color(CyberpunkTheme.primaryCyan))
            
            // Tab Size Stepper
            HStack {
                HStack {
                    Image(systemName: "arrow.right.to.line")
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    Text("Tab Size")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.textPrimary))
                }
                
                Spacer()
                
                Stepper("\(viewModel.tabSize) spaces", value: $viewModel.tabSize, in: 2...8, step: 2)
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.primaryCyan))
            }
            
            // Word Wrap Toggle
            Toggle(isOn: $viewModel.wordWrapEnabled) {
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    Text("Word Wrap")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.textPrimary))
                }
            }
            .tint(Color(CyberpunkTheme.primaryCyan))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(CyberpunkTheme.surface))
        )
        .padding(.horizontal)
    }
    
    // MARK: - API Configuration Section
    
    private var apiSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "API Configuration", icon: "network")
            
            // Backend URL
            VStack(alignment: .leading, spacing: 8) {
                Text("Backend URL")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textSecondary))
                
                TextField("http://localhost:3004", text: $viewModel.backendURL)
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textPrimary))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(CyberpunkTheme.background))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(CyberpunkTheme.border), lineWidth: 1)
                            )
                    )
                    .accentColor(Color(CyberpunkTheme.primaryCyan))
            }
            
            // Test Connection Button
            Button(action: { viewModel.testConnection() }) {
                HStack {
                    if viewModel.isTestingConnection {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "network")
                    }
                    
                    Text(viewModel.isTestingConnection ? "Testing..." : "Test Connection")
                        .font(.system(size: 14, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
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
                .cornerRadius(8)
            }
            .disabled(viewModel.isTestingConnection)
            
            // Connection Status
            if let connectionStatus = viewModel.connectionStatus {
                HStack {
                    Image(systemName: connectionStatus.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(connectionStatus.success ? Color(CyberpunkTheme.success) : Color(CyberpunkTheme.error))
                    
                    Text(connectionStatus.message)
                        .font(.system(size: 12))
                        .foregroundColor(Color(CyberpunkTheme.textSecondary))
                    
                    Spacer()
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(CyberpunkTheme.surface).opacity(0.5))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(CyberpunkTheme.surface))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Data Management Section
    
    private var dataManagementSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Data Management", icon: "folder")
            
            // Export Settings
            Button(action: exportSettings) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    Text("Export Settings")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.textPrimary))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(CyberpunkTheme.textTertiary))
                }
                .padding(.vertical, 12)
            }
            
            Divider()
                .background(Color(CyberpunkTheme.border))
            
            // Import Settings
            Button(action: { showingImportPicker = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    Text("Import Settings")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.textPrimary))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(CyberpunkTheme.textTertiary))
                }
                .padding(.vertical, 12)
            }
            
            Divider()
                .background(Color(CyberpunkTheme.border))
            
            // Clear Cache
            Button(action: { viewModel.clearCache() }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(Color(CyberpunkTheme.warning))
                    Text("Clear Cache")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.textPrimary))
                    Spacer()
                    Text(viewModel.cacheSize)
                        .font(.system(size: 12))
                        .foregroundColor(Color(CyberpunkTheme.textTertiary))
                }
                .padding(.vertical, 12)
            }
            
            Divider()
                .background(Color(CyberpunkTheme.border))
            
            // Reset Settings
            Button(action: { showingResetAlert = true }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(Color(CyberpunkTheme.error))
                    Text("Reset to Defaults")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.error))
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(CyberpunkTheme.surface))
        )
        .padding(.horizontal)
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "About", icon: "info.circle")
            
            // App Version
            HStack {
                Text("Version")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textSecondary))
                Spacer()
                Text(viewModel.appVersion)
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textPrimary))
            }
            
            // Build Number
            HStack {
                Text("Build")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textSecondary))
                Spacer()
                Text(viewModel.buildNumber)
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textPrimary))
            }
            
            // Developer
            HStack {
                Text("Developer")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textSecondary))
                Spacer()
                Text("Claude Code Team")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.textPrimary))
            }
            
            // Links
            VStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/claudecode")!) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                        Text("GitHub")
                            .font(.system(size: 14))
                            .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    }
                }
                
                Link(destination: URL(string: "https://claudecode.io/privacy")!) {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                        Text("Privacy Policy")
                            .font(.system(size: 14))
                            .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(CyberpunkTheme.surface))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func exportSettings() {
        if let url = viewModel.exportSettings() {
            exportedFileURL = url
            showingExportSheet = true
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(CyberpunkTheme.primaryCyan))
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(CyberpunkTheme.textPrimary))
            Spacer()
        }
    }
}

struct ThemeOption: View {
    let name: String
    let colors: [Color]
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 60)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color(CyberpunkTheme.primaryCyan) : Color.clear,
                            lineWidth: 2
                        )
                )
                
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(Color(CyberpunkTheme.textPrimary))
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}