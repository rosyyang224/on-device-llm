import Foundation

extension Compressor {
    static func estimateTokens(_ text: String, charsPerToken: Int) -> Int {
        max(1, text.utf8.count / max(1, charsPerToken))
    }
    static func overBudget(_ text: String, config: CompressionConfig) -> Bool {
        estimateTokens(text, charsPerToken: config.charsPerTokenHeuristic) > config.maxTokens
    }
    static func compressToBudget(_ text: String, config: CompressionConfig) -> String {
        guard overBudget(text, config: config) else { return text }
        var s = text.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
        guard overBudget(s, config: config) else { return s }
        let lines = s.split(separator: "\n", omittingEmptySubsequences: false)
        if lines.count > 120 {
            s = (lines.prefix(60) + ["… (trimmed) …"] + lines.suffix(60)).joined(separator: "\n")
        }
        guard overBudget(s, config: config) else { return s }
        let targetChars = max(200, config.maxTokens * max(1, config.charsPerTokenHeuristic))
        if s.utf8.count > targetChars {
            let head = Int(Double(targetChars) * 0.85)
            s = String(s.prefix(head)) + "\n… (hard clipped) …\n" + String(s.suffix(targetChars - head))
        }
        return s
    }

    static func compressHoldings(_ holdings: [Holding], config: CompressionConfig = .default) -> String {
        guard !holdings.isEmpty else { return "No holdings found." }
        let sorted = holdings.sorted { $0.totalmarketvalue > $1.totalmarketvalue }
        let total  = holdings.reduce(0) { $0 + $1.totalmarketvalue }
        let top    = Array(sorted.prefix(min(config.topHoldingsCount, holdings.count)))
        let rest   = Array(sorted.dropFirst(top.count))

        var out = "=== TOP \(top.count) HOLDINGS ===\n"
        for (i, h) in top.enumerated() {
            let pct = total == 0 ? 0 : (h.totalmarketvalue / total) * 100
            let pnl = h.totalmarketvalue - h.totalcostinbccy
            out += "\(i+1). \(h.symbol) (\(h.assetclass)) | Value \(Fmt.usd(h.totalmarketvalue)) (\(String(format:"%.1f", pct))%) | P&L \(Fmt.usd(pnl)) (\(String(format:"%.1f", h.marketplpercentinsccy))%) | Px \(Fmt.usd(h.marketpricesccy)) | \(h.countryregion)\n"
        }
        if !rest.isEmpty {
            let restVal = rest.reduce(0) { $0 + $1.totalmarketvalue }
            let restPct = total == 0 ? 0 : (restVal / total) * 100
            out += "\nOTHER: \(rest.count) positions, \(Fmt.usd(restVal)) (\(String(format:"%.1f", restPct))%)\n"
        }
        return compressToBudget(out, config: config)
    }

    static func compressTransactions(_ txs: [Transaction], config: CompressionConfig = .default) -> String {
        guard !txs.isEmpty else { return "No transactions found." }

        var result = ""
        
        // Sort by date (newest first)
        let sortedTxs = txs.sorted { tx1, tx2 in
            let date1 = Fmt.ymd.date(from: tx1.transactiondate) ?? Date.distantPast
            let date2 = Fmt.ymd.date(from: tx2.transactiondate) ?? Date.distantPast
            return date1 > date2
        }
        
        // Recent transactions
        let recentCount = min(config.recentTransactionsCount, txs.count)
        result += "=== RECENT (\(recentCount)) ===\n"
        
        for i in 0..<recentCount {
            let tx = sortedTxs[i]
            let amount = Swift.abs(tx.transactionamt)
            result += "\(tx.transactiondate): \(tx.transactiontypedesc) • \(tx.description) • \(Fmt.usd(amount))\n"
        }
        
        // Group by transaction type
        var typeGroups: [String: [Transaction]] = [:]
        for tx in txs {
            let type = tx.transactiontypedesc
            if typeGroups[type] == nil {
                typeGroups[type] = []
            }
            typeGroups[type]!.append(tx)
        }
        
        // Calculate totals for each type
        var typeTotals: [(String, Int, Double)] = []
        for (type, transactions) in typeGroups {
            let count = transactions.count
            var totalAmount = 0.0
            for tx in transactions {
                totalAmount += Swift.abs(tx.transactionamt)
            }
            typeTotals.append((type, count, totalAmount))
        }
        
        // Sort by amount (highest first)
        typeTotals.sort { first, second in
            return first.2 > second.2
        }
        
        // Add top transaction types
        if !typeTotals.isEmpty {
            result += "\nTypes: "
            let topCount = min(config.transactionTypeTopCount, typeTotals.count)
            for i in 0..<topCount {
                let (type, count, amount) = typeTotals[i]
                if i > 0 { result += ", " }
                result += "\(type)=\(count) (\(Fmt.int(amount)))"
            }
            result += "\n"
        }
        
        // Calculate costs
        var totalCommissions = 0.0
        var totalTaxes = 0.0
        for tx in txs {
            totalCommissions += tx.commission
            totalTaxes += tx.taxwithheld
        }
        
        result += "Costs: commissions \(Fmt.usd(totalCommissions)), taxes \(Fmt.usd(totalTaxes))\n"
        
        return compressToBudget(result, config: config)
    }

