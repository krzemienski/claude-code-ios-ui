//
//  FileNode.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import Foundation

// File tree node for representing project file structure
// Not persisted with SwiftData as it's loaded dynamically
class FileNode: Identifiable, ObservableObject, Decodable {
    let id: String
    let name: String
    let path: String
    let type: FileType
    @Published var isExpanded: Bool = false
    @Published var children: [FileNode] = []
    weak var parent: FileNode?
    
    // File metadata
    let size: Int64?
    let modifiedDate: Date?
    let permissions: String?
    
    init(name: String, path: String, type: FileType, size: Int64? = nil, modifiedDate: Date? = nil, permissions: String? = nil) {
        self.id = path
        self.name = name
        self.path = path
        self.type = type
        self.size = size
        self.modifiedDate = modifiedDate
        self.permissions = permissions
    }
    
    // MARK: - Decodable
    enum CodingKeys: String, CodingKey {
        case name
        case path
        case type
        case children
        case size
        case modifiedDate
        case permissions
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.path = try container.decode(String.self, forKey: .path)
        self.type = try container.decode(FileType.self, forKey: .type)
        self.id = path
        self.children = try container.decodeIfPresent([FileNode].self, forKey: .children) ?? []
        self.size = try container.decodeIfPresent(Int64.self, forKey: .size)
        self.modifiedDate = try container.decodeIfPresent(Date.self, forKey: .modifiedDate)
        self.permissions = try container.decodeIfPresent(String.self, forKey: .permissions)
        self.isExpanded = false
        
        // Set parent references for children
        for child in children {
            child.parent = self
        }
    }
    
    // Helper computed properties
    var isDirectory: Bool {
        type == .directory
    }
    
    var fileExtension: String? {
        guard type == .file else { return nil }
        let components = name.split(separator: ".")
        return components.count > 1 ? String(components.last!) : nil
    }
    
    var depth: Int {
        var count = 0
        var current = parent
        while current != nil {
            count += 1
            current = current?.parent
        }
        return count
    }
}

// MARK: - File Type
enum FileType: String, Codable {
    case file
    case directory
    case symlink
    
    var icon: String {
        switch self {
        case .file: return "doc"
        case .directory: return "folder"
        case .symlink: return "link"
        }
    }
}

// MARK: - File Operations Result
struct FileOperationResult {
    let success: Bool
    let message: String?
    let affectedPaths: [String]
}