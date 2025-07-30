import Foundation

// MARK: - Holdings Compression
extension Compressor {
    
    /// Compress holdings data to show top performers + summary of rest
    static func compressHoldings(_ holdings: [Holding]) -> String {
        guard !holdings.isEmpty else { return "No holdings found." }
        
        let sorted = holdings.sorted { $0.totalmarketvalue > $1.totalmarketvalue }
        let totalValue = holdings.reduce(0) { $0 + $1.totalmarketvalue }
        
        // Show top 10 holdings in detail
        let topCount = min(10, holdings.count)
        let top = Array(sorted.prefix(topCount))
        let remaining = Array(sorted.dropFirst(topCount))
        
        var result = "=== TOP \(topCount) HOLDINGS ===\n"
        for (index, holding) in top.enumerated() {
            let percentage = (holding.totalmarketvalue / totalValue) * 100
            let pnl = holding.totalmarketvalue - holding.totalcostinbccy
            let pnlPercent = holding.marketplpercentinsccy
            
            result += "\(index + 1). \(holding.symbol) (\(holding.assetclass))\n"
            result += "   Value: $\(String(format: "%.2f", holding.totalmarketvalue)) (\(String(format: "%.1f", percentage))%)\n"
            result += "   P&L: $\(String(format: "%.2f", pnl)) (\(String(format: "%.1f", pnlPercent))%)\n"
            result += "   Price: $\(String(format: "%.2f", holding.marketpricesccy)) | Region: \(holding.countryregion)\n\n"
        }
        
        // Summarize remaining holdings
        if !remaining.isEmpty {
            let remainingValue = remaining.reduce(0) { $0 + $1.totalmarketvalue }
            let remainingPercentage = (remainingValue / totalValue) * 100
            
            result += "=== OTHER HOLDINGS ===\n"
            result += "\(remaining.count) additional positions: $\(String(format: "%.2f", remainingValue)) (\(String(format: "%.1f", remainingPercentage))%)\n"
            
            // Show top 5 of the remaining by value
            let topRemaining = Array(remaining.prefix(5))
            if !topRemaining.isEmpty {
                let topRemainingList = topRemaining.map { "\($0.symbol) $\(String(format: "%.0f", $0.totalmarketvalue))" }.joined(separator: ", ")
                result += "Notable others: \(topRemainingList)\n"
            }
            
            // Asset class breakdown for remaining
            let assetClasses = Dictionary(grouping: remaining) { $0.assetclass }
            let assetSummary = assetClasses.mapValues { holdings in
                holdings.reduce(0) { $0 + $1.totalmarketvalue }
            }.sorted { $0.value > $1.value }
            
            result += "By asset class: \(assetSummary.map { "\($0.key) $\(String(format: "%.0f", $0.value))" }.joined(separator: ", "))\n"
        }
        
        // Overall portfolio summary
        let totalPnL = holdings.reduce(0) { $0 + ($1.totalmarketvalue - $1.totalcostinbccy) }
        let totalPnLPercent = (totalPnL / holdings.reduce(0) { $0 + $1.totalcostinbccy }) * 100
        
        result += "\nPORTFOLIO SUMMARY:\n"
        result += "Total Value: $\(String(format: "%.2f", totalValue))\n"
        result += "Total P&L: $\(String(format: "%.2f", totalPnL)) (\(String(format: "%.1f", totalPnLPercent))%)\n"
        result += "Positions: \(holdings.count) | Asset Classes: \(Set(holdings.map { $0.assetclass }).count)\n"
        print(result)
        return result
    }
    
    /// Format holdings data normally (when no compression needed)
    static func formatHoldings(_ holdings: [Holding]) -> String {
        guard !holdings.isEmpty else { return "No holdings found." }
        
        return holdings.map { holding in
            let pnl = holding.totalmarketvalue - holding.totalcostinbccy
            return """
            Symbol: \(holding.symbol) | Asset Class: \(holding.assetclass)
            Market Value: $\(String(format: "%.2f", holding.totalmarketvalue))
            Market Price: $\(String(format: "%.2f", holding.marketpricesccy))
            P&L: $\(String(format: "%.2f", pnl)) (\(String(format: "%.2f", holding.marketplpercentinsccy))%)
            Region: \(holding.countryregion) | Account: \(holding.accounttype)
            """
        }.joined(separator: "\n\n")
    }
}

// MARK: - Transactions Compression
extension Compressor {
    