    static func compressPortfolioVals(_ series: [PortfolioValue], config: CompressionConfig = .default) -> String {
        guard !series.isEmpty else { return "No portfolio values." }
        let sorted = series.sorted { $0.valueDate < $1.valueDate }
        let tail   = Array(sorted.suffix(config.keepLastTrendPoints))
        let vals   = tail.map(\.marketValue)
        let startV = vals.first ?? 0, endV = vals.last ?? 0
        let delta  = endV - startV
        let deltaPct = startV == 0 ? 0 : (delta / startV) * 100

        let minV = vals.min() ?? 0, maxV = vals.max() ?? 0
        let mean = vals.reduce(0,+) / Double(max(vals.count,1))
        let variance = vals.reduce(0) { $0 + pow($1 - mean, 2) } / Double(max(vals.count,1))
        let stdev    = sqrt(variance)
        let volPct   = mean == 0 ? 0 : (stdev / mean) * 100

        var out = "=== PORTFOLIO TREND (last \(tail.count)) ===\n"
        if config.includeArrays {
            out += "dates: \(tail.map(\.valueDate))\n"
            out += "values: \(vals.map { round($0, config.roundDecimals) })\n"
        }
        if config.includeStats {
            out += "summary: { start: \(Fmt.int(startV)), end: \(Fmt.int(endV)), delta: \(Fmt.int(delta)), delta_pct: \(String(format:"%.2f", deltaPct))%, min: \(Fmt.int(minV)), max: \(Fmt.int(maxV)), mean: \(Fmt.int(mean)), stdev: \(Fmt.int(stdev)), volatility_pct: \(String(format:"%.2f", volPct))% }\n"
        }
        return compressToBudget(out, config: config)
    }

    static func processData<T>(_ data: T, config: CompressionConfig = .default) -> String {
        switch data {
        case let holdings as [Holding]:
            let verbose = holdings.isEmpty ? "No holdings found." : compressHoldings(holdings, config: config) // already compact
            return overBudget(verbose, config: config) ? compressToBudget(verbose, config: config) : verbose

        case let txs as [Transaction]:
            let verbose = txs.isEmpty ? "No transactions found." : compressTransactions(txs, config: config)
            return overBudget(verbose, config: config) ? compressToBudget(verbose, config: config) : verbose

        case let series as [PortfolioValue]:
            let compact = compressPortfolioVals(series, config: config)
            return overBudget(compact, config: config) ? compressToBudget(compact, config: config) : compact

        default:
            let s = String(describing: data)
            return overBudget(s, config: config) ? compressToBudget(s, config: config) : s
        }
    }

    static func processData<T>(_ data: T, customCompressionThreshold: Int?) -> String {
        var cfg = CompressionConfig.default
        if let t = customCompressionThreshold { cfg.maxTokens = t }
        return processData(data, config: cfg)
    }
}

private func round(_ v: Double, _ dp: Int) -> Double {
    guard dp > 0 else { return v.rounded() }
    let f = pow(10.0, Double(dp))
    return (v * f).rounded() / f
}

