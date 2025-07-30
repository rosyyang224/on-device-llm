import Foundation
import LocalLLMClient
import LocalLLMClientMacros

private func effectiveFilter(_ value: String?) -> String? {
    return (value?.lowercased() == "all") ? nil : value
}

@Tool("get_holdings")
struct LocalLLMGetHoldingsTool {
    let description = "Retrieve portfolio holdings, filterable by symbol, asset class, region, account type, profit/loss, or value."
    let holdingsProvider: @Sendable () -> [Holding]
    private let cache = Cache.shared

    @ToolArguments
    struct Arguments {
        @ToolArgument("The security symbol (e.g. 'AAPL').")
        var symbol: String?
        @ToolArgument("Asset class (e.g. 'Equity', 'Fixed Income').")
        var assetclass: String?
        @ToolArgument("Country or region (e.g. 'United States', 'Hong Kong').")
        var countryregion: String?
        @ToolArgument("Account type (e.g. 'Brokerage', 'Retirement').")
        var accounttype: String?
        @ToolArgument("Only holdings with profit/loss (in settlement currency) >= this value.")
        var min_marketplinsccy: Double?
        @ToolArgument("Only holdings with profit/loss (in settlement currency) <= this value.")
        var max_marketplinsccy: Double?
        @ToolArgument("Only holdings with market value (in base currency) >= this value.")
        var min_marketvalueinbccy: Double?
        @ToolArgument("Only holdings with market value (in base currency) <= this value.")
        var max_marketvalueinbccy: Double?
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        print("[GetHoldingsTool] called with arguments:")
        print("  symbol: \(arguments.symbol ?? "nil")")
        print("  assetclass: \(arguments.assetclass ?? "nil")")
        print("  countryregion: \(arguments.countryregion ?? "nil")")
        print("  accounttype: \(arguments.accounttype ?? "nil")")
        print("  min_marketplinsccy: \(arguments.min_marketplinsccy.map { String(describing: $0) } ?? "nil")")
        print("  max_marketplinsccy: \(arguments.max_marketplinsccy.map { String(describing: $0) } ?? "nil")")
        print("  min_marketvalueinbccy: \(arguments.min_marketvalueinbccy.map { String(describing: $0) } ?? "nil")")
        print("  max_marketvalueinbccy: \(arguments.max_marketvalueinbccy.map { String(describing: $0) } ?? "nil")")

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
        
        if let cached = cache.getCachedToolCall(toolName: "GetHoldingsTool", arguments: cacheArguments) as? [String: Any] {
            print("[GetHoldingsTool] CACHE HIT - returning cached holdings.")
            return ToolOutput(data: cached)
        }

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
            let result = ["holdings": filtered, "formatted_output": "No holdings matched the filters."] as [String : Any]
            cache.cacheToolCall(toolName: "GetHoldingsTool", arguments: cacheArguments, result: result)
            return ToolOutput(data: result)
        }

        // Use the existing smart compression logic
        let formattedOutput = Compressor.processData(filtered)
        print("[GetHoldingsTool] Applied compression! original: \(filtered.count) holdings, compressed size: \(Compressor.estimateTokens(formattedOutput)) tokens")
        
        let result: [String: Any] = [
            "holdings": filtered,
            "formatted_output": formattedOutput
        ]

        // Log individual holdings for debugging
        for (i, holding) in filtered.enumerated() {
            print("[GetHoldingsTool] Matched #\(i + 1): \(holding)")
        }

        cache.cacheToolCall(toolName: "GetHoldingsTool", arguments: cacheArguments, result: result)

        return ToolOutput(data: result)
    }
}
