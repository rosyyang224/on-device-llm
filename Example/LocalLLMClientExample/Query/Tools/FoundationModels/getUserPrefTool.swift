import Foundation
import FoundationModels

struct FoundationModelsGetUserPrefTool: Tool {
    static var name: String = "get_user_pref"
    let description = "Extract user preferences from activity logs to personalize LLM responses and summaries"
    
    @Generable
    struct Arguments {
        @Guide(description: "User activity log as JSON string with 'activities' array")
        var userlog: String
        
        @Guide(description: "Focus areas to analyze: holdings, portfolio, transactions, all")
        var focusArea: String = "all"
        
        @Guide(description: "Number of top items to extract per category")
        var topCount: Int = 5
    }
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        guard let jsonData = arguments.userlog.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let activities = json["activities"] as? [[String: Any]] else {
            return "Invalid userlog format. Expected JSON with 'activities' array."
        }
        
        let preferences = extractUserPreferences(activities: activities, topCount: arguments.topCount)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedData = try encoder.encode(preferences)
        return String(data: encodedData, encoding: .utf8) ?? "Error encoding preferences"
    }
}

func extractUserPreferences(activities: [[String: Any]], topCount: Int) -> UserPreferences {
    var symbolEngagement: [String: Int] = [:]
    var geographicFocus: [String: Int] = [:]
    var assetClassFocus: [String: Int] = [:]
    var sectorFocus: [String: Int] = [:]
    var dateRangePrefs: [String: Int] = [:]
    var viewPreferences: [String: Int] = [:]
    var dataGranularity: [String: Int] = [:]
    
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
    }
    
    return UserPreferences(
        topSymbols: getTopItems(from: symbolEngagement, count: topCount),
        preferredGeography: geographicFocus.max(by: { $0.value < $1.value })?.key ?? "mixed",
        preferredAssetClasses: getTopItems(from: assetClassFocus, count: topCount),
        preferredSectors: getTopItems(from: sectorFocus, count: topCount),
        preferredDateRanges: getTopItems(from: dateRangePrefs, count: topCount),
        preferredViews: getTopItems(from: viewPreferences, count: topCount),
        preferredGranularity: dataGranularity.max(by: { $0.value < $1.value })?.key ?? "mixed",
        behaviorSummary: generateBehaviorSummary(
            symbols: symbolEngagement,
            views: viewPreferences,
            geography: geographicFocus,
            assetClass: assetClassFocus,
            sectors: sectorFocus
        )
    )
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

// MARK: - Helper Structures

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
