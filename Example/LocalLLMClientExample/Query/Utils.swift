//
//  Utils.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/18/25.
//

import Foundation
import LocalLLMClient
import LocalLLMClientMLX
import LocalLLMClientLlama

func loadMockDataContainer(from jsonString: String) -> MockDataContainer? {
    let data = Data(jsonString.utf8)
    let decoder = JSONDecoder()
    do {
        return try decoder.decode(MockDataContainer.self, from: data)
    } catch {
        print("Failed to decode mock data: \(error)")
        return nil
    }
}

func makeLLMTools(container: MockDataContainer, userlogProvider: @escaping @Sendable () -> String) -> [any LLMTool] {
    let holdings = container.holdings
    let portfolio_vals = container.portfolio_value
    let transactions = container.transactions

    let getHoldingsTool = LocalLLMGetHoldingsTool(holdingsProvider: { holdings })
    let getPortfolioValTool = LocalLLMGetPortfolioValTool(portfolioValProvider: { portfolio_vals })
    let getTransactionsTool = LocalLLMGetTransactionsTool(transactionsProvider: { transactions })
    let getUserPrefTool = LocalLLMGetUserPrefTool(userPreferenceProvider: userlogProvider)

    return [
        getHoldingsTool,
        getPortfolioValTool,
        getTransactionsTool,
        getUserPrefTool,
    ]
}

func extractUserPreferences(activities: [[String: Any]], topCount: Int) -> UserPreferences {
    var symbolEngagement: [String: Int] = [:]
    var geographicFocus: [String: Int] = [:]
    var assetClassFocus: [String: Int] = [:]
    var sectorFocus: [String: Int] = [:]
    var dateRangePrefs: [String: Int] = [:]
    var viewPreferences: [String: Int] = [:]
    var dataGranularity: [String: Int] = [:]
    
    var holdingsFocus = 0
    var transactionsFocus = 0
    var portfolioFocus = 0
    var symbolDrillDowns = 0
    var chartInteractions = 0
    var detailViews = 0
    
    for activityData in activities {
        let activity = ContextualActivity(from: activityData)
        
        // Track symbol engagement
        for symbol in activity.extractSymbols() {
            symbolEngagement[symbol, default: 0] += 1
        }
        
        // Track geographic focus
        if let geo = activity.extractGeography() {
            geographicFocus[geo, default: 0] += 1
        }
        
        // Track asset class focus
        if let assetClass = activity.extractAssetClass() {
            assetClassFocus[assetClass, default: 0] += 1
        }
        
        // Track sector focus
        if let sector = activity.extractSector() {
            sectorFocus[sector, default: 0] += 1
        }
        
        // Track date range preferences
        if let dateRange = activity.extractDateRange() {
            dateRangePrefs[dateRange, default: 0] += 1
        }
        
        // Track view preferences (what they spend time on)
        let viewType = activity.getViewType()
        viewPreferences[viewType, default: 0] += 1
        
        // Track data granularity preference
        let granularity = activity.getDataGranularity()
        dataGranularity[granularity, default: 0] += 1
        
        let focusArea = activity.getPrimaryFocusArea()
        switch focusArea {
        case "holdings": holdingsFocus += activity.getEngagementWeight()
        case "transactions": transactionsFocus += activity.getEngagementWeight()
        case "portfolio": portfolioFocus += activity.getEngagementWeight()
        default: break
        }
        
        if activity.isSymbolDrillDown() { symbolDrillDowns += 1 }
        if activity.isChartInteraction() { chartInteractions += 1 }
        if activity.isDetailView() { detailViews += 1 }
    }
    
    let (primaryFocus, focusIntensity, granularityLevel, specificInterests) =
        analyzeFocusMetrics(
            holdingsFocus: holdingsFocus,
            transactionsFocus: transactionsFocus,
            portfolioFocus: portfolioFocus,
            symbolDrillDowns: symbolDrillDowns,
            chartInteractions: chartInteractions,
            detailViews: detailViews,
            symbolEngagement: symbolEngagement
        )
    
    return UserPreferences(
        primaryFocus: primaryFocus,
        focusIntensity: focusIntensity,
        granularityLevel: granularityLevel,
        specificInterests: specificInterests,
        topSymbols: getTopItems(from: symbolEngagement, count: topCount),
        preferredGeography: geographicFocus.max(by: { $0.value < $1.value })?.key ?? "mixed",
        preferredAssetClasses: getTopItems(from: assetClassFocus, count: topCount),
        preferredSectors: getTopItems(from: sectorFocus, count: topCount),
        preferredDateRanges: getTopItems(from: dateRangePrefs, count: topCount),
        preferredViews: getTopItems(from: viewPreferences, count: topCount),
        preferredGranularity: dataGranularity.max(by: { $0.value < $1.value })?.key ?? "mixed",
    )
}

