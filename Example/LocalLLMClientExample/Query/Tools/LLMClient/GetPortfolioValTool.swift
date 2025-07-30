import Foundation
import LocalLLMClient
import LocalLLMClientMacros

private func effectiveFilter(_ value: String?) -> String? {
    return (value?.lowercased() == "all") ? nil : value
}

@Tool("get_portfolio_value")
struct LocalLLMGetPortfolioValTool {
    let description = "Query your portfolio value snapshots. Filter by date range or index, or retrieve summary statistics like highest, lowest, and trend over time."
    let portfolioValProvider: @Sendable () -> [PortfolioValue]
    private let cache = Cache.shared

    @ToolArguments
    struct Arguments {
        @ToolArgument("Start date (inclusive, format YYYY-MM-DD).")
        var startDate: String?
        @ToolArgument("End date (inclusive, format YYYY-MM-DD).")
        var endDate: String?
        @ToolArgument("Filter for a specific market index (e.g. 'S&P 500').")
        var index: String?
        @ToolArgument("Return summary: 'highest', 'lowest', 'trend', or leave blank for raw results.")
        var summary: String?
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        print("[GetPortfolioValTool] called with arguments:")
        print("  startDate: \(arguments.startDate ?? "nil")")
        print("  endDate: \(arguments.endDate ?? "nil")")
        print("  index: \(arguments.index ?? "nil")")
        print("  summary: \(arguments.summary ?? "nil")")

        let cacheArguments: [String: Any?] = [
            "startDate": arguments.startDate,
            "endDate": arguments.endDate,
            "index": arguments.index,
            "summary": arguments.summary
        ]
        
        // Check cache first
        if let cached = cache.getCachedToolCall(toolName: "GetPortfolioValTool", arguments: cacheArguments) as? [String: Any] {
            print("[GetPortfolioValTool] CACHE HIT - returning cached result.")
            return ToolOutput(data: cached)
        }

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

        // Handle summary requests first
        if let summary = arguments.summary?.lowercased() {
            var result: [String: Any] = [:]
            var formattedOutput = ""
            
            switch summary {
            case "highest":
                if let maxPV = filtered.max(by: { $0.marketValue < $1.marketValue }) {
                    print("[GetPortfolioValTool] highest found: \(maxPV)")
                    let formattedOutput = Compressor.processData(maxPV)
                    result = [
                        "type": "highest",
                        "portfolio_value": maxPV,
                        "formatted_output": formattedOutput
                    ]
                }
            case "lowest":
                if let minPV = filtered.min(by: { $0.marketValue < $1.marketValue }) {
                    print("[GetPortfolioValTool] lowest found: \(minPV)")
                    let formattedOutput = Compressor.processData(minPV)
                    result = [
                        "type": "lowest",
                        "portfolio_value": minPV,
                        "formatted_output": formattedOutput
                    ]
                }
            case "trend":
                let points = filtered
                    .sorted(by: { $0.valueDate < $1.valueDate })
                    .map { ["date": $0.valueDate, "marketValue": $0.marketValue] }
                print("[GetPortfolioValTool] trend points count: \(points.count)")
                
                // Format as string first, then compress
                let trendString = points.map { point in
                    let date = point["date"] as? String ?? "Unknown"
                    let value = point["marketValue"] as? Double ?? 0.0
                    return "\(date): $\(String(format: "%.2f", value))"
                }.joined(separator: "\n")
                
                let fullTrendOutput = "Portfolio Value Trend:\n" + trendString
                let formattedOutput = Compressor.processData(fullTrendOutput)
                
                print("[GetPortfolioValTool] Applied compression! original: \(points.count) trend points")
                print("[GetPortfolioValTool] Formatted output:")
                print(formattedOutput)
                
                result = [
                    "type": "trend",
                    "points": points,
                    "formatted_output": formattedOutput
                ]
            case "latest":
                print("[GetPortfolioValTool] 'latest' treated as raw data request")
                fallthrough
            default:
                // Handle as regular portfolio values with compression
                return try await handleRegularPortfolioValues(filtered: filtered, arguments: arguments, cacheArguments: cacheArguments)
            }
            
            cache.cacheToolCall(toolName: "GetPortfolioValTool", arguments: cacheArguments, result: result)
            return ToolOutput(data: result)
        } else {
            // Handle regular portfolio values request
            return try await handleRegularPortfolioValues(filtered: filtered, arguments: arguments, cacheArguments: cacheArguments)
        }
    }
    
    private func handleRegularPortfolioValues(
        filtered: [PortfolioValue],
        arguments: Arguments,
        cacheArguments: [String: Any?]
    ) async throws -> ToolOutput {
        
        if filtered.isEmpty {
            let result = ["portfolio_values": filtered, "formatted_output": "No portfolio values found for the specified criteria."] as [String : Any]
            cache.cacheToolCall(toolName: "GetPortfolioValTool", arguments: cacheArguments, result: result)
            return ToolOutput(data: result)
        }
        
        let formattedOutput = Compressor.processData(filtered)
        print("[GetPortfolioValTool] Applied compression! original: \(filtered.count) portfolio values, compressed size: \(Compressor.estimateTokens(formattedOutput)) tokens")
        
        let result: [String: Any] = [
            "portfolio_values": filtered,
            "formatted_output": formattedOutput
        ]

        cache.cacheToolCall(toolName: "GetPortfolioValTool", arguments: cacheArguments, result: result)
        return ToolOutput(data: result)
    }
}
