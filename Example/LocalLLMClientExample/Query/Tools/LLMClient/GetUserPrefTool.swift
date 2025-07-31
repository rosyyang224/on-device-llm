//
//  LocalLLMGetUserPrefTool.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/31/25.
//

import Foundation
import LocalLLMClient
import LocalLLMClientMacros

@Tool("get_user_pref")
struct LocalLLMGetUserPrefTool {
    let description = "Extract user preferences from activity logs to personalize LLM responses and summaries"
    private let cache = Cache.shared
    
    let userPreferenceProvider: @Sendable () -> String
    
    init(userPreferenceProvider: @escaping @Sendable () -> String) {
        self.userPreferenceProvider = userPreferenceProvider
    }

    @ToolArguments
    struct Arguments {
        @ToolArgument("Focus areas to analyze: holdings, portfolio, transactions, all")
        var focusArea: String = "all"
        @ToolArgument("Number of top items to extract per category")
        var topCount: Int = 5
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        print("========== [LocalLLMGetUserPrefTool] CALL ==========")
        print("[ARGS] focusArea:", arguments.focusArea)
        print("[ARGS] topCount:", arguments.topCount)
        
        // Always get from provider, never from LLM
        let userlog = userPreferenceProvider()
        
        // Try to parse user_id/session_id for caching
        var cacheKey = "unknown"
        var activities: [[String: Any]] = []
        do {
            guard let jsonData = userlog.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw NSError(domain: "ParseError", code: -1)
            }
            let userId = json["user_id"] as? String ?? "no_user"
            let sessionId = json["session_id"] as? String ?? ""
            cacheKey = userId + (sessionId.isEmpty ? "" : ":\(sessionId)")
            activities = json["activities"] as? [[String: Any]] ?? []
            print("[DEBUG] Extracted user_id:", userId, "session_id:", sessionId)
            print("[DEBUG] Cache key will be:", cacheKey)
            print("[DEBUG] Activities count:", activities.count)
        } catch {
            print("[ERROR] Could not parse userlog for cache key/activities:", error)
            let errorResult: [String: Any] = [
                "topSymbols": [],
                "preferredGeography": "",
                "preferredAssetClasses": [],
                "preferredSectors": [],
                "preferredDateRanges": [],
                "preferredViews": [],
                "preferredGranularity": "",
                "behaviorSummary": "Invalid userlog format. Expected JSON with 'activities' array and 'user_id'."
            ]
            print("[RETURN] Error result:", errorResult)
            return ToolOutput(data: errorResult)
        }
        
        // Use composite cache key
        let cacheArguments: [String: Any?] = [
            "user_session": cacheKey,
            "focusArea": arguments.focusArea,
            "topCount": arguments.topCount
        ]
        
        // Show full cache key and args
        print("[DEBUG] Full cache arguments:", cacheArguments)
        
        // Check cache
        if let cachedResults = cache.getCachedToolCall(toolName: "get_user_pref", arguments: cacheArguments) as? [String: Any] {
            print("[CACHE HIT] Found summary for key:", cacheKey)
            print("[CACHE VALUE]", cachedResults)
            return ToolOutput(data: cachedResults)
        }
        
        print("[CACHE MISS] No summary found for key:", cacheKey)
        print("[TOOL LOGIC] Extracting preferences from activities…")
        
        let preferences = extractUserPreferences(activities: activities, topCount: arguments.topCount)
        
        let summary: [String: Any] = [
            "topSymbols": preferences.topSymbols,
            "preferredGeography": preferences.preferredGeography,
            "preferredAssetClasses": preferences.preferredAssetClasses,
            "preferredSectors": preferences.preferredSectors,
            "preferredDateRanges": preferences.preferredDateRanges,
            "preferredViews": preferences.preferredViews,
            "preferredGranularity": preferences.preferredGranularity,
            "behaviorSummary": preferences.behaviorSummary
        ]
        
        print("[TOOL OUTPUT] Summary being cached/returned:\n", summary)
        
        // Cache result
        cache.cacheToolCall(toolName: "get_user_pref", arguments: cacheArguments, result: summary)
        print("[CACHE STORE] Cached result for key:", cacheKey)
        print("========== [/LocalLLMGetUserPrefTool] END CALL ==========")
        
        return ToolOutput(data: summary)
    }
}
