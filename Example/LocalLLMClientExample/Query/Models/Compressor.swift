//
//  DataCompressor.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/30/25.
//


struct Compressor {
    static let maxTokensPerResponse = 2000
    
    /// Estimate token count from text (rough approximation)
    static func estimateTokens(_ text: String) -> Int {
        return text.count / 4
    }
    
    /// Check if data needs compression
    static func shouldCompress(_ text: String) -> Bool {
        return estimateTokens(text) > maxTokensPerResponse
    }
    
    /// Adjust compression threshold dynamically
    static func shouldCompress(_ text: String, maxTokens: Int) -> Bool {
        return estimateTokens(text) > maxTokens
    }
}
