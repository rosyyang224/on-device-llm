import Foundation

// MARK: - Centralized Compression Config (with presets)
extension Compressor {
    /// One place to tune compression behavior. All compressors read from this.
    struct CompressionConfig {
        // Token budgeting
        var maxTokens: Int = 2000
        var charsPerTokenHeuristic: Int = 4   // rough; swap with real tokenizer later

        // Holdings
        var topHoldingsCount: Int = 10
        var notableOtherHoldingsCount: Int = 5

        // Transactions
        var recentTransactionsCount: Int = 20
        var transactionTypeTopCount: Int = 5
        var symbolTopCount: Int = 7

        // Portfolio series
        var keepLastTrendPoints: Int = 12
        var includeArrays: Bool = true        // dates/values/changes/ytd arrays
        var includeStats: Bool = true         // summary dict (min/max/mean/volatility/etc.)
        var roundDecimals: Int = 0            // 0 for ints in arrays

        // Presets
        static let `default` = CompressionConfig()

        static let aggressive = CompressionConfig(
            maxTokens: 800,
            charsPerTokenHeuristic: 4,
            topHoldingsCount: 5,
            notableOtherHoldingsCount: 3,
            recentTransactionsCount: 10,
            transactionTypeTopCount: 4,
            symbolTopCount: 5,
            keepLastTrendPoints: 6,
            includeArrays: true,
            includeStats: true,
            roundDecimals: 0
        )

        static let detailed = CompressionConfig(
            maxTokens: 4000,
            charsPerTokenHeuristic: 4,
            topHoldingsCount: 15,
            notableOtherHoldingsCount: 8,
            recentTransactionsCount: 30,
            transactionTypeTopCount: 8,
            symbolTopCount: 10,
            keepLastTrendPoints: 24,
            includeArrays: true,
            includeStats: true,
            roundDecimals: 2
        )
    }
}

// MARK: - Token helpers (shared)
extension Compressor {
    /// Heuristic token estimator; replace later with a real tokenizer without changing call sites.
    static func estimateTokens(_ text: String, charsPerToken: Int = CompressionConfig.default.charsPerTokenHeuristic) -> Int {
        max(1, text.utf8.count / max(1, charsPerToken))
    }

    static func shouldCompress(_ text: String, maxTokens: Int, charsPerToken: Int = CompressionConfig.default.charsPerTokenHeuristic) -> Bool {
        estimateTokens(text, charsPerToken: charsPerToken) > maxTokens
    }

    /// Generic budget clamp that preserves some structure: squashes blanks, keeps head+tail, then hard clips to budget.
    static func compressToBudget(_ text: String, config: CompressionConfig) -> String {
        guard shouldCompress(text, maxTokens: config.maxTokens, charsPerToken: config.charsPerTokenHeuristic) else { return text }

        // Pass 1: collapse excess blank lines
        var s = text.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)

        if !shouldCompress(s, maxTokens: config.maxTokens, charsPerToken: config.charsPerTokenHeuristic) { return s }

        // Pass 2: head/tail preservation (keep early context + recent tail)
        let lines = s.split(separator: "\n", omittingEmptySubsequences: false)
        if lines.count > 120 {
            let head = lines.prefix(60)
            let tail = lines.suffix(60)
            s = (head + ["… (trimmed) …"] + tail).joined(separator: "\n")
        }

        if !shouldCompress(s, maxTokens: config.maxTokens, charsPerToken: config.charsPerTokenHeuristic) { return s }

        // Pass 3: hard clip by approximate char budget (tokens * charsPerToken)
        let targetChars = max(200, config.maxTokens * max(1, config.charsPerTokenHeuristic))
        if s.utf8.count > targetChars {
            let headChars = Int(Double(targetChars) * 0.85)
            let tailChars = targetChars - headChars
            let headStr = String(s.prefix(headChars))
            let tailStr = String(s.suffix(tailChars))
            s = headStr + "\n… (hard clipped) …\n" + tailStr
        }
        return s
    }
}

// MARK: - Holdings Compression
extension Compressor {