// MARK: - Missing Helper Functions

func analyzeFocusMetrics(
    holdingsFocus: Int,
    transactionsFocus: Int,
    portfolioFocus: Int,
    symbolDrillDowns: Int,
    chartInteractions: Int,
    detailViews: Int,
    symbolEngagement: [String: Int]
) -> (primaryFocus: String, focusIntensity: String, granularityLevel: String, specificInterests: [String]) {
    
    // Determine primary focus
    let totalFocus = holdingsFocus + transactionsFocus + portfolioFocus
    let primaryFocus: String
    let focusIntensity: String
    
    if totalFocus == 0 {
        primaryFocus = "general_browsing"
        focusIntensity = "low"
    } else {
        let holdingsRatio = Double(holdingsFocus) / Double(totalFocus)
        let transactionsRatio = Double(transactionsFocus) / Double(totalFocus)
        let portfolioRatio = Double(portfolioFocus) / Double(totalFocus)
        
        if holdingsRatio > 0.5 {
            primaryFocus = "holdings"
        } else if transactionsRatio > 0.5 {
            primaryFocus = "transactions"
        } else if portfolioRatio > 0.5 {
            primaryFocus = "portfolio"
        } else {
            primaryFocus = "mixed"
        }
        
        // Determine intensity based on drill-downs and interactions
        let granularityScore = symbolDrillDowns + chartInteractions + (detailViews / 2)
        if granularityScore > 8 {
            focusIntensity = "high"
        } else if granularityScore > 3 {
            focusIntensity = "medium"
        } else {
            focusIntensity = "low"
        }
    }
    
    // Determine granularity level
    let granularityLevel: String
    if symbolDrillDowns > 3 && detailViews > 2 {
        granularityLevel = "symbol_level"
    } else if symbolDrillDowns > 1 || chartInteractions > 2 {
        granularityLevel = "category_level"
    } else {
        granularityLevel = "portfolio_level"
    }
    
    // Generate specific interests based on focus
    var specificInterests: [String] = []
    let topSymbols = symbolEngagement.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    
    switch primaryFocus {
    case "holdings":
        specificInterests = Array(topSymbols.prefix(3)) + ["market_price_tracking", "performance_analysis"]
    case "transactions":
        specificInterests = ["buy_orders", "transaction_costs", "recent_activity"] + Array(topSymbols.prefix(2))
    case "portfolio":
        specificInterests = ["portfolio_performance", "allocation_analysis", "trend_tracking"]
    default:
        specificInterests = Array(topSymbols.prefix(2)) + ["general_overview"]
    }
    
    return (primaryFocus, focusIntensity, granularityLevel, Array(specificInterests))
}

func generateEnhancedBehaviorSummary(
    primaryFocus: String,
    focusIntensity: String,
    symbols: [String: Int],
    views: [String: Int],
    geography: [String: Int],
    assetClass: [String: Int],
    sectors: [String: Int]
) -> String {
    var summary: [String] = []
    
    // Enhanced primary focus with intensity
    summary.append("Primary focus: \(primaryFocus) (\(focusIntensity) intensity)")
    
    // Geographic preference
    if let topGeo = geography.max(by: { $0.value < $1.value })?.key {
        summary.append("Geographic focus: \(topGeo)")
    }
    
    // Asset class preference
    if let topAsset = assetClass.max(by: { $0.value < $1.value })?.key {
        summary.append("Asset preference: \(topAsset)")
    }
    
    // Sector interest
    if let topSector = sectors.max(by: { $0.value < $1.value })?.key {
        summary.append("Sector interest: \(topSector)")
    }
    
    // Most engaged symbols
    let topSymbols = symbols.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    if !topSymbols.isEmpty {
        summary.append("Most analyzed: \(topSymbols.joined(separator: ", "))")
    }
    
    return summary.joined(separator: ". ")
}