    /// Compress transactions to show recent activity + summary patterns
    static func compressTransactions(_ transactions: [Transaction]) -> String {
        guard !transactions.isEmpty else { return "No transactions found." }
        
        // Sort by transaction date (most recent first)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // Adjust based on your date format
        
        let sortedByDate = transactions.sorted { transaction1, transaction2 in
            let date1 = dateFormatter.date(from: transaction1.transactiondate) ?? Date.distantPast
            let date2 = dateFormatter.date(from: transaction2.transactiondate) ?? Date.distantPast
            return date1 > date2
        }
        
        // Recent transactions (last 15-20)
        let recentCount = min(20, transactions.count)
        let recent = Array(sortedByDate.prefix(recentCount))
        
        var result = "=== RECENT ACTIVITY (Last \(recentCount) Transactions) ===\n"
        for transaction in recent {
            let shares = transaction.sharesoffacevalue
            let totalAmount = Swift.abs(transaction.transactionamt)
            
            result += "\(transaction.transactiondate): \(transaction.transactiontypedesc)\n"
            result += "  \(transaction.description) | Shares: \(String(format: "%.2f", shares))\n"
            result += "  Amount: $\(String(format: "%.2f", totalAmount)) | Price: $\(String(format: "%.2f", transaction.costprice))\n"
            
            if transaction.commission > 0 {
                result += "  Commission: $\(String(format: "%.2f", transaction.commission))"
            }
            if transaction.taxwithheld > 0 {
                result += " | Tax: $\(String(format: "%.2f", transaction.taxwithheld))"
            }
            result += "\n\n"
        }
        
        // Transaction type analysis
        let typeGroups = Dictionary(grouping: transactions) { $0.transactiontypedesc }
        let typeSummary = typeGroups.mapValues { transactions in
            let totalAmount = transactions.reduce(0) { $0 + Swift.abs($1.transactionamt) }
            let totalShares = transactions.reduce(0) { $0 + $1.sharesoffacevalue }
            return (count: transactions.count, amount: totalAmount, shares: totalShares)
        }.sorted { $0.value.count > $1.value.count }
        
        result += "=== TRANSACTION ANALYSIS ===\n"
        result += "Total Transactions: \(transactions.count)\n\n"
        
        result += "Transaction Types:\n"
        for (type, summary) in typeSummary.prefix(5) {
            result += "  \(type): \(summary.count) transactions | Total: $\(String(format: "%.0f", summary.amount))\n"
        }
        
        // Symbol analysis
        let symbolGroups = Dictionary(grouping: transactions) { $0.description }
        let symbolSummary = symbolGroups.mapValues { transactions in
            let totalAmount = transactions.reduce(0) { $0 + Swift.abs($1.transactionamt) }
            return (count: transactions.count, amount: totalAmount)
        }.sorted { $0.value.amount > $1.value.amount }
        
        result += "\nMost Active Securities:\n"
        for (symbol, summary) in symbolSummary.prefix(7) {
            result += "  \(symbol): \(summary.count) trades | Volume: $\(String(format: "%.0f", summary.amount))\n"
        }
        
        // Cost analysis
        let totalCommissions = transactions.reduce(0) { $0 + $1.commission }
        let totalTaxes = transactions.reduce(0) { $0 + $1.taxwithheld }
        let totalVolume = transactions.reduce(0) { $0 + Swift.abs($1.transactionamt) }
        
        result += "\nCost Summary:\n"
        result += "Total Volume: $\(String(format: "%.2f", totalVolume))\n"
        result += "Commissions: $\(String(format: "%.2f", totalCommissions))\n"
        result += "Taxes Withheld: $\(String(format: "%.2f", totalTaxes))\n"
        print(result)
        return result
    }
    
    /// Format transactions data normally (when no compression needed)
    static func formatTransactions(_ transactions: [Transaction]) -> String {
        guard !transactions.isEmpty else { return "No transactions found." }
        
        return transactions.map { transaction in
            let totalAmount = Swift.abs(transaction.transactionamt)
            var result = """
            Date: \(transaction.transactiondate) | Settlement: \(transaction.settlementdate)
            Type: \(transaction.transactiontypedesc)
            Security: \(transaction.description)
            Shares: \(String(format: "%.2f", transaction.sharesoffacevalue)) | Price: $\(String(format: "%.2f", transaction.costprice))
            Amount: $\(String(format: "%.2f", totalAmount))
            """
            
            if transaction.commission > 0 || transaction.taxwithheld > 0 || transaction.otherexpensesm > 0 {
                result += "\nFees - Commission: $\(String(format: "%.2f", transaction.commission))"
                result += " | Tax: $\(String(format: "%.2f", transaction.taxwithheld))"
                result += " | Other: $\(String(format: "%.2f", transaction.otherexpensesm))"
            }
            
            result += "\nAccount: \(transaction.account) | Currency: \(transaction.stccy)"
            
            return result
        }.joined(separator: "\n\n")
    }
}