    /// Compress holdings data to show top performers + summary of rest (config-aware)
    static func compressHoldings(_ holdings: [Holding], config: CompressionConfig = .default) -> String {
        guard !holdings.isEmpty else { return "No holdings found." }

        let sorted = holdings.sorted { $0.totalmarketvalue > $1.totalmarketvalue }
        let totalValue = holdings.reduce(0) { $0 + $1.totalmarketvalue }

        let topCount = min(config.topHoldingsCount, holdings.count)
        let top = Array(sorted.prefix(topCount))
        let remaining = Array(sorted.dropFirst(topCount))

        var result = "=== TOP \(topCount) HOLDINGS ===\n"
        for (index, holding) in top.enumerated() {
            let percentage = totalValue == 0 ? 0 : (holding.totalmarketvalue / totalValue) * 100
            let pnl = holding.totalmarketvalue - holding.totalcostinbccy
            let pnlPercent = holding.marketplpercentinsccy

            result += "\(index + 1). \(holding.symbol) (\(holding.assetclass))\n"
            result += "   Value: $\(String(format: "%.2f", holding.totalmarketvalue)) (\(String(format: "%.1f", percentage))%)\n"
            result += "   P&L: $\(String(format: "%.2f", pnl)) (\(String(format: "%.1f", pnlPercent))%)\n"
            result += "   Price: $\(String(format: "%.2f", holding.marketpricesccy)) | Region: \(holding.countryregion)\n\n"
        }

        if !remaining.isEmpty {
            let remainingValue = remaining.reduce(0) { $0 + $1.totalmarketvalue }
            let remainingPercentage = totalValue == 0 ? 0 : (remainingValue / totalValue) * 100
            result += "=== OTHER HOLDINGS ===\n"
            result += "\(remaining.count) positions: $\(String(format: "%.2f", remainingValue)) (\(String(format: "%.1f", remainingPercentage))%)\n"

            let notableCount = min(config.notableOtherHoldingsCount, remaining.count)
            if notableCount > 0 {
                let topRemaining = Array(remaining.prefix(notableCount))
                if !topRemaining.isEmpty {
                    let list = topRemaining.map { "\($0.symbol) $\(String(format: "%.0f", $0.totalmarketvalue))" }.joined(separator: ", ")
                    result += "Notable others: \(list)\n"
                }
            }

            let assetClasses = Dictionary(grouping: remaining) { $0.assetclass }
            let assetSummary = assetClasses.mapValues { hs in
                hs.reduce(0) { $0 + $1.totalmarketvalue }
            }.sorted { $0.value > $1.value }
            if !assetSummary.isEmpty {
                result += "By asset class: \(assetSummary.map { "\($0.key) $\(String(format: "%.0f", $0.value))" }.joined(separator: ", "))\n"
            }
        }

        return compressToBudget(result, config: config)
    }

    static func formatHoldings(_ holdings: [Holding]) -> String {
        guard !holdings.isEmpty else { return "No holdings found." }
        return holdings.map { h in
            let pnl = h.totalmarketvalue - h.totalcostinbccy
            return """
            Symbol: \(h.symbol) | Asset Class: \(h.assetclass)
            Market Value: $\(String(format: "%.2f", h.totalmarketvalue))
            Market Price: $\(String(format: "%.2f", h.marketpricesccy))
            P&L: $\(String(format: "%.2f", pnl)) (\(String(format: "%.2f", h.marketplpercentinsccy))%)
            Region: \(h.countryregion) | Account: \(h.accounttype)
            """
        }.joined(separator: "\n\n")
    }
}

// MARK: - Transactions Compression
extension Compressor {

