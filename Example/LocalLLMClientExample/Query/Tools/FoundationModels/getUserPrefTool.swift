import Foundation
import FoundationModels

struct FoundationModelsGetUserPrefTool: Tool {
    static var name: String = "get_user_pref"
    let description = "Analyze user activity log and extract their top preferences automatically"
    
    @Generable
    struct Arguments {
        @Guide(description: "User activity log as JSON string with 'activities' array containing events with timestamps and properties")
        var userlog: String
        
        @Guide(description: "Number of top items to return for each category. Default: 3")
        var count: Int = 3
    }
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        guard let jsonData = arguments.userlog.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let activities = json["activities"] as? [[String: Any]] else {
            return "Invalid userlog format"
        }
        
        let summary = analyzeUserLog(activities: activities, topCount: arguments.count)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedData = try encoder.encode(summary)
        return String(data: encodedData, encoding: .utf8) ?? "Error encoding summary"
    }
}

func analyzeUserLog(activities: [[String: Any]], topCount: Int) -> UserPreferenceSummary {
    var symbolCounts: [String: Int] = [:]
    var actionCounts: [String: Int] = [:]
    var allTerms: [String: Int] = [:]
    
    for activity in activities {
        let event = activity["event"] as? String ?? ""
        let properties = activity["properties"] as? [String: Any] ?? [:]
        
        // Count actions
        actionCounts[event, default: 0] += 1
        
        // Extract and count ALL terms from the entire event
        let allText = "\(event) \(properties.values.compactMap { $0 as? String }.joined(separator: " "))"
        let terms = extractTerms(from: allText)
        
        for term in terms {
            allTerms[term, default: 0] += 1
            
            // If it looks like a symbol, count it separately
            if term.range(of: "^[A-Z]{2,5}$", options: .regularExpression) != nil {
                symbolCounts[term, default: 0] += 1
            }
        }
    }
    
    // Find the most frequent terms to determine focus
    let topTerms = getTop(from: allTerms, count: 10)
    let primaryFocus = inferFocusFromTerms(topTerms)
    
    let topSymbols = getTop(from: symbolCounts, count: topCount)
    let topActions = getTop(from: actionCounts, count: topCount)
    
    let summary = generateSummary(
        symbols: topSymbols,
        actions: topActions,
        focus: primaryFocus,
        topTerms: Array(topTerms.prefix(5))
    )
    
    return UserPreferenceSummary(
        top_symbols: topSymbols,
        top_actions: topActions,
        primary_focus: primaryFocus,
        summary_statement: summary
    )
}

func extractTerms(from text: String) -> [String] {
    return text.lowercased()
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { $0.count > 2 } // Only meaningful words
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
}

func inferFocusFromTerms(_ terms: [String]) -> String {
    let termString = terms.joined(separator: "_")
    
    for term in terms {
        if ["holdings", "performance", "transaction"].contains(term) {
            return "\(term)_focused"
        }
    }
    
    return terms.first.map { "\($0)_activity" } ?? "general_activity"
}

func getTop(from counts: [String: Int], count: Int) -> [String] {
    return counts
        .sorted { $0.value > $1.value }
        .prefix(count)
        .map { $0.key }
}

func generateSummary(symbols: [String], actions: [String], focus: String, topTerms: [String]) -> String {
    var parts: [String] = []
    
    if !symbols.isEmpty {
        parts.append("Top symbols: \(symbols.joined(separator: ", "))")
    }
    
    if !actions.isEmpty {
        parts.append("Most common actions: \(actions.joined(separator: ", "))")
    }
    
    parts.append("Primary focus: \(focus)")
    
    if !topTerms.isEmpty {
        parts.append("Key terms: \(topTerms.joined(separator: ", "))")
    }
    
    return parts.joined(separator: ". ")
}
