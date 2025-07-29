//
//  FoundationChatSession.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/29/25.
//

import Foundation
import FoundationModels

@MainActor
public final class FoundationChatSession {
    private var session: LanguageModelSession?
    private var isFirstInteraction = true

    // Session state
    private var conversationHistory: [ConversationTurn] = []
    private var sessionAttempts = 0
    private let maxSessionAttempts = 3
    private let maxHistoryLength = 10

    // Context tracking
    private var totalTokensUsed: Int = 0
    private var estimatedContextSize: Int = 0

    private let container: MockDataContainer

    public struct ConversationTurn {
        public let query: String
        public let response: String
        public let timestamp: Date
        public let tokenEstimate: Int
    }

    public enum SessionError: Error {
        case contextLimitExceeded, sessionCreationFailed, maxAttemptsReached, invalidResponse

        public var localizedDescription: String {
            switch self {
            case .contextLimitExceeded: "Context limit exceeded - creating new session"
            case .sessionCreationFailed: "Failed to create new session"
            case .maxAttemptsReached: "Maximum session attempts reached"
            case .invalidResponse: "Invalid response from language model"
            }
        }
    }

    init(container: MockDataContainer) {
        self.container = container
        initializeSession()
    }

    private func initializeSession() {
        sessionAttempts += 1
        guard sessionAttempts <= maxSessionAttempts else {
            conversationHistory.removeAll()
            sessionAttempts = 1
            return
        }

        let getHoldingsTool = FoundationModelsGetHoldingsTool(holdingsProvider: { self.container.holdings })
        let getPortfolioValTool = FoundationModelsGetPortfolioValTool(portfolioValProvider: { self.container.portfolio_value })
        let getTransactionsTool = FoundationModelsGetTransactionsTool(transactionsProvider: { self.container.transactions })

        let tools: [any Tool] = [getHoldingsTool, getPortfolioValTool, getTransactionsTool]

        // Use a summary or prompt based on container content, or just a static system prompt
        session = LanguageModelSession(
            tools: tools,
            instructions: instructions
        )
        estimatedContextSize = estimateTokenCount(String(describing: instructions))
    }

    public func send(_ query: String) async throws -> String {
        var lastError: Error?
        for attempt in 1...maxSessionAttempts {
            do {
                let response = try await attemptSendQuery(query)
                let tokenEstimate = estimateTokenCount(query + response)
                let turn = ConversationTurn(query: query, response: response, timestamp: Date(), tokenEstimate: tokenEstimate)
                conversationHistory.append(turn)
                totalTokensUsed += tokenEstimate
                trimConversationHistory()
                checkContextHealth()
                return response
            } catch {
                lastError = error
                if isContextLimitError(error) {
                    try await recreateSessionWithContinuity()
                } else if attempt < maxSessionAttempts {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
        throw lastError ?? SessionError.maxAttemptsReached
    }

    private func attemptSendQuery(_ query: String) async throws -> String {
        guard let session else { throw SessionError.sessionCreationFailed }
        if isFirstInteraction { isFirstInteraction = false }
        let result = try await session.respond(to: query)
        guard !result.content.isEmpty else { throw SessionError.invalidResponse }
        return result.content
    }

    private func recreateSessionWithContinuity() async throws {
        session = nil
        isFirstInteraction = true
        initializeSession()
        guard session != nil else { throw SessionError.sessionCreationFailed }
    }

    private func checkContextHealth() {
        let currentEstimate = estimatedContextSize + totalTokensUsed
        let warningThreshold = 8000
        let criticalThreshold = 12000
        if currentEstimate > criticalThreshold {
            Task { try await recreateSessionWithContinuity() }
        }
    }

    private func trimConversationHistory() {
        if conversationHistory.count > maxHistoryLength {
            let keepEarly = 2
            let keepRecent = maxHistoryLength - keepEarly
            let earlyTurns = Array(conversationHistory.prefix(keepEarly))
            let recentTurns = Array(conversationHistory.suffix(keepRecent))
            conversationHistory = earlyTurns + recentTurns
        }
    }

    private func isContextLimitError(_ error: Error) -> Bool {
        let errorString = error.localizedDescription.lowercased()
        return errorString.contains("context") &&
               (errorString.contains("limit") || errorString.contains("length") || errorString.contains("token"))
    }

    private func estimateTokenCount(_ text: String) -> Int {
        return text.count / 4
    }

    // Context and debug helpers
    public func refreshContext() {
        // No need to update container (stateless, provided at init)
        sessionAttempts = 0
        initializeSession()
        isFirstInteraction = true
    }
    public func clearHistory() {
        conversationHistory.removeAll()
        totalTokensUsed = 0
        sessionAttempts = 0
    }
    public func getConversationHistory() -> [ConversationTurn] {
        return conversationHistory
    }
}