    /// Compress transactions to show recent activity + summary patterns (config-aware)
    static func compressTransactions(_ transactions: [Transaction], config: CompressionConfig = .default) -> String {
        guard !transactions.isEmpty else { return "No transactions found." }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let sortedByDate = transactions.sorted {
            (df.date(from: $0.transactiondate) ?? .distantPast) >
            (df.date(from: $1.transactiondate) ?? .distantPast)
        }

        let recentCount = min(config.recentTransactionsCount, transactions.count)
        let recent = Array(sortedByDate.prefix(recentCount))

        var result = "=== RECENT ACTIVITY (Last \(recentCount)) ===\n"
        for t in recent {
            let amt = Swift.abs(t.transactionamt)
            result += "\(t.transactiondate): \(t.transactiontypedesc) | \(t.description) | $\(String(format: "%.2f", amt))\n"
        }
        result += "\n"

        // Transaction type analysis
        let typeGroups = Dictionary(grouping: transactions) { $0.transactiontypedesc }
        let typeSummary = typeGroups.mapValues { txs -> (count: Int, amount: Double) in
            let amount = txs.reduce(0) { $0 + Swift.abs($1.transactionamt) }
            return (txs.count, amount)
        }.sorted { $0.value.amount > $1.value.amount }

        result += "Transaction Types:\n"
        for (type, summary) in typeSummary.prefix(config.transactionTypeTopCount) {
            result += "  \(type): \(summary.count) | Total: $\(String(format: "%.0f", summary.amount))\n"
        }

        // Symbol activity (by description)
        let symbolGroups = Dictionary(grouping: transactions) { $0.description }
        let symbolSummary = symbolGroups.mapValues { txs in
            txs.reduce(0) { $0 + Swift.abs($1.transactionamt) }
        }.sorted { $0.value > $1.value }

        result += "Most Active Securities:\n"
        for (symbol, volume) in symbolSummary.prefix(config.symbolTopCount) {
            let count = symbolGroups[symbol]?.count ?? 0
            result += "  \(symbol): \(count) trades | Volume: $\(String(format: "%.0f", volume))\n"
        }

        // Costs
        let totalCommissions = transactions.reduce(0) { $0 + $1.commission }
        let totalTaxes = transactions.reduce(0) { $0 + $1.taxwithheld }
        let totalVolume = transactions.reduce(0) { $0 + Swift.abs($1.transactionamt) }

        let commissions = String(format: "%.2f", totalCommissions)
        let taxes = String(format: "%.2f", totalTaxes)
        let volume = String(format: "%.2f", totalVolume)
        result += "Costs: commissions $\(commissions), taxes $\(taxes), volume $\(volume)\n"

        return compressToBudget(result, config: config)
    }

    static func formatTransactions(_ transactions: [Transaction]) -> String {
        guard !transactions.isEmpty else { return "No transactions found." }
        return transactions.map { t in
            let amt = Swift.abs(t.transactionamt)
            return "\(t.transactiondate): \(t.transactiontypedesc) | \(t.description) | $\(String(format: "%.2f", amt))"
        }.joined(separator: "\n")
    }
}

// MARK: - Portfolio Value Compression
extension Compressor {

    /// Compact array-style summary for multiple portfolio values (config-aware, token-budgeted)
    static func compressPortfolioSeriesArrays(_ series: [PortfolioValue],
                                              config: CompressionConfig = .default) -> String {
        guard !series.isEmpty else { return "No portfolio values." }

        let sorted = series.sorted { $0.valueDate < $1.valueDate }
        let tail = Array(sorted.suffix(config.keepLastTrendPoints))

        // Arrays (rounded)
        func roundValue(_ v: Double, _ dp: Int) -> Double {
            let factor = pow(10.0, Double(dp))
            return Double(round(v * factor) / factor)
        }

        let dates = tail.map { $0.valueDate }
        let values = tail.map { roundValue($0.marketValue, config.roundDecimals) }
        let changes = tail.map { roundValue($0.marketChange, config.roundDecimals) }
        let ytds = tail.map { roundValue($0.yearToDateRateOfReturnCumulative, 2) }

        // Stats
        let startV = tail.first!.marketValue
        let endV = tail.last!.marketValue
        let deltaAbs = endV - startV
        let deltaPct = startV == 0 ? 0 : (deltaAbs / startV) * 100.0

        let minIdx = values.enumerated().min(by: { $0.element < $1.element })!.offset
        let maxIdx = values.enumerated().max(by: { $0.element < $1.element })!.offset
        let minV = values[minIdx], maxV = values[maxIdx]
        let minD = dates[minIdx], maxD = dates[maxIdx]

        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0, { $0 + pow($1 - mean, 2) }) / Double(values.count)
        let stdev = sqrt(variance)
        let volPct = mean == 0 ? 0 : (stdev / mean) * 100.0

        let ytdDelta = tail.last!.yearToDateRateOfReturnCumulative - tail.first!.yearToDateRateOfReturnCumulative

        var out = "=== PORTFOLIO TREND (last \(tail.count)) ===\n"

        if config.includeArrays {
            out += "dates: \(dates)\n"
            out += "values: \(values)\n"
            out += "changes: \(changes)\n"
            out += "ytd: \(ytds)\n"
        }

