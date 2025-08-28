//
//  CursorConfigurationView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import SwiftUI

// MARK: - Cursor Model Settings
struct CursorModelSettings {
    var model: String = "gpt-4"
    var temperature: Double = 0.7
    var maxTokens: Int = 2048
    var topP: Double = 1.0
    var frequencyPenalty: Double = 0.0
    var presencePenalty: Double = 0.0
    var streamingEnabled: Bool = false
}

// MARK: - Cursor Features
struct CursorFeatures {
    var copilotEnabled: Bool = true
    var chatEnabled: Bool = true
    var commandPaletteEnabled: Bool = true
    var inlineCompletionEnabled: Bool = true
}

// MARK: - Extended Cursor Config
struct ExtendedCursorConfig {
    var enabled: Bool = false
    var apiKey: String = ""
    var apiUrl: String = "https://api.openai.com"
    var workspacePath: String? = nil
    var extensionsPath: String? = nil
    var configPath: String? = nil
    var lastSyncDate: Date? = nil
    var modelSettings: CursorModelSettings? = CursorModelSettings()
    var features: CursorFeatures? = CursorFeatures()
    
    // Convert from CursorConfig
    init(from config: CursorConfig? = nil) {
        if let config = config {
            self.enabled = config.enabled
            self.apiKey = config.apiKey ?? ""
            self.apiUrl = config.apiUrl ?? "https://api.openai.com"
            self.modelSettings = CursorModelSettings(
                model: config.model ?? "gpt-4",
                temperature: config.temperature ?? 0.7,
                maxTokens: config.maxTokens ?? 2048,
                topP: 1.0,
                frequencyPenalty: 0.0,
                presencePenalty: 0.0,
                streamingEnabled: false
            )
            self.features = CursorFeatures()
        }
    }
    
    init() {
        // Default initializer
    }
}

// MARK: - Cursor Configuration View
struct CursorConfigurationView: View {
    @ObservedObject var viewModel: CursorViewModel
    @State private var editedConfig: ExtendedCursorConfig = ExtendedCursorConfig()
    @State private var hasChanges = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cursor Configuration")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Configure your Cursor AI integration settings")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                
                // Configuration Sections
                VStack(spacing: 16) {
                    // Paths Section
                    ConfigSection(title: "Paths", icon: "folder.fill") {
                        ConfigField(
                            label: "Workspace Path",
                            value: $editedConfig.workspacePath,
                            placeholder: "~/Documents/CursorProjects",
                            onChange: { _ in hasChanges = true }
                        )
                        
                        ConfigField(
                            label: "Extensions Path",
                            value: $editedConfig.extensionsPath,
                            placeholder: "~/.cursor/extensions",
                            onChange: { _ in hasChanges = true }
                        )
                        
                        ConfigField(
                            label: "Config Path",
                            value: $editedConfig.configPath,
                            placeholder: "~/.cursor/config",
                            onChange: { _ in hasChanges = true }
                        )
                    }
                    
                    // API Section
                    ConfigSection(title: "API Settings", icon: "key.fill") {
                        SecureConfigField(
                            label: "API Key",
                            value: $editedConfig.apiKey,
                            placeholder: "sk-...",
                            onChange: { _ in hasChanges = true }
                        )
                    }
                    
                    // Model Settings Section
                    if editedConfig.modelSettings != nil {
                        ConfigSection(title: "Model Settings", icon: "cpu") {
                            ModelSettingsView(
                                settings: Binding(
                                    get: { editedConfig.modelSettings ?? CursorModelSettings() },
                                    set: { 
                                        editedConfig.modelSettings = $0
                                        hasChanges = true
                                    }
                                )
                            )
                        }
                    }
                    
                    // Features Section
                    if editedConfig.features != nil {
                        ConfigSection(title: "Features", icon: "sparkles") {
                            FeaturesToggleView(
                                features: Binding(
                                    get: { editedConfig.features ?? CursorFeatures() },
                                    set: { 
                                        editedConfig.features = $0
                                        hasChanges = true
                                    }
                                )
                            )
                        }
                    }
                    
                    // Action Buttons
                    if hasChanges {
                        HStack(spacing: 16) {
                            Button(action: {
                                editedConfig = viewModel.config ?? CursorConfig()
                                hasChanges = false
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.8))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                Task {
                                    await viewModel.updateConfiguration(editedConfig)
                                    hasChanges = false
                                }
                            }) {
                                Text("Save Changes")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0, green: 0.85, blue: 1), Color(red: 0, green: 0.65, blue: 0.9)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        .transition(.opacity)
                    }
                }
                
                // Last Sync Info
                if let lastSync = editedConfig.lastSyncDate {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                        
                        Text("Last synced: \(lastSync, formatter: dateFormatter)")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .onAppear {
            editedConfig = ExtendedCursorConfig(from: viewModel.config)
        }
        .onChange(of: viewModel.config) { newConfig in
            if !hasChanges {
                editedConfig = ExtendedCursorConfig(from: newConfig)
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Config Section
struct ConfigSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Config Field
struct ConfigField: View {
    let label: String
    @Binding var value: String?
    let placeholder: String
    let onChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.white.opacity(0.6))
            
            TextField(placeholder, text: Binding(
                get: { value ?? "" },
                set: { newValue in
                    value = newValue.isEmpty ? nil : newValue
                    onChange(newValue)
                }
            ))
            .font(.system(size: 14))
            .foregroundColor(.white)
            .padding(10)
            .background(Color.white.opacity(0.08))
            .cornerRadius(8)
        }
    }
}

