//
//  CacheManager.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-08.
//

import Foundation

/// Simple in-memory cache manager for the app
final class CacheManager {
    static let shared = CacheManager()
    
    private var cache: [String: (data: Any, expiry: Date)] = [:]
    private let queue = DispatchQueue(label: "com.claudecodeui.cache", attributes: .concurrent)
    
    private init() {}
    
    func store<T>(_ object: T, forKey key: String, expiresIn seconds: TimeInterval = 300) {
        queue.async(flags: .barrier) {
            let expiry = Date().addingTimeInterval(seconds)
            self.cache[key] = (object, expiry)
        }
    }
    
    func retrieve<T>(forKey key: String) -> T? {
        queue.sync {
            guard let entry = cache[key],
                  entry.expiry > Date(),
                  let value = entry.data as? T else {
                return nil
            }
            return value
        }
    }
    
    func remove(forKey key: String) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }
    
    func clearAll() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
    
    func clearExpired() {
        queue.async(flags: .barrier) {
            let now = Date()
            self.cache = self.cache.filter { $0.value.expiry > now }
        }
    }
}