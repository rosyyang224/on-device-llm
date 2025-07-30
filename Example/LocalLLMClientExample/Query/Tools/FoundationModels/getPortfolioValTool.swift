//
//  GetPortfolioValTool.swift (with Cache + Compression)
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/17/25.
//  Enhanced with caching by Assistant on 7/29/25.
//  Enhanced with compression by Assistant on 7/30/25.
//

import Foundation
import FoundationModels

private func effectiveFilter(_ value: String?) -> String? {
    return (value == "all") ? nil : value
}

struct TrendPoint: Codable {
    let date: String
    let marketValue: Double
}

struct PortfolioValResponse: Codable {
    let portfolio_values: [PortfolioValue]?
    let type: String?
    let portfolio_value: PortfolioValue?
    let points: [TrendPoint]?
}

struct FoundationModelsGetPortfolioValTool: Tool {
    static var name: String = "get_portfolio_value"
    let description = "Query your portfolio value snapshots. Filter by date range or index, or retrieve summary statistics like highest, lowest, and trend over time."
    
    @Generable
    struct Arguments {
        @Guide(description: "Start date (inclusive, format YYYY-MM-DD).")
        let startDate: String?
        
        @Guide(description: "End date (inclusive, format YYYY-MM-DD).")
        let endDate: String?
        
        @Guide(description: "Filter for a specific market index (e.g. 'S&P 500').")
        let index: String?
        
        @Guide(description: "Return summary: 'highest', 'lowest', 'trend', or leave blank for raw results.")
        let summary: String?
    }
    
    let portfolioValProvider: @Sendable () -> [PortfolioValue]
    private let cache = Cache.shared
    
    init(portfolioValProvider: @escaping @Sendable () -> [PortfolioValue]) {
        self.portfolioValProvider = portfolioValProvider
    }
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        print("[GetPortfolioValTool] called with arguments:")
        print("  startDate: \(arguments.startDate ?? "nil")")
        print("  endDate: \(arguments.endDate ?? "nil")")
        print("  index: \(arguments.index ?? "nil")")
        print("  summary: \(arguments.summary ?? "nil")")

        // Create cache key from arguments
        let cacheArguments: [String: Any?] = [
            "startDate": arguments.startDate,
            "endDate": arguments.endDate,
            "index": arguments.index,
            "summary": arguments.summary
        ]
        
        // Check cache first - look for the actual results based on tool arguments
        if let cachedResults = cache.getCachedToolCall(toolName: "GetPortfolioValTool", arguments: cacheArguments) as? String {
            print("[GetPortfolioValTool] CACHE HIT - returning cached results")
            return cachedResults
        }

        print("[GetPortfolioValTool] CACHE MISS - executing tool logic")

        let all = portfolioValProvider()
        print("[GetPortfolioValTool] total portfolio values: \(all.count)")

        let filtered = all.filter { pv in
            if let idx = effectiveFilter(arguments.index), !pv.indices.contains(where: { $0.localizedCaseInsensitiveContains(idx) }) {
                return false
            }
            if let start = effectiveFilter(arguments.startDate), pv.valueDate < start {
                return false
            }
            if let end = effectiveFilter(arguments.endDate), pv.valueDate > end {
                return false
            }
            return true
        }

        print("[GetPortfolioValTool] filtered values count: \(filtered.count)")

        if filtered.isEmpty {
            print("[GetPortfolioValTool] No portfolio values matched the filters.")
            let emptyResult = "No portfolio values found matching the specified filters."
            
            // Cache the empty result
            cache.cacheToolCall(toolName: "GetPortfolioValTool", arguments: cacheArguments, result: emptyResult)
            return emptyResult
        }

        let processedResult = Compressor.processData(filtered, customCompressionThreshold: Compressor.CompressionConfig.aggressive.maxTokens)
        print("[GetPortfolioValTool] Applied compression! original: \(filtered.count) portfolio values, compressed size: \(Compressor.estimateTokens(processedResult)) tokens")
        
        // Cache the processed result
        cache.cacheToolCall(toolName: "GetPortfolioValTool", arguments: cacheArguments, result: processedResult)
        
        return processedResult
    }
}

func getPortfolioValTool(isSessionStart: Bool = false) -> FoundationModelsGetPortfolioValTool {
    guard let container = loadMockDataContainer(from: mockData) else {
        return FoundationModelsGetPortfolioValTool { [] }
    }
    
    return FoundationModelsGetPortfolioValTool(portfolioValProvider: { container.portfolio_value })
}
