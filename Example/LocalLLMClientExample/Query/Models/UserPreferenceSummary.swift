//
//  UserPreferenceSummary.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/30/25.
//

import Foundation
import FoundationModels

@Generable
struct UserPreferences: Codable, PromptRepresentable {
    @Guide(description: "Primary area of focus: holdings, transactions, portfolio, or mixed")
    let primaryFocus: String
    
    @Guide(description: "Level of engagement: high, medium, or low")
    let focusIntensity: String
    
    @Guide(description: "Analysis depth: symbol_level, category_level, or portfolio_level")
    let granularityLevel: String
    
    @Guide(description: "Specific areas of interest within their primary focus")
    let specificInterests: [String]
    
    @Guide(description: "Top N symbols the user interacted with most")
    let topSymbols: [String]
    
    @Guide(description: "Most viewed or interacted-with geographic region")
    let preferredGeography: String
    
    @Guide(description: "Top N asset classes the user focuses on")
    let preferredAssetClasses: [String]
    
    @Guide(description: "Top N sectors of interest")
    let preferredSectors: [String]
    
    @Guide(description: "Most common date ranges viewed or filtered by")
    let preferredDateRanges: [String]
    
    @Guide(description: "Views or tabs the user spends the most time on")
    let preferredViews: [String]
    
    @Guide(description: "Typical granularity (e.g. security, asset class, portfolio)")
    let preferredGranularity: String
}
