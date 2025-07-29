//
//  Cache.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/29/25.
//

import Foundation

@MainActor
final class Cache{
    static let shared = Cache()
    
    // Simple in-memory caches
    private var responseCache: [String: String] = [:]
    private var contextCache: [String: Any] = [:]
    private var recentQueries: [String] = []
    
    // Cache limits to prevent memory bloat
    private let maxCacheSize = 100
    private let maxRecentQueries = 20
    
    private init() {}
    
    // MARK: - Response Caching
    
    /// Cache a response for a given query
    func cacheResponse(_ response: String, for query: String) {
        let key = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        responseCache[key] = response
        
        // Add to recent queries
        if !recentQueries.contains(key) {
            recentQueries.insert(key, at: 0)
            if recentQueries.count > maxRecentQueries {
                recentQueries = Array(recentQueries.prefix(maxRecentQueries))
            }
        }
        
        // Trim cache if too large
        if responseCache.count > maxCacheSize {
            trimCache()
        }
    }
    
    /// Get cached response for a query
    func getCachedResponse(for query: String) -> String? {
        let key = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return responseCache[key]
    }
    
    /// Check if we have a cached response
    func hasCachedResponse(for query: String) -> Bool {
        let key = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return responseCache[key] != nil
    }
    
    // MARK: - Context Caching (for FoundationModels)
    
    /// Cache session context to avoid recreation
    func cacheContext(_ context: Any, key: String) {
        contextCache[key] = context
    }
    
    /// Get cached context
    func getCachedContext(key: String) -> Any? {
        return contextCache[key]
    }
    
    // MARK: - Recent Queries
    
    /// Get recent queries for autocomplete/suggestions
    func getRecentQueries() -> [String] {
        return recentQueries
    }
    
    /// Get query suggestions based on partial input
    func getQuerySuggestions(for partial: String) -> [String] {
        let lowercasePartial = partial.lowercased()
        return recentQueries.filter { $0.contains(lowercasePartial) }
    }
    
    // MARK: - Cache Management
    
    /// Clear all caches
    func clearCache() {
        responseCache.removeAll()
        contextCache.removeAll()
        recentQueries.removeAll()
    }
    
    /// Clear only response cache
    func clearResponseCache() {
        responseCache.removeAll()
    }
    
    /// Clear only context cache
    func clearContextCache() {
        contextCache.removeAll()
    }
    
    /// Get cache statistics
    func getCacheStats() -> (responses: Int, contexts: Int, recent: Int) {
        return (responseCache.count, contextCache.count, recentQueries.count)
    }
    
    // MARK: - Private Methods
    
    private func trimCache() {
        // Remove oldest entries to keep cache size manageable
        let sortedKeys = responseCache.keys.sorted()
        let keysToRemove = sortedKeys.prefix(responseCache.count - maxCacheSize + 10)
        
        for key in keysToRemove {
            responseCache.removeValue(forKey: key)
        }
    }
}
