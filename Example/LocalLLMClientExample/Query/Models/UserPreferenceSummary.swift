//
//  UserPreferenceSummary.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/30/25.
//


struct UserPreferences: Codable {
    let topSymbols: [String]
    let preferredGeography: String
    let preferredAssetClasses: [String]
    let preferredSectors: [String]
    let preferredDateRanges: [String]
    let preferredViews: [String]
    let preferredGranularity: String
    let behaviorSummary: String
}