func getTopItems(from counts: [String: Int], count: Int) -> [String] {
    return counts
        .sorted { $0.value > $1.value }
        .prefix(count)
        .map { $0.key }
}

func generateBehaviorSummary(
    symbols: [String: Int],
    views: [String: Int],
    geography: [String: Int],
    assetClass: [String: Int],
    sectors: [String: Int]
) -> String {
    var summary: [String] = []
    
    // Primary focus
    let topView = views.max(by: { $0.value < $1.value })?.key ?? "general"
    summary.append("Primary focus: \(topView)")
    
    // Geographic preference
    if let topGeo = geography.max(by: { $0.value < $1.value })?.key {
        summary.append("Geographic focus: \(topGeo)")
    }
    
    // Asset class preference
    if let topAsset = assetClass.max(by: { $0.value < $1.value })?.key {
        summary.append("Asset preference: \(topAsset)")
    }
    
    // Sector interest
    if let topSector = sectors.max(by: { $0.value < $1.value })?.key {
        summary.append("Sector interest: \(topSector)")
    }
    
    // Most engaged symbols
    let topSymbols = symbols.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    if !topSymbols.isEmpty {
        summary.append("Most viewed: \(topSymbols.joined(separator: ", "))")
    }
    
    return summary.joined(separator: ". ")
}

// MARK: - ContextualActivity Extensions

extension ContextualActivity {
    func getPrimaryFocusArea() -> String {
        // Analyze the activity to determine which area it focuses on
        if let url = properties["url"] as? String {
            if url.contains("/holdings") {
                return "holdings"
            }
            if url.contains("/transactions") {
                return "transactions"
            }
            if url.contains("/portfolio") {
                return "portfolio"
            }
        }
        
        if let tab = properties["tab"] as? String {
            switch tab {
            case "holdings": return "holdings"
            case "transactions": return "transactions"
            case "portfolio": return "portfolio"
            default: break
            }
        }
        
        if let rowType = properties["row_type"] as? String {
            switch rowType {
            case "holding": return "holdings"
            case "transaction": return "transactions"
            default: break
            }
        }
        
        return "general"
    }
    
    func getEngagementWeight() -> Int {
        // Return different weights based on activity type
        switch event {
        case "page_view": return 1
        case "row_click": return 3
        case "chart_interaction": return 2
        case "filter_applied": return 1
        case "search": return 2
        case "export": return 2
        case "tab_click": return 1
        default: return 1
        }
    }
    
    func isSymbolDrillDown() -> Bool {
        // Check if this activity involves drilling down into specific symbol details
        if let url = properties["url"] as? String, url.contains("/details/") {
            return true
        }
        
        if event == "row_click" && properties["symbol"] != nil {
            return true
        }
        
        if event == "search" && properties["type"] as? String == "symbol_lookup" {
            return true
        }
        
        return false
    }
    
    func isChartInteraction() -> Bool {
        return event == "chart_interaction"
    }
    
    func isDetailView() -> Bool {
        if let url = properties["url"] as? String, url.contains("/details/") {
            return true
        }
        return false
    }
}

struct ContextualActivity {
    let event: String
    let properties: [String: Any]
    
    init(from activityData: [String: Any]) {
        self.event = activityData["event"] as? String ?? ""
        self.properties = activityData["properties"] as? [String: Any] ?? [:]
    }
    