// MARK: - Secure Config Field
struct SecureConfigField: View {
    let label: String
    @Binding var value: String?
    let placeholder: String
    let onChange: (String) -> Void
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.white.opacity(0.6))
            
            HStack {
                if isSecure {
                    SecureField(placeholder, text: Binding(
                        get: { value ?? "" },
                        set: { newValue in
                            value = newValue.isEmpty ? nil : newValue
                            onChange(newValue)
                        }
                    ))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                } else {
                    TextField(placeholder, text: Binding(
                        get: { value ?? "" },
                        set: { newValue in
                            value = newValue.isEmpty ? nil : newValue
                            onChange(newValue)
                        }
                    ))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                }
                
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundColor(Color.white.opacity(0.5))
                        .font(.system(size: 14))
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.08))
            .cornerRadius(8)
        }
    }
}

// MARK: - Model Settings View
struct ModelSettingsView: View {
    @Binding var settings: CursorModelSettings
    
    var body: some View {
        VStack(spacing: 12) {
            // Model Selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Model")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))
                
                Menu {
                    ForEach(["gpt-4", "gpt-4-turbo", "gpt-3.5-turbo", "claude-3-opus", "claude-3-sonnet"], id: \.self) { model in
                        Button(model) {
                            settings.model = model
                        }
                    }
                } label: {
                    HStack {
                        Text(settings.model)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                }
            }
            
            // Temperature Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Temperature")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                    Spacer()
                    Text(String(format: "%.1f", settings.temperature))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                }
                
                Slider(value: $settings.temperature, in: 0...2, step: 0.1)
                    .accentColor(Color(red: 0, green: 0.85, blue: 1))
            }
            
            // Max Tokens
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Max Tokens")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                    Spacer()
                    Text("\(settings.maxTokens)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0, green: 0.85, blue: 1))
                }
                
                Slider(value: Binding(
                    get: { Double(settings.maxTokens) },
                    set: { settings.maxTokens = Int($0) }
                ), in: 100...8000, step: 100)
                .accentColor(Color(red: 0, green: 0.85, blue: 1))
            }
            
            // Streaming Toggle
            Toggle(isOn: $settings.streamingEnabled) {
                Text("Streaming Enabled")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .toggleStyle(CyberpunkToggleStyle())
        }
    }
}

// MARK: - Features Toggle View
struct FeaturesToggleView: View {
    @Binding var features: CursorFeatures
    
    var body: some View {
        VStack(spacing: 12) {
            FeatureToggle(title: "Copilot", isOn: $features.copilotEnabled)
            FeatureToggle(title: "Chat", isOn: $features.chatEnabled)
            FeatureToggle(title: "Command Palette", isOn: $features.commandPaletteEnabled)
            FeatureToggle(title: "Inline Completion", isOn: $features.inlineCompletionEnabled)
        }
    }
}

struct FeatureToggle: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .toggleStyle(CyberpunkToggleStyle())
    }
}

// MARK: - Cyberpunk Toggle Style
struct CyberpunkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? 
                      Color(red: 0, green: 0.85, blue: 1).opacity(0.3) : 
                      Color.white.opacity(0.1))
                .frame(width: 48, height: 28)
                .overlay(
                    Circle()
                        .fill(configuration.isOn ? 
                              Color(red: 0, green: 0.85, blue: 1) : 
                              Color.white.opacity(0.5))
                        .frame(width: 22, height: 22)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.spring(response: 0.3), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}