//
//  ChatCache.swift
//  LocalLLMClientExample
//
//  Created by Assistant on 7/29/25.
//

import Foundation

final class Cache {
    static let shared = Cache()
    
    private var contextCache: [String: Any] = [:]
    private var toolCallCache: [String: Any] = [:]
    
    private let maxToolCalls = 50
    
    private let queue = DispatchQueue(label: "cache.queue", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Tool Call Caching
    
    /// Cache a tool call result
    func cacheToolCall(toolName: String, arguments: [String: Any?], result: Any) {
        queue.async(flags: .barrier) {
            let cacheKey = self.createToolCacheKey(toolName: toolName, arguments: arguments)
            self.toolCallCache[cacheKey] = result
            
            // Trim tool cache if too large
            if self.toolCallCache.count > self.maxToolCalls {
                self.trimToolCache()
            }
            
            let argString = self.formatArguments(arguments)
            print("TOOL CACHE: Stored result for [\(toolName)] with args: \(argString)")
        }
    }
    
    /// Get cached tool call result
    func getCachedToolCall(toolName: String, arguments: [String: Any?]) -> Any? {
        return queue.sync {
            let cacheKey = self.createToolCacheKey(toolName: toolName, arguments: arguments)
            
            if let cachedResult = self.toolCallCache[cacheKey] {
                let argString = self.formatArguments(arguments)
                print("TOOL CACHE HIT: Found result for [\(toolName)] with args: \(argString)")
                return cachedResult
            }
            
            let argString = self.formatArguments(arguments)
            print("❌ TOOL CACHE MISS: No result for [\(toolName)] with args: \(argString)")
            return nil
        }
    }
    
    /// Check if we have a cached tool call result
    func hasCachedToolCall(toolName: String, arguments: [String: Any?]) -> Bool {
        return queue.sync {
            let cacheKey = self.createToolCacheKey(toolName: toolName, arguments: arguments)
            return self.toolCallCache[cacheKey] != nil
        }
    }
    
    // MARK: - Tool Cache Helpers
    
    private func createToolCacheKey(toolName: String, arguments: [String: Any?]) -> String {
        // Create a stable key from tool name and arguments
        let sortedArgs = arguments.sorted { $0.key < $1.key }
        var keyComponents = [toolName]
        
        for (key, value) in sortedArgs {
            if let value = value {
                keyComponents.append("\(key):\(value)")
            } else {
                keyComponents.append("\(key):nil")
            }
        }
        
        return keyComponents.joined(separator: "|")
    }
    
    private func formatArguments(_ arguments: [String: Any?]) -> String {
        let sortedArgs = arguments.sorted { $0.key < $1.key }
        let argStrings = sortedArgs.map { key, value in
            if let value = value {
                return "\(key): \(value)"
            } else {
                return "\(key): nil"
            }
        }
        return argStrings.joined(separator: ", ")
    }
    
    private func trimToolCache() {
        let sortedKeys = toolCallCache.keys.sorted()
        let keysToRemove = sortedKeys.prefix(toolCallCache.count - maxToolCalls + 10)
        
        for key in keysToRemove {
            toolCallCache.removeValue(forKey: key)
        }
        print("TOOL CACHE: Trimmed cache to \(toolCallCache.count) items")
    }
    
    // MARK: - Context Caching (for FoundationModels)
    
    /// Cache session context to avoid recreation
    func cacheContext(_ context: Any, key: String) {
        contextCache[key] = context
        print("CACHE: Stored context for key '\(key)'")
    }
    
    /// Get cached context
    func getCachedContext(key: String) -> Any? {
        if let context = contextCache[key] {
            print("CACHE HIT: Found context for key '\(key)'")
            return context
        }
        print("CACHE MISS: No context for key '\(key)'")
        return nil
    }
    
    // MARK: - Cache Management
    
    /// Clear all caches
    func clearCache() {
        queue.async(flags: .barrier) {
            self.contextCache.removeAll()
            self.toolCallCache.removeAll()
            print("CACHE: Cleared all caches")
        }
    }
    
    /// Clear only context cache
    func clearContextCache() {
        queue.async(flags: .barrier) {
            self.contextCache.removeAll()
            print("CACHE: Cleared context cache")
        }
    }
    
    /// Clear only tool call cache
    func clearToolCache() {
        queue.async(flags: .barrier) {
            self.toolCallCache.removeAll()
            print("CACHE: Cleared tool call cache")
        }
    }
    
    /// Get cache statistics
    func getCacheStats() -> (contexts: Int, tools: Int) {
        return queue.sync {
            let stats = (contexts: self.contextCache.count, tools: self.toolCallCache.count)
            print("CACHE STATS: \(stats.contexts) contexts, \(stats.tools) tools")
            return stats
        }
    }
}
