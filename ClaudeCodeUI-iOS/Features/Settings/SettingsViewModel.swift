//
//  SettingsViewModel.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import Foundation
import SwiftUI
import UIKit

enum AppTheme: String, CaseIterable {
    case cyberpunk = "Cyberpunk"
    case dark = "Dark"
    case light = "Light"
}

struct SettingsConnectionStatus {
    let success: Bool
    let message: String
}

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Appearance Settings
    @Published var selectedTheme: AppTheme = .cyberpunk {
        didSet {
            saveSettings()
            applyTheme()
        }
    }
    
    @Published var fontSize: Double = 14.0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var glowEffectsEnabled = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var animationsEnabled = true {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Editor Settings
    @Published var showLineNumbers = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var syntaxHighlighting = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var tabSize = 4 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var wordWrapEnabled = true {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - API Configuration
    @Published var backendURL = "http://localhost:3004" {
        didSet {
            saveSettings()
        }
    }
    
    @Published var isTestingConnection = false
    @Published var connectionStatus: SettingsConnectionStatus?
    
    // MARK: - Data Management
    @Published var cacheSize = "0 MB"
    
    // MARK: - About
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "AppSettings"
    
    init() {
        loadSettings()
        calculateCacheSize()
    }
    
    // MARK: - Public Methods
    
    func testConnection() {
        isTestingConnection = true
        connectionStatus = nil
        
        Task {
            do {
                // Create URL
                guard let url = URL(string: "\(backendURL)/api/health") else {
                    await MainActor.run {
                        self.connectionStatus = SettingsConnectionStatus(
                            success: false,
                            message: "Invalid URL"
                        )
                        self.isTestingConnection = false
                    }
                    return
                }
                
                // Make request
                let (_, response) = try await URLSession.shared.data(from: url)
                
                // Check response
                if let httpResponse = response as? HTTPURLResponse {
                    let success = httpResponse.statusCode == 200
                    await MainActor.run {
                        self.connectionStatus = SettingsConnectionStatus(
                            success: success,
                            message: success ? "Connection successful" : "Server returned: \(httpResponse.statusCode)"
                        )
                        self.isTestingConnection = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.connectionStatus = SettingsConnectionStatus(
                        success: false,
                        message: "Connection failed: \(error.localizedDescription)"
                    )
                    self.isTestingConnection = false
                }
            }
        }
    }
    
    func clearCache() {
        // Clear URLCache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear image cache if you have one
        // ImageCache.shared.clear()
        
        // Clear UserDefaults cache keys
        let cacheKeys = userDefaults.dictionaryRepresentation().keys.filter { $0.contains("cache") }
        cacheKeys.forEach { userDefaults.removeObject(forKey: $0) }
        
        // Recalculate cache size
        calculateCacheSize()
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func resetToDefaults() {
        // Reset all settings to defaults
        selectedTheme = .cyberpunk
        fontSize = 14.0
        glowEffectsEnabled = true
        animationsEnabled = true
        showLineNumbers = true
        syntaxHighlighting = true
        tabSize = 4
        wordWrapEnabled = true
        backendURL = "http://localhost:3004"
        
        // Clear stored settings
        userDefaults.removeObject(forKey: settingsKey)
        
        // Apply theme
        applyTheme()
        
        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    func exportSettings() -> URL? {
        let settings: [String: Any] = [
            "theme": selectedTheme.rawValue,
            "fontSize": fontSize,
            "glowEffects": glowEffectsEnabled,
            "animations": animationsEnabled,
            "showLineNumbers": showLineNumbers,
            "syntaxHighlighting": syntaxHighlighting,
            "tabSize": tabSize,
            "wordWrap": wordWrapEnabled,
            "backendURL": backendURL,
            "exportDate": Date().timeIntervalSince1970
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
            
            // Create temporary file
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileName = "claudecode-settings-\(Date().timeIntervalSince1970).json"
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL)
            
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            return fileURL
        } catch {
            print("Failed to export settings: \(error)")
            return nil
        }
    }
    
    func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importSettings(from: url)
        case .failure(let error):
            print("Failed to import: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return
        }
        
        // Apply loaded settings
        if let theme = AppTheme(rawValue: settings.theme) {
            selectedTheme = theme
        }
        fontSize = settings.fontSize
        glowEffectsEnabled = settings.glowEffects
        animationsEnabled = settings.animations
        showLineNumbers = settings.showLineNumbers
        syntaxHighlighting = settings.syntaxHighlighting
        tabSize = settings.tabSize
        wordWrapEnabled = settings.wordWrap
        backendURL = settings.backendURL
    }
    
    private func saveSettings() {
        let settings = AppSettings(
            theme: selectedTheme.rawValue,
            fontSize: fontSize,
            glowEffects: glowEffectsEnabled,
            animations: animationsEnabled,
            showLineNumbers: showLineNumbers,
            syntaxHighlighting: syntaxHighlighting,
            tabSize: tabSize,
            wordWrap: wordWrapEnabled,
            backendURL: backendURL
        )
        
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }
    
    private func importSettings(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            // Apply imported settings
            if let themeString = json["theme"] as? String,
               let theme = AppTheme(rawValue: themeString) {
                selectedTheme = theme
            }
            
            if let size = json["fontSize"] as? Double {
                fontSize = size
            }
            
            if let glow = json["glowEffects"] as? Bool {
                glowEffectsEnabled = glow
            }
            
            if let animations = json["animations"] as? Bool {
                animationsEnabled = animations
            }
            
            if let lineNumbers = json["showLineNumbers"] as? Bool {
                showLineNumbers = lineNumbers
            }
            
            if let syntax = json["syntaxHighlighting"] as? Bool {
                syntaxHighlighting = syntax
            }
            
            if let tab = json["tabSize"] as? Int {
                tabSize = tab
            }
            
            if let wrap = json["wordWrap"] as? Bool {
                wordWrapEnabled = wrap
            }
            
            if let url = json["backendURL"] as? String {
                backendURL = url
            }
            
            // Save and apply
            saveSettings()
            applyTheme()
            
            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
        } catch {
            print("Failed to import settings: \(error)")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    private func applyTheme() {
        // In a real app, this would update the app's appearance
        // For now, we'll just trigger a notification
        NotificationCenter.default.post(
            name: Notification.Name("ThemeDidChange"),
            object: nil,
            userInfo: ["theme": selectedTheme]
        )
    }
    
    private func calculateCacheSize() {
        Task {
            let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let size = try? FileManager.default.allocatedSizeOfDirectory(at: cacheDirectory)
            
            await MainActor.run {
                if let size = size {
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    self.cacheSize = formatter.string(fromByteCount: Int64(size))
                } else {
                    self.cacheSize = "Unknown"
                }
            }
        }
    }
}

// MARK: - Settings Model

private struct AppSettings: Codable {
    let theme: String
    let fontSize: Double
    let glowEffects: Bool
    let animations: Bool
    let showLineNumbers: Bool
    let syntaxHighlighting: Bool
    let tabSize: Int
    let wordWrap: Bool
    let backendURL: String
}

// MARK: - FileManager Extension

extension FileManager {
    func allocatedSizeOfDirectory(at url: URL) throws -> Int {
        var size = 0
        
        let enumerator = self.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
            options: [],
            errorHandler: nil
        )
        
        while let fileURL = enumerator?.nextObject() as? URL {
            let resourceValues = try fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
            size += resourceValues.totalFileAllocatedSize ?? 0
        }
        
        return size
    }
}

// MARK: - UIKit Bridge
// SettingsViewController is defined in SettingsViewController.swift