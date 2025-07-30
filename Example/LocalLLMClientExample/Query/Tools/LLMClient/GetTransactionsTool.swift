import Foundation
import LocalLLMClient
import LocalLLMClientMacros

private func effectiveFilter(_ value: String?) -> String? {
    return (value?.lowercased() == "all") ? nil : value
}

@Tool("get_transactions")
struct LocalLLMGetTransactionsTool {
    let description = "Retrieve and filter your transaction history by symbol (CUSIP), transaction type, account, date range, or amount."
    let transactionsProvider: @Sendable () -> [Transaction]
    private let cache = Cache.shared

    @ToolArguments
    struct Arguments {
        @ToolArgument("CUSIP or partial CUSIP of the security.")
        var cusip: String?
        @ToolArgument("Transaction type (e.g. 'BUY', 'SELL').")
        var transactiontype: String?
        @ToolArgument("Account name (e.g. 'Brokerage Account 1').")
        var account: String?
        @ToolArgument("Start date (YYYY-MM-DD, inclusive).")
        var startDate: String?
        @ToolArgument("End date (YYYY-MM-DD, inclusive).")
        var endDate: String?
        @ToolArgument("Minimum transaction amount.")
        var minTransactionAmt: Double?
        @ToolArgument("Maximum transaction amount.")
        var maxTransactionAmt: Double?
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        print("[GetTransactionsTool] called with arguments:")
        print("  cusip: \(arguments.cusip ?? "nil")")
        print("  transactiontype: \(arguments.transactiontype ?? "nil")")
        print("  account: \(arguments.account ?? "nil")")
        print("  startDate: \(arguments.startDate ?? "nil")")
        print("  endDate: \(arguments.endDate ?? "nil")")
        print("  minTransactionAmt: \(arguments.minTransactionAmt.map { String(describing: $0) } ?? "nil")")
        print("  maxTransactionAmt: \(arguments.maxTransactionAmt.map { String(describing: $0) } ?? "nil")")

        let cacheArguments: [String: Any?] = [
            "cusip": arguments.cusip,
            "transactiontype": arguments.transactiontype,
            "account": arguments.account,
            "startDate": arguments.startDate,
            "endDate": arguments.endDate,
            "minTransactionAmt": arguments.minTransactionAmt,
            "maxTransactionAmt": arguments.maxTransactionAmt
        ]
        
        // Check cache first
        if let cached = cache.getCachedToolCall(toolName: "GetTransactionsTool", arguments: cacheArguments) as? [String: Any] {
            print("[GetTransactionsTool] CACHE HIT - returning cached transactions.")
            return ToolOutput(data: cached)
        }

        let all = transactionsProvider()
        print("[GetTransactionsTool] total transactions: \(all.count)")

        let filtered = all.filter { txn in
            if let v = effectiveFilter(arguments.cusip), !txn.cusip.localizedCaseInsensitiveContains(v) { return false }
            if let v = effectiveFilter(arguments.transactiontype), !txn.transactiontype.localizedCaseInsensitiveContains(v) { return false }
            if let v = effectiveFilter(arguments.account), !txn.account.localizedCaseInsensitiveContains(v) { return false }
            if let start = effectiveFilter(arguments.startDate), txn.transactiondate < start { return false }
            if let end = effectiveFilter(arguments.endDate), txn.transactiondate > end { return false }
            if let minAmt = arguments.minTransactionAmt, txn.transactionamt < minAmt { return false }
            if let maxAmt = arguments.maxTransactionAmt, txn.transactionamt > maxAmt { return false }
            return true
        }

        print("[GetTransactionsTool] filtered transactions: \(filtered.count)")
        if filtered.isEmpty {
            print("[GetTransactionsTool] No transactions matched the filters.")
            let result = ["transactions": filtered, "formatted_output": "No transactions matched the filters."] as [String : Any]
            cache.cacheToolCall(toolName: "GetTransactionsTool", arguments: cacheArguments, result: result)
            return ToolOutput(data: result)
        }

        let formattedOutput = Compressor.processData(filtered)
        
        print("[GetTransactionsTool] Applied compression! original: \(filtered.count) transactions, compressed size: \(Compressor.estimateTokens(formattedOutput)) tokens")
        
        let result: [String: Any] = [
            "transactions": filtered,
            "formatted_output": formattedOutput
        ]

        // Log individual transactions for debugging
        for (i, txn) in filtered.enumerated() {
            print("[GetTransactionsTool] Matched #\(i + 1): \(txn)")
        }

        cache.cacheToolCall(toolName: "GetTransactionsTool", arguments: cacheArguments, result: result)

        return ToolOutput(data: result)
    }
}
