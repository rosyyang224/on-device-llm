//
//  ConversationTurn.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/21/25.
//


import Foundation

struct ConversationTurn: Codable {
    let query: String
    let response: String
    let timestamp: Date
    let tokenEstimate: Int

    init(query: String, response: String, tokenEstimate: Int) {
        self.query = query
        self.response = response
        self.timestamp = Date()
        self.tokenEstimate = tokenEstimate
    }
}