    func extractSymbols() -> [String] {
        var symbols: [String] = []
        
        // Check symbol field directly (most common)
        if let symbol = properties["symbol"] as? String {
            symbols.append(symbol)
        }
        
        // Check row_id for symbols
        if let rowId = properties["row_id"] as? String,
           rowId.range(of: "^[A-Z]{2,5}$", options: .regularExpression) != nil {
            symbols.append(rowId)
        }
        
        // Check URL for cusip or symbol patterns
        if let url = properties["url"] as? String {
            let components = url.components(separatedBy: "/")
            for component in components {
                // Look for symbol patterns or use cusip if that's how URLs are structured
                if component.range(of: "^[A-Z]{2,5}$", options: .regularExpression) != nil {
                    symbols.append(component)
                }
            }
        }
        
        // Check search queries
        if let query = properties["query"] as? String,
           query.range(of: "^[A-Z]{2,5}$", options: .regularExpression) != nil {
            symbols.append(query)
        }
        
        return symbols
    }
    
    func extractGeography() -> String? {
        // Look through all property values for geographic indicators
        for (key, value) in properties {
            if let stringValue = value as? String {
                let lower = stringValue.lowercased()
                // Check for actual countryregion field values
                if key == "countryregion" || lower.contains("united states") {
                    return "United_States"
                }
                if lower.contains("canada") {
                    return "Canada"
                }
                if lower.contains("united kingdom") || lower.contains("uk") {
                    return "United_Kingdom"
                }
                if lower.contains("japan") {
                    return "Japan"
                }
            }
        }
        return nil
    }
    
    func extractAssetClass() -> String? {
        // Check for actual assetclass field values from your Holding struct
        if let assetClass = properties["assetclass"] as? String {
            return assetClass // Returns "Equity", "Bond", etc. as stored
        }
        
        // Also check filter values and labels
        for (key, value) in properties {
            if let stringValue = value as? String {
                let lower = stringValue.lowercased()
                if key == "filter" && stringValue == "assetclass" {
                    continue // This is just the filter name
                }
                if lower == "equity" {
                    return "Equity"
                }
                if lower == "bond" {
                    return "Bond"
                }
                if lower == "cash" {
                    return "Cash"
                }
            }
        }
        return nil
    }
    
    func extractSector() -> String? {
        for (_, value) in properties {
            if let stringValue = value as? String {
                let lower = stringValue.lowercased()
                if lower.contains("technology") {
                    return "technology"
                }
                if lower.contains("healthcare") {
                    return "healthcare"
                }
                // Add more sectors as needed
            }
        }
        return nil
    }
    
    func extractDateRange() -> String? {
        if event == "date_picker" {
            if let periodType = properties["period_type"] as? String {
                return periodType
            }
        }
        return nil
    }
    
    func getViewType() -> String {
        // Categorize what type of view/data the user is engaging with
        if let url = properties["url"] as? String {
            if url.contains("/holdings/details/") {
                return "individual_holdings"
            }
            if url.contains("/holdings") {
                return "holdings_overview"
            }
            if url.contains("/portfolio") {
                return "portfolio_performance"
            }
            if url.contains("/transactions") {
                return "transactions_overview"
            }
        }
        
        if let tab = properties["tab"] as? String {
            switch tab {
            case "holdings": return "holdings_overview"
            case "performance_graphs": return "performance_analysis"
            case "transactions": return "transaction_history"
            case "portfolio": return "portfolio_performance"
            default: return tab
            }
        }
        
        if event == "chart_interaction" {
            if let chartName = properties["chart_name"] as? String {
                return "chart_\(chartName)"
            }
        }
        
        if event == "filter_applied" {
            if let filter = properties["filter"] as? String {
                return "filter_\(filter)"
            }
        }
        
        return "general_browsing"
    }
    
    func getDataGranularity() -> String {
        // Determine what level of detail they prefer
        if let url = properties["url"] as? String, url.contains("/details/") {
            return "individual_security"
        }
        
        if let tab = properties["tab"] as? String, tab == "asset_class" {
            return "asset_class_level"
        }
        
        if properties["chart_name"] as? String == "sector_allocation" {
            return "sector_level"
        }
        
        if event == "filter_applied" && properties["filter"] as? String == "asset_class" {
            return "asset_class_level"
        }
        
        return "portfolio_level"
    }
}
