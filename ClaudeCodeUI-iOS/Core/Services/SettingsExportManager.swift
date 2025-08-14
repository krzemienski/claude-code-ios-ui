//
//  SettingsExportManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025/01/05.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

/// Manager for exporting and importing app settings
class SettingsExportManager {
    
    // MARK: - Singleton
    static let shared = SettingsExportManager()
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Settings Structure
    struct ExportedSettings: Codable {
        let version: String
        let exportDate: Date
        let deviceInfo: String
        let settings: SettingsData
        let projects: [ProjectData]?
        let customTheme: ThemeData?
        
        struct SettingsData: Codable {
            let backendURL: String
            let enableHaptics: Bool
            let enableSounds: Bool
            let codeTheme: String
            let fontSize: Int
            let enableAutoSave: Bool
            let syncInterval: Int
            let maxCacheSize: Int
            let enableDebugMode: Bool
        }
        
        struct ProjectData: Codable {
            let id: String
            let name: String
            let path: String
            let createdAt: Date
            let lastModified: Date
            let customSettings: [String: Any]?
            
            enum CodingKeys: String, CodingKey {
                case id, name, path, createdAt, lastModified, customSettings
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                id = try container.decode(String.self, forKey: .id)
                name = try container.decode(String.self, forKey: .name)
                path = try container.decode(String.self, forKey: .path)
                createdAt = try container.decode(Date.self, forKey: .createdAt)
                lastModified = try container.decode(Date.self, forKey: .lastModified)
                customSettings = nil // Simplified for now
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(id, forKey: .id)
                try container.encode(name, forKey: .name)
                try container.encode(path, forKey: .path)
                try container.encode(createdAt, forKey: .createdAt)
                try container.encode(lastModified, forKey: .lastModified)
            }
        }
        
        struct ThemeData: Codable {
            let primaryColor: String
            let accentColor: String
            let backgroundColor: String
            let surfaceColor: String
            let textColor: String
            let customFonts: [String]?
        }
    }
    
    // MARK: - Export Methods
    
