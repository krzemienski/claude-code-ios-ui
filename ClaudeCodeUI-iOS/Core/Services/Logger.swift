//
//  Logger.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation
import os.log

// MARK: - Log Level
enum LogLevel: Int, Comparable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case critical = 5
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var emoji: String {
        switch self {
        case .verbose: return "🔍"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .verbose, .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

// MARK: - Logger
final class Logger {
    
    // MARK: - Properties
    static let shared = Logger()
    
    private let subsystem = "com.claudecodeui.ios"
    private var loggers: [String: OSLog] = [:]
    private let queue = DispatchQueue(label: "com.claudecodeui.logger", attributes: .concurrent)
    
    var minimumLogLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }()
    
    var isConsoleLoggingEnabled = true
    var isFileLoggingEnabled = false
    private var logFileURL: URL?
    
    // MARK: - Initialization
    private init() {
        setupFileLogging()
    }
    
    // MARK: - Public Methods
    func verbose(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .verbose, category: category, file: file, function: function, line: line)
    }
    
    func debug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Error Logging
    func error(_ error: Error, category: String = "Error", file: String = #file, function: String = #function, line: Int = #line) {
        let message = "Error: \(error.localizedDescription)"
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Performance Logging
    func measureTime<T>(label: String, category: String = "Performance", block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            info("⏱ \(label) took \(String(format: "%.3f", timeElapsed))s", category: category)
        }
        return try block()
    }
    
    @available(iOS 16.0, *)
    func measureTimeAsync<T>(label: String, category: String = "Performance", block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            info("⏱ \(label) took \(String(format: "%.3f", timeElapsed))s", category: category)
        }
        return try await block()
    }
    
    // MARK: - Private Methods
    private func log(_ message: String, level: LogLevel, category: String, file: String, function: String, line: Int) {
        guard level >= minimumLogLevel else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = formatMessage(message, level: level, fileName: fileName, function: function, line: line)
        
        // OS Log
        let osLog = getOSLog(for: category)
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        
        // Console Log
        if isConsoleLoggingEnabled {
            queue.async(flags: .barrier) {
                print(logMessage)
            }
        }
        
        // File Log
        if isFileLoggingEnabled {
            queue.async(flags: .barrier) { [weak self] in
                self?.writeToFile(logMessage)
            }
        }
    }
    
    private func formatMessage(_ message: String, level: LogLevel, fileName: String, function: String, line: Int) -> String {
        let timestamp = DateFormatter.logDateFormatter.string(from: Date())
        return "\(timestamp) \(level.emoji) [\(fileName):\(line)] \(function) - \(message)"
    }
    
    private func getOSLog(for category: String) -> OSLog {
        return queue.sync {
            if let logger = loggers[category] {
                return logger
            }
            let logger = OSLog(subsystem: subsystem, category: category)
            loggers[category] = logger
            return logger
        }
    }
    
    // MARK: - File Logging
    private func setupFileLogging() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let logsDirectory = documentsDirectory.appendingPathComponent("Logs")
        
        do {
            try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true, attributes: nil)
            
            let dateString = DateFormatter.fileDateFormatter.string(from: Date())
            let fileName = "claudecodeui_\(dateString).log"
            logFileURL = logsDirectory.appendingPathComponent(fileName)
            
            // Create file if it doesn't exist
            if !FileManager.default.fileExists(atPath: logFileURL!.path) {
                FileManager.default.createFile(atPath: logFileURL!.path, contents: nil, attributes: nil)
            }
        } catch {
            print("Failed to setup file logging: \(error)")
        }
    }
    
    private func writeToFile(_ message: String) {
        guard let logFileURL = logFileURL else { return }
        
        let logLine = message + "\n"
        
        if let data = logLine.data(using: .utf8) {
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                defer { fileHandle.closeFile() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
            }
        }
    }
    
    // MARK: - Log Management
    func clearLogs() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let logsDirectory = documentsDirectory.appendingPathComponent("Logs")
        
        do {
            let logFiles = try FileManager.default.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: nil)
            for logFile in logFiles {
                try FileManager.default.removeItem(at: logFile)
            }
            info("Cleared all log files", category: "Logger")
        } catch {
            self.error(error, category: "Logger")
        }
    }
    
    func getLogFiles() -> [URL] {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return [] }
        
        let logsDirectory = documentsDirectory.appendingPathComponent("Logs")
        
        do {
            let logFiles = try FileManager.default.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: [.creationDateKey])
            return logFiles.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
        } catch {
            self.error(error, category: "Logger")
            return []
        }
    }
}

// MARK: - Date Formatter Extensions
private extension DateFormatter {
    static let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

// MARK: - Convenience Global Functions
func logVerbose(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.verbose(message, category: category, file: file, function: function, line: line)
}

func logDebug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, category: category, file: file, function: function, line: line)
}

func logInfo(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, category: category, file: file, function: function, line: line)
}

func logWarning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, category: category, file: file, function: function, line: line)
}

func logError(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, category: category, file: file, function: function, line: line)
}

func logCritical(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.critical(message, category: category, file: file, function: function, line: line)
}