        if config.includeStats {
            out += "summary: { "
            out += "start: \(Int(startV)), "
            out += "end: \(Int(endV)), "
            out += "delta: \(Int(deltaAbs)), "
            out += "delta_pct: \(String(format: "%.2f", deltaPct))%, "
            out += "min: \(Int(minV))@\(minD), "
            out += "max: \(Int(maxV))@\(maxD), "
            out += "mean: \(Int(mean)), "
            out += "stdev: \(Int(stdev)), "
            out += "volatility_pct: \(String(format: "%.2f", volPct))%, "
            out += "ytd_delta: \(String(format: "%.2f", ytdDelta))% "
            out += "}\n"
        }

        return compressToBudget(out, config: config)
    }

    /// Compact single-snapshot (still passes through budget clamp)
    static func compressPortfolioValue(_ p: PortfolioValue, config: CompressionConfig = .default) -> String {
        let base = """
        Portfolio Value: $\(String(format: "%.2f", p.marketValue))
        Market Change: $\(String(format: "%.2f", p.marketChange))
        YTD Return: \(String(format: "%.2f", p.yearToDateRateOfReturnCumulative))%
        Net ARR: \(String(format: "%.2f", p.netARR))% | Cumulative ARR: \(String(format: "%.2f", p.cumulativeARR))%
        Value Date: \(p.valueDate)
        """
        return compressToBudget(base, config: config)
    }

    /// Verbose formatter (unchanged)
    static func formatPortfolioValue(_ p: PortfolioValue) -> String {
        return """
        Client ID: \(p.clientID)
        Market Value: $\(String(format: "%.2f", p.marketValue))
        Market Change: $\(String(format: "%.2f", p.marketChange))
        Value Date: \(p.valueDate)

        Performance Metrics:
        Year-to-Date Rate of Return (Cumulative): \(String(format: "%.2f", p.yearToDateRateOfReturnCumulative))%
        Year-to-Date Return: \(String(format: "%.2f", p.yearToDateOfReturn))%
        Net ARR: \(String(format: "%.2f", p.netARR))%
        Cumulative ARR: \(String(format: "%.2f", p.cumulativeARR))%

        Contribution and Withdrawals: $\(String(format: "%.2f", p.contributionAndWithdraw))
        Growth Cumulative Value Date: \(p.growthCumulativeValueDate)
        Indices: \(p.indices.joined(separator: ", "))
        """
    }
}

// MARK: - Generic Compression for Unknown Data Types
extension Compressor {
    /// Generic compression if you hand it a big text blob directly (config-aware).
    static func genericCompress(_ text: String, config: CompressionConfig = .default) -> String {
        compressToBudget(text, config: config)
    }
}

// MARK: - Entry Points / Integration Helpers
extension Compressor {

    /// Dynamic, config-aware processing for known data shapes.
    static func processData<T>(_ data: T, config: CompressionConfig = .default) -> String {
        switch data {
        case let holdings as [Holding]:
            let verbose = formatHoldings(holdings)
            return shouldCompress(verbose, maxTokens: config.maxTokens, charsPerToken: config.charsPerTokenHeuristic)
                ? compressHoldings(holdings, config: config)
                : verbose

        case let transactions as [Transaction]:
            let verbose = formatTransactions(transactions)
            return shouldCompress(verbose, maxTokens: config.maxTokens, charsPerToken: config.charsPerTokenHeuristic)
                ? compressTransactions(transactions, config: config)
                : verbose

        case let portfolio as PortfolioValue:
            let verbose = formatPortfolioValue(portfolio)
            return shouldCompress(verbose, maxTokens: config.maxTokens, charsPerToken: config.charsPerTokenHeuristic)
                ? compressPortfolioValue(portfolio, config: config)
                : verbose

        case let series as [PortfolioValue]:
            // Always use compact array+summary for series (then clamp to budget)
            let compact = compressPortfolioSeriesArrays(series, config: config)
            return shouldCompress(compact, maxTokens: config.maxTokens, charsPerToken: config.charsPerTokenHeuristic)
                ? compressToBudget(compact, config: config)
                : compact

        default:
            let str = String(describing: data)
            return shouldCompress(str, maxTokens: config.maxTokens, charsPerToken: config.charsPerTokenHeuristic)
                ? compressToBudget(str, config: config)
                : str
        }
    }

    /// Back-compat: respect a custom token threshold while using the new config machinery.
    static func processData<T>(_ data: T, customCompressionThreshold: Int?) -> String {
        var cfg = CompressionConfig.default
        if let t = customCompressionThreshold { cfg.maxTokens = t }
        return processData(data, config: cfg)
    }
}