    /// Export current settings to a file
    func exportSettings(includeProjects: Bool = true) -> Result<URL, Error> {
        do {
            // Gather current settings
            let settings = gatherCurrentSettings()
            
            // Include projects if requested
            let projects = includeProjects ? gatherProjects() : nil
            
            // Create export data
            let exportData = ExportedSettings(
                version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                exportDate: Date(),
                deviceInfo: getDeviceInfo(),
                settings: settings,
                projects: projects,
                customTheme: gatherCustomTheme()
            )
            
            // Encode to JSON
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(exportData)
            
            // Save to temporary file
            let fileName = "claudecode-settings-\(Date().timeIntervalSince1970).json"
            let tempURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)
            try jsonData.write(to: tempURL)
            
            Logger.shared.info("Settings exported successfully to: \(tempURL)")
            return .success(tempURL)
            
        } catch {
            Logger.shared.error("Failed to export settings: \(error)")
            return .failure(error)
        }
    }
    
    /// Import settings from a file
    func importSettings(from url: URL, mergeProjects: Bool = false) -> Result<Void, Error> {
        do {
            // Read file
            let jsonData = try Data(contentsOf: url)
            
            // Decode settings
            decoder.dateDecodingStrategy = .iso8601
            let importedSettings = try decoder.decode(ExportedSettings.self, from: jsonData)
            
            // Validate version compatibility
            guard isVersionCompatible(importedSettings.version) else {
                throw ImportError.incompatibleVersion(importedSettings.version)
            }
            
            // Apply settings
            applySettings(importedSettings.settings)
            
            // Apply theme if present
            if let theme = importedSettings.customTheme {
                applyCustomTheme(theme)
            }
            
            // Handle projects
            if let projects = importedSettings.projects {
                if mergeProjects {
                    self.mergeProjects(projects)
                } else {
                    replaceProjects(projects)
                }
            }
            
            // Notify of successful import
            NotificationCenter.default.post(name: .settingsImported, object: nil)
            
            Logger.shared.info("Settings imported successfully from: \(url)")
            return .success(())
            
        } catch {
            Logger.shared.error("Failed to import settings: \(error)")
            return .failure(error)
        }
    }
    
    // MARK: - Backup Methods
    
    /// Create automatic backup
    func createBackup() -> Result<URL, Error> {
        do {
            // Create backups directory
            let backupsDir = getBackupsDirectory()
            try fileManager.createDirectory(at: backupsDir, withIntermediateDirectories: true)
            
            // Export settings
            let exportResult = exportSettings(includeProjects: true)
            
            switch exportResult {
            case .success(let tempURL):
                // Move to backups directory with timestamp
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
                let timestamp = dateFormatter.string(from: Date())
                let backupName = "backup-\(timestamp).json"
                let backupURL = backupsDir.appendingPathComponent(backupName)
                
                try fileManager.moveItem(at: tempURL, to: backupURL)
                
                // Clean old backups (keep last 10)
                cleanOldBackups()
                
                Logger.shared.info("Backup created: \(backupURL)")
                return .success(backupURL)
                
            case .failure(let error):
                return .failure(error)
            }
            
        } catch {
            Logger.shared.error("Failed to create backup: \(error)")
            return .failure(error)
        }
    }
    
    /// Restore from backup
    func restoreFromBackup(at url: URL) -> Result<Void, Error> {
        return importSettings(from: url, mergeProjects: false)
    }
    
    /// List available backups
    func listBackups() -> [BackupInfo] {
        let backupsDir = getBackupsDirectory()
        
        guard let urls = try? fileManager.contentsOfDirectory(
            at: backupsDir,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        
        return urls.compactMap { url in
            guard url.pathExtension == "json" else { return nil }
            
            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
            let creationDate = attributes?[.creationDate] as? Date ?? Date()
            let fileSize = attributes?[.size] as? Int64 ?? 0
            
            return BackupInfo(
                url: url,
                name: url.lastPathComponent,
                creationDate: creationDate,
                size: fileSize
            )
        }.sorted { $0.creationDate > $1.creationDate }
    }
    
    // MARK: - Private Methods
    
    private func gatherCurrentSettings() -> ExportedSettings.SettingsData {
        let defaults = UserDefaults.standard
        
        return ExportedSettings.SettingsData(
            backendURL: AppConfig.backendURL,
            enableHaptics: defaults.bool(forKey: "EnableHaptics"),
            enableSounds: defaults.bool(forKey: "EnableSounds"),
            codeTheme: defaults.string(forKey: "CodeTheme") ?? "cyberpunk",
            fontSize: defaults.integer(forKey: "FontSize"),
            enableAutoSave: defaults.bool(forKey: "EnableAutoSave"),
            syncInterval: defaults.integer(forKey: "SyncInterval"),
            maxCacheSize: defaults.integer(forKey: "MaxCacheSize"),
            enableDebugMode: defaults.bool(forKey: "EnableDebugMode")
        )
    }
    
    private func gatherProjects() -> [ExportedSettings.ProjectData]? {
        // This would normally fetch from SwiftData
        // Simplified for demonstration
        return nil
    }
    
    private func gatherCustomTheme() -> ExportedSettings.ThemeData? {
        // Return current theme if customized
        guard UserDefaults.standard.bool(forKey: "HasCustomTheme") else { return nil }
        
        return ExportedSettings.ThemeData(
            primaryColor: CyberpunkTheme.primaryCyan.hexString,
            accentColor: CyberpunkTheme.accentPink.hexString,
            backgroundColor: CyberpunkTheme.background.hexString,
            surfaceColor: CyberpunkTheme.surface.hexString,
            textColor: CyberpunkTheme.textPrimary.hexString,
            customFonts: nil
        )
    }
    
    private func applySettings(_ settings: ExportedSettings.SettingsData) {
        let defaults = UserDefaults.standard
        
        AppConfig.updateBackendURL(settings.backendURL)
        defaults.set(settings.enableHaptics, forKey: "EnableHaptics")
        defaults.set(settings.enableSounds, forKey: "EnableSounds")
        defaults.set(settings.codeTheme, forKey: "CodeTheme")
        defaults.set(settings.fontSize, forKey: "FontSize")
        defaults.set(settings.enableAutoSave, forKey: "EnableAutoSave")
        defaults.set(settings.syncInterval, forKey: "SyncInterval")
        defaults.set(settings.maxCacheSize, forKey: "MaxCacheSize")
        defaults.set(settings.enableDebugMode, forKey: "EnableDebugMode")
    }
    
    private func applyCustomTheme(_ theme: ExportedSettings.ThemeData) {
        // Apply theme colors
        // This would update the CyberpunkTheme with custom colors
        UserDefaults.standard.set(true, forKey: "HasCustomTheme")
    }
    
    private func mergeProjects(_ projects: [ExportedSettings.ProjectData]) {
        // Merge with existing projects
        Logger.shared.info("Merging \(projects.count) projects")
    }
    
    private func replaceProjects(_ projects: [ExportedSettings.ProjectData]) {
        // Replace all existing projects
        Logger.shared.info("Replacing with \(projects.count) projects")
    }
    
    private func isVersionCompatible(_ version: String) -> Bool {
        // Check if imported version is compatible
        // For now, accept all versions
        return true
    }
    
    private func getBackupsDirectory() -> URL {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDir.appendingPathComponent("Backups")
    }
    
    private func cleanOldBackups(keepCount: Int = 10) {
        let backups = listBackups()
        guard backups.count > keepCount else { return }
        
        // Delete oldest backups
        let toDelete = backups.suffix(from: keepCount)
        for backup in toDelete {
            try? fileManager.removeItem(at: backup.url)
            Logger.shared.info("Deleted old backup: \(backup.name)")
        }
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) - iOS \(device.systemVersion)"
    }
    
    // MARK: - Error Types
    enum ImportError: LocalizedError {
        case incompatibleVersion(String)
        case invalidData
        case missingRequiredFields
        
        var errorDescription: String? {
            switch self {
            case .incompatibleVersion(let version):
                return "Incompatible settings version: \(version)"
            case .invalidData:
                return "Invalid settings data format"
            case .missingRequiredFields:
                return "Missing required fields in settings"
            }
        }
    }
}

// MARK: - Supporting Types
struct BackupInfo {
    let url: URL
    let name: String
    let creationDate: Date
    let size: Int64
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - UIColor Extension
extension UIColor {
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255) << 0
        return String(format: "#%06x", rgb)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let settingsImported = Notification.Name("SettingsImported")
    static let settingsExported = Notification.Name("SettingsExported")
    static let backupCreated = Notification.Name("BackupCreated")
    static let backupRestored = Notification.Name("BackupRestored")
}