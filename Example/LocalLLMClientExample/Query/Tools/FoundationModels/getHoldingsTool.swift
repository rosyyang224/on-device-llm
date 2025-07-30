//
//  GetHoldingsTool.swift (with Cache + Compression)
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

struct HoldingsResponse: Codable {
    let holdings: [Holding]
    let count: Int
    let total_holdings: Int
}

struct FoundationModelsGetHoldingsTool: Tool {
    static var name: String = "get_holdings"
    let description = "Retrieve holdings, filterable by symbol, asset class, region, account type, profit/loss, or value."
    
    @Generable
    struct Arguments {
        @Guide(description: "The security symbol (e.g. 'AAPL').")
        let symbol: String?
        
        @Guide(description: "Asset class (e.g. 'Equity', 'Fixed Income').")
        let assetclass: String?
        
        @Guide(description: "Country or region (e.g. 'United States', 'Hong Kong').")
        let countryregion: String?
        
        @Guide(description: "Account type (e.g. 'Brokerage', 'Retirement').")
        let accounttype: String?
        
        @Guide(description: "Only holdings with profit/loss (in settlement currency) >= this value.")
        let min_marketplinsccy: Double?
        
        @Guide(description: "Only holdings with profit/loss (in settlement currency) <= this value.")
        let max_marketplinsccy: Double?
        
        @Guide(description: "Only holdings with market value (in base currency) >= this value.")
        let min_marketvalueinbccy: Double?
        
        @Guide(description: "Only holdings with market value (in base currency) <= this value.")
        let max_marketvalueinbccy: Double?
    }
    
    let holdingsProvider: @Sendable () -> [Holding]
    private let cache = Cache.shared
    
    init(holdingsProvider: @escaping @Sendable () -> [Holding]) {
        self.holdingsProvider = holdingsProvider
    }
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        print("[GetHoldingsTool] called with arguments:")
        print("  symbol: \(arguments.symbol ?? "nil")")
        print("  assetclass: \(arguments.assetclass ?? "nil")")
        print("  countryregion: \(arguments.countryregion ?? "nil")")
        print("  accounttype: \(arguments.accounttype ?? "nil")")
        print("  min_marketplinsccy: \(arguments.min_marketplinsccy.map { String(describing: $0) } ?? "nil")")
        print("  max_marketplinsccy: \(arguments.max_marketplinsccy.map { String(describing: $0) } ?? "nil")")
        print("  min_marketvalueinbccy: \(arguments.min_marketvalueinbccy.map { String(describing: $0) } ?? "nil")")
        print("  max_marketvalueinbccy: \(arguments.max_marketvalueinbccy.map { String(describing: $0) } ?? "nil")")

        // Create cache key from arguments
        let cacheArguments: [String: Any?] = [
            "symbol": arguments.symbol,
            "assetclass": arguments.assetclass,
            "countryregion": arguments.countryregion,
            "accounttype": arguments.accounttype,
            "min_marketplinsccy": arguments.min_marketplinsccy,
            "max_marketplinsccy": arguments.max_marketplinsccy,
            "min_marketvalueinbccy": arguments.min_marketvalueinbccy,
            "max_marketvalueinbccy": arguments.max_marketvalueinbccy
        ]
        
        // Check cache first - look for the actual filtered results based on tool arguments
        if let cachedResults = cache.getCachedToolCall(toolName: "GetHoldingsTool", arguments: cacheArguments) as? String {
            print("[GetHoldingsTool] CACHE HIT - returning cached results")
            return cachedResults
        }

        print("[GetHoldingsTool] CACHE MISS - executing tool logic")
        
        let all = holdingsProvider()
        print("[GetHoldingsTool] total holdings: \(all.count)")

        let filtered = all.filter { h in
            if let v = effectiveFilter(arguments.symbol), !h.symbol.localizedCaseInsensitiveContains(v) { return false }
            if let v = effectiveFilter(arguments.assetclass), !h.assetclass.localizedCaseInsensitiveContains(v) { return false }
            if let v = effectiveFilter(arguments.countryregion), !h.countryregion.localizedCaseInsensitiveContains(v) { return false }
            if let v = effectiveFilter(arguments.accounttype), !h.accounttype.localizedCaseInsensitiveContains(v) { return false }
            if let minPL = arguments.min_marketplinsccy, h.marketplinsccy < minPL { return false }
            if let maxPL = arguments.max_marketplinsccy, h.marketplinsccy > maxPL { return false }
            if let minVal = arguments.min_marketvalueinbccy, h.marketvalueinbccy < minVal { return false }
            if let maxVal = arguments.max_marketvalueinbccy, h.marketvalueinbccy > maxVal { return false }
            return true
        }

        print("[GetHoldingsTool] filtered holdings: \(filtered.count)")
        if filtered.isEmpty {
            print("[GetHoldingsTool] No holdings matched the filters.")
            let emptyResult = "No holdings found matching the specified filters."
            
            // Cache the empty result
            cache.cacheToolCall(toolName: "GetHoldingsTool", arguments: cacheArguments, result: emptyResult)
            return emptyResult
        }

        let processedResult = Compressor.processData(filtered, customCompressionThreshold: Compressor.CompressionConfig.aggressive.maxTokens)
        print("[GetHoldingsTool] Applied compression! original: \(filtered.count) holdings, compressed size: \(Compressor.estimateTokens(processedResult)) tokens")
        
        cache.cacheToolCall(toolName: "GetHoldingsTool", arguments: cacheArguments, result: processedResult)
        
        return processedResult
    }
}

func getHoldingsTool(isSessionStart: Bool = false) -> FoundationModelsGetHoldingsTool {
    guard let container = loadMockDataContainer(from: mockData) else {
        return FoundationModelsGetHoldingsTool { [] }
    }
    
    return FoundationModelsGetHoldingsTool(holdingsProvider: { container.holdings })
}
