//
//  FoundationChatSession.swift (Enhanced with Caching)
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/29/25.
//  Enhanced by Assistant on 7/29/25.
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

    // Caching integration
    private(set) public var sessionId: UUID
    private var lastCacheUpdate: Date = Date()
    private let cacheUpdateInterval: TimeInterval = 30 // Cache every 30 seconds

    private let container: MockDataContainer

    public struct ConversationTurn: Codable {
        public let query: String
        public let response: String
        public let timestamp: Date
        public let tokenEstimate: Int
        public let turnId: UUID

        public init(query: String, response: String, tokenEstimate: Int) {
            self.query = query
            self.response = response
            self.timestamp = Date()
            self.tokenEstimate = tokenEstimate
            self.turnId = UUID()
        }
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
        self.sessionId = UUID()
        initializeSession()
    }

    convenience init(container: MockDataContainer, sessionId: UUID) {
        self.init(container: container)
        self.sessionId = sessionId
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
                let turn = ConversationTurn(query: query, response: response, tokenEstimate: tokenEstimate)
                conversationHistory.append(turn)
                totalTokensUsed += tokenEstimate
                trimConversationHistory()
                checkContextHealth()

                // Periodic caching for long conversations
                await updateCacheIfNeeded()

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
        let contextSummary = createContextSummary()

        session = nil
        isFirstInteraction = true
        initializeSession()
        guard session != nil else { throw SessionError.sessionCreationFailed }

        if !contextSummary.isEmpty {
            try await restoreContext(from: contextSummary)
        }
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

    // MARK: - Enhanced Caching Methods

    private func updateCacheIfNeeded() async {
        let now = Date()
        if now.timeIntervalSince(lastCacheUpdate) > cacheUpdateInterval && !conversationHistory.isEmpty {
            await saveTempSession()
            lastCacheUpdate = now
        }
    }

    private func saveTempSession() async {
        let tempSession = TempSessionState(
            sessionId: sessionId,
            conversationHistory: conversationHistory,
            totalTokensUsed: totalTokensUsed,
            estimatedContextSize: estimatedContextSize,
            lastSaved: Date()
        )

        if let encoded = try? JSONEncoder().encode(tempSession) {
            UserDefaults.standard.set(encoded, forKey: "temp_foundation_session_\(sessionId)")
        }
    }

    private func loadTempSession() -> TempSessionState? {
        guard let data = UserDefaults.standard.data(forKey: "temp_foundation_session_\(sessionId)"),
              let session = try? JSONDecoder().decode(TempSessionState.self, from: data) else {
            return nil
        }
        return session
    }

    private func createContextSummary() -> String {
        guard !conversationHistory.isEmpty else { return "" }

        let recentTurns = conversationHistory.suffix(3)
        var summary = "Previous conversation context:\n"

        for turn in recentTurns {
            summary += "User: \(turn.query.prefix(100))\n"
            summary += "Assistant: \(turn.response.prefix(200))\n"
        }

        return summary
    }

    private func restoreContext(from summary: String) async throws {
        guard let session = session else { return }

        let contextMessage = "Context from previous session: \(summary)"
        _ = try await session.respond(to: contextMessage)
    }

    // MARK: - Public Cache Integration Methods

    /// Restore session from cached conversation turns
    public func restoreFromCache(_ cachedTurns: [ConversationTurn]) {
        conversationHistory = cachedTurns
        totalTokensUsed = cachedTurns.reduce(0) { $0 + $1.tokenEstimate }
        Task { @MainActor in
            try await recreateSessionWithContinuity()
        }
    }

    /// Get a serializable session state for caching
    public func getSessionState() -> SessionState {
        return SessionState(
            sessionId: sessionId,
            conversationHistory: conversationHistory,
            totalTokensUsed: totalTokensUsed,
            estimatedContextSize: estimatedContextSize,
            sessionAttempts: sessionAttempts,
            lastUpdated: Date()
        )
    }

    /// Restore session from a saved state
    public func restoreFromState(_ state: SessionState) {
        sessionId = state.sessionId
        conversationHistory = state.conversationHistory
        totalTokensUsed = state.totalTokensUsed
        estimatedContextSize = state.estimatedContextSize
        sessionAttempts = state.sessionAttempts
        initializeSession()
    }

    // Context and debug helpers
    public func refreshContext() {
        sessionAttempts = 0
        initializeSession()
        isFirstInteraction = true
    }

    public func clearHistory() {
        conversationHistory.removeAll()
        totalTokensUsed = 0
        sessionAttempts = 0
        let oldSessionId = sessionId
        sessionId = UUID()
        UserDefaults.standard.removeObject(forKey: "temp_foundation_session_\(oldSessionId)")
        UserDefaults.standard.removeObject(forKey: "temp_foundation_session_\(sessionId)")
    }

    public func getConversationHistory() -> [ConversationTurn] {
        return conversationHistory
    }

    public func getSessionId() -> UUID {
        return sessionId
    }

    /// Get conversation statistics
    public func getConversationStats() -> ConversationStats {
        let sessionStart = conversationHistory.first?.timestamp ?? Date()
        return ConversationStats(
            totalTurns: conversationHistory.count,
            totalTokens: totalTokensUsed,
            averageTokensPerTurn: conversationHistory.isEmpty ? 0 : totalTokensUsed / conversationHistory.count,
            sessionDuration: Date().timeIntervalSince(sessionStart),
            contextUtilization: Double(estimatedContextSize + totalTokensUsed) / 12000.0
        )
    }
}

// MARK: - Supporting Types

public struct SessionState: Codable {
    public let sessionId: UUID
    public let conversationHistory: [FoundationChatSession.ConversationTurn]
    public let totalTokensUsed: Int
    public let estimatedContextSize: Int
    public let sessionAttempts: Int
    public let lastUpdated: Date
}

private struct TempSessionState: Codable {
    let sessionId: UUID
    let conversationHistory: [FoundationChatSession.ConversationTurn]
    let totalTokensUsed: Int
    let estimatedContextSize: Int
    let lastSaved: Date
}

public struct ConversationStats {
    public let totalTurns: Int
    public let totalTokens: Int
    public let averageTokensPerTurn: Int
    public let sessionDuration: TimeInterval
    public let contextUtilization: Double

    public var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: fabs(sessionDuration)) ?? "0s"
    }

    public var utilizationPercentage: String {
        return String(format: "%.1f%%", contextUtilization * 100)
    }
}
