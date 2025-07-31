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

    @ToolArguments
    struct Arguments {
        @ToolArgument("User activity log as JSON string with 'activities' array")
        var userlog: String
        @ToolArgument("Focus areas to analyze: holdings, portfolio, transactions, all")
        var focusArea: String = "all"
        @ToolArgument("Number of top items to extract per category")
        var topCount: Int = 5
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        print("[GetUserPrefTool] called with arguments:")
        print("  userlog length: \(arguments.userlog.count) characters")
        print("  focusArea: \(arguments.focusArea)")
        print("  topCount: \(arguments.topCount)")

        let cacheArguments: [String: Any?] = [
            "userlog": arguments.userlog,
            "focusArea": arguments.focusArea,
            "topCount": arguments.topCount
        ]
        
        // Check cache first
        if let cached = cache.getCachedToolCall(toolName: "GetUserPrefTool", arguments: cacheArguments) as? [String: Any] {
            print("[GetUserPrefTool] CACHE HIT - returning cached preferences.")
            return ToolOutput(data: cached)
        }

        guard let jsonData = arguments.userlog.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let activities = json["activities"] as? [[String: Any]] else {
            print("[GetUserPrefTool] Invalid userlog format.")
            let result = ["error": "Invalid userlog format. Expected JSON with 'activities' array."] as [String: Any]
            return ToolOutput(data: result)
        }
        
        print("[GetUserPrefTool] Processing \(activities.count) activities")

        let preferences = extractUserPreferences(activities: activities, topCount: arguments.topCount)
        
        let formattedOutput = Compressor.processData(preferences)
        print("[GetUserPrefTool] Applied compression! compressed size: \(Compressor.estimateTokens(formattedOutput)) tokens")
        
        let result: [String: Any] = [
            "preferences": preferences,
            "formatted_output": formattedOutput
        ]

        cache.cacheToolCall(toolName: "GetUserPrefTool", arguments: cacheArguments, result: result)
        return ToolOutput(data: result)
    }
}
