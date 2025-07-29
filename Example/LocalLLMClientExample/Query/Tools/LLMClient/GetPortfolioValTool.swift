import Foundation
import LocalLLMClient
import LocalLLMClientMacros

private func effectiveFilter(_ value: String?) -> String? {
    return (value == "all") ? nil : value
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

        var result: [String: Any] = [:]
        if let summary = arguments.summary?.lowercased() {
            switch summary {
            case "highest":
                if let maxPV = filtered.max(by: { $0.marketValue < $1.marketValue }) {
                    print("[GetPortfolioValTool] highest found: \(maxPV)")
                    result = ["type": "highest", "portfolio_value": maxPV]
                }
            case "lowest":
                if let minPV = filtered.min(by: { $0.marketValue < $1.marketValue }) {
                    print("[GetPortfolioValTool] lowest found: \(minPV)")
                    result = ["type": "lowest", "portfolio_value": minPV]
                }
            case "trend":
                let points = filtered
                    .sorted(by: { $0.valueDate < $1.valueDate })
                    .map { ["date": $0.valueDate, "marketValue": $0.marketValue] }
                print("[GetPortfolioValTool] trend points count: \(points.count)")
                result = ["type": "trend", "points": points]
            case "latest":
                print("[GetPortfolioValTool] 'latest' treated as raw data request")
                fallthrough
            default:
                result = ["portfolio_values": filtered]
            }
        } else {
            print("[GetPortfolioValTool] returning raw filtered data")
            result = ["portfolio_values": filtered]
        }

        cache.cacheToolCall(toolName: "GetPortfolioValTool", arguments: cacheArguments, result: result)

        return ToolOutput(data: result)
    }
}
