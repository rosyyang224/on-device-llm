//
//  UserPreferenceSummary.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/30/25.
//


struct UserPreferenceSummary: Codable {
    let top_symbols: [String]
    let top_actions: [String]
    let primary_focus: String
    let summary_statement: String
}