// MARK: - Portfolio Value Compression
extension Compressor {
    
    /// Compress portfolio value (rarely needed, but available)
    static func compressPortfolioValue(_ portfolio: PortfolioValue) -> String {
        return """
        Portfolio Value: $\(String(format: "%.2f", portfolio.marketValue))
        Market Change: $\(String(format: "%.2f", portfolio.marketChange))
        YTD Return: \(String(format: "%.2f", portfolio.yearToDateRateOfReturnCumulative))%
        Net ARR: \(String(format: "%.2f", portfolio.netARR))% | Cumulative ARR: \(String(format: "%.2f", portfolio.cumulativeARR))%
        Value Date: \(portfolio.valueDate)
        """
    }
    
    /// Format portfolio value normally
    static func formatPortfolioValue(_ portfolio: PortfolioValue) -> String {
        return """
        Client ID: \(portfolio.clientID)
        Market Value: $\(String(format: "%.2f", portfolio.marketValue))
        Market Change: $\(String(format: "%.2f", portfolio.marketChange))
        Value Date: \(portfolio.valueDate)
        
        Performance Metrics:
        Year-to-Date Rate of Return (Cumulative): \(String(format: "%.2f", portfolio.yearToDateRateOfReturnCumulative))%
        Year-to-Date Return: \(String(format: "%.2f", portfolio.yearToDateOfReturn))%
        Net ARR: \(String(format: "%.2f", portfolio.netARR))%
        Cumulative ARR: \(String(format: "%.2f", portfolio.cumulativeARR))%
        
        Contribution and Withdrawals: $\(String(format: "%.2f", portfolio.contributionAndWithdraw))
        Growth Cumulative Value Date: \(portfolio.growthCumulativeValueDate)
        Indices: \(portfolio.indices.joined(separator: ", "))
        """
    }
}

// MARK: - Generic Compression for Unknown Data Types
extension Compressor {
    
    /// Generic compression for any string data that's too large
    static func genericCompress(_ text: String, targetTokens: Int = maxTokensPerResponse) -> String {
        let lines = text.components(separatedBy: .newlines)
        let targetLines = Int(Double(lines.count) * (Double(targetTokens) / Double(estimateTokens(text))))
        
        if targetLines >= lines.count {
            return text // No compression needed
        }
        
        let compressed = Array(lines.prefix(targetLines))
        let remaining = lines.count - targetLines
        
        var result = compressed.joined(separator: "\n")
        if remaining > 0 {
            result += "\n\n... (\(remaining) more lines truncated for brevity)"
        }
        print(result)
        return result
    }
}

// MARK: - Usage Examples and Integration Helpers

extension Compressor {
    
    /// Smart wrapper for any data type - automatically detects and compresses
    static func processData<T>(_ data: T, customCompressionThreshold: Int? = nil) -> String {
        let threshold = customCompressionThreshold ?? maxTokensPerResponse
        
        // Try to format the data first
        let formatted: String
        switch data {
        case let holdings as [Holding]:
            formatted = formatHoldings(holdings)
            return shouldCompress(formatted, maxTokens: threshold) ? compressHoldings(holdings) : formatted
            
        case let transactions as [Transaction]:
            formatted = formatTransactions(transactions)
            return shouldCompress(formatted, maxTokens: threshold) ? compressTransactions(transactions) : formatted
            
        case let portfolio as PortfolioValue:
            formatted = formatPortfolioValue(portfolio)
            return shouldCompress(formatted, maxTokens: threshold) ? compressPortfolioValue(portfolio) : formatted
            
        default:
            // Generic string handling
            formatted = String(describing: data)
            return shouldCompress(formatted, maxTokens: threshold) ? genericCompress(formatted, targetTokens: threshold) : formatted
        }
    }
}

// MARK: - Configuration
extension Compressor {
    
    /// Adjust compression settings based on context
    struct CompressionConfig {
        let maxTokens: Int
        let topHoldingsCount: Int
        let recentTransactionsCount: Int
        
        static let `default` = CompressionConfig(
            maxTokens: 2000,
            topHoldingsCount: 10,
            recentTransactionsCount: 20
        )
        
        static let aggressive = CompressionConfig(
            maxTokens: 1000,
            topHoldingsCount: 5,
            recentTransactionsCount: 10
        )
        
        static let detailed = CompressionConfig(
            maxTokens: 4000,
            topHoldingsCount: 15,
            recentTransactionsCount: 30
        )
    }
}
