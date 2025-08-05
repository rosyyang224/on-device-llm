//
//  FoundationChatSession.swift (Enhanced with Caching)
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/29/25.
//  Enhanced by Assistant on 7/29/25.

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
    private let userPreferenceData: String?

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

    init(container: MockDataContainer, userPreferenceData: String? = nil) {
        self.container = container
        self.userPreferenceData = userPreferenceData
        self.sessionId = UUID()
        initializeSession()
    }

    convenience init(container: MockDataContainer, sessionId: UUID, userPreferenceData: String? = nil) {
        self.init(container: container, userPreferenceData: userPreferenceData)
        self.sessionId = sessionId
        initializeSession()
    }

    private func initializeSession() {
        let getHoldingsTool = FoundationModelsGetHoldingsTool(holdingsProvider: { self.container.holdings })
        let getPortfolioValTool = FoundationModelsGetPortfolioValTool(portfolioValProvider: { self.container.portfolio_value })
        let getTransactionsTool = FoundationModelsGetTransactionsTool(transactionsProvider: { self.container.transactions })
        let getUserPrefTool = FoundationModelsGetUserPrefTool(userPreferenceProvider: {
            let prefData = self.userPreferenceData ?? userPref1
            return prefData
        })
        let tools: [any Tool] = [getHoldingsTool, getPortfolioValTool, getTransactionsTool, getUserPrefTool]
        self.session = LanguageModelSession(
            tools: tools,
            instructions: summarySysPrompt
        )
        estimatedContextSize = estimateTokenCount(String(describing: summarySysPrompt))
    }

    public func send(_ query: String) async throws -> String {
        do {
            let response = try await attemptSendQuery(query)
            let tokenEstimate = estimateTokenCount(query + response)
            let turn = ConversationTurn(query: query, response: response, tokenEstimate: tokenEstimate)
            conversationHistory.append(turn)
            totalTokensUsed += tokenEstimate
            trimConversationHistory()
            checkContextHealth()
            await updateCacheIfNeeded()
            return response
        } catch {
            if isContextLimitError(error) {
                try await recreateSessionWithContinuity()
                return try await attemptSendQuery(query)
            }
            throw error
        }
    }

    private func attemptSendQuery(_ query: String) async throws -> String {
        guard let session else { throw SessionError.sessionCreationFailed }
        
        // Detailed prompt length debugging
        print("========== PROMPT DEBUG START ==========")
        
        // Calculate individual components
        let queryLength = query.count
        let queryTokens = queryLength / 2
        
        // Conversation history length
        let historyText = conversationHistory.map { "\($0.query)\n\($0.response)" }.joined(separator: "\n")
        let historyLength = historyText.count
        let historyTokens = historyLength / 2
        
        // System instructions
        let instructionsLength = String(describing: instructions).count
        let instructionsTokens = instructionsLength / 2
        
        // Try to estimate tool context from previous calls
        let estimatedToolContext = conversationHistory.reduce(0) { total, turn in
            return total + (turn.response.contains("Tool") ? 500 : 0)
        }
        
        let totalEstimatedChars = queryLength + historyLength + instructionsLength + estimatedToolContext
        let totalEstimatedTokens = totalEstimatedChars / 2
        
        print("[PROMPT DEBUG] Query length: \(queryLength) chars (\(queryTokens) tokens)")
        print("[PROMPT DEBUG] History length: \(historyLength) chars (\(historyTokens) tokens)")
        print("[PROMPT DEBUG] Instructions length: \(instructionsLength) chars (\(instructionsTokens) tokens)")
        print("[PROMPT DEBUG] Estimated tool context: \(estimatedToolContext) chars")
        print("[PROMPT DEBUG] Total estimated: \(totalEstimatedChars) chars (\(totalEstimatedTokens) tokens)")
        print("[PROMPT DEBUG] Context utilization: \(Double(totalEstimatedTokens)/12000.0 * 100)%")

        // Detailed conversation history breakdown
        print("[PROMPT DEBUG] Conversation turns breakdown:")
        for (index, turn) in conversationHistory.enumerated() {
            let turnLength = turn.query.count + turn.response.count
            print("  Turn \(index + 1): \(turnLength) chars (Q:\(turn.query.count) + R:\(turn.response.count))")
        }

        print("[PROMPT DEBUG] About to send query to LanguageModelSession...")

        if isFirstInteraction { isFirstInteraction = false }

        let startTime = Date()

        do {
            print("[PROMPT DEBUG] Calling session.respond(to: \"\(query.prefix(50))...\")")
            let result = try await session.respond(to: query)

            let duration = Date().timeIntervalSince(startTime)
            
            print("[PROMPT DEBUG] Response received in \(duration)s")
            print("[PROMPT DEBUG] Response length: \(result.content.count) chars")
            print("========== PROMPT DEBUG END ==========")
            
            guard !result.content.isEmpty else { throw SessionError.invalidResponse }
            return result.content
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("[PROMPT DEBUG] ERROR after \(duration)s: \(error)")
            print("[PROMPT DEBUG] Error type: \(type(of: error))")
            print("[PROMPT DEBUG] Error localized: \(error.localizedDescription)")
            
            // Try to extract more details from the error
            let errorString = String(describing: error)
            print("[PROMPT DEBUG] Full error description: \(errorString)")
            
            // Check if it's specifically a context window error
            if errorString.lowercased().contains("context") {
                print("[PROMPT DEBUG] CONTEXT ERROR DETECTED!")
                print("[PROMPT DEBUG] This is where context limit was hit!")
                print("[PROMPT DEBUG] Estimated context at failure: \(totalEstimatedTokens) tokens")
            }
            
            if errorString.lowercased().contains("window") {
                print("[PROMPT DEBUG] WINDOW SIZE ERROR DETECTED!")
            }
            
            if errorString.lowercased().contains("token") {
                print("[PROMPT DEBUG] TOKEN ERROR DETECTED!")
            }
            
            print("========== PROMPT DEBUG ERROR END ==========")
            throw error
        }
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
        let warningThreshold = 3800
        let criticalThreshold = 4096
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
        return text.count / 2
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

    // Debug helper method
    public func debugCurrentContext() {
        print("========== CONTEXT STATE DEBUG ==========")
        print("Session ID: \(sessionId)")
        print("Is first interaction: \(isFirstInteraction)")
        print("Session attempts: \(sessionAttempts)")
        print("Conversation turns: \(conversationHistory.count)")
        print("Total tokens used (estimate): \(totalTokensUsed)")
        print("Estimated context size: \(estimatedContextSize)")
        
        let totalChars = conversationHistory.reduce(0) { $0 + $1.query.count + $1.response.count }
        print("Total conversation chars: \(totalChars)")
        
        // Print recent conversation snippet
        if let lastTurn = conversationHistory.last {
            print("Last query: '\(lastTurn.query.prefix(100))...'")
            print("Last response: '\(lastTurn.response.prefix(100))...'")
        }
        print("========== CONTEXT STATE DEBUG END ==========")
    }
    // Add this method to your FoundationChatSession class

    public func debugTranscript() {
        guard let session = session else {
            print("No session available")
            return
        }
        
        print("========== TRANSCRIPT DEBUG ==========")
        print("Total entries: \(session.transcript.count)")
        
        for (index, entry) in session.transcript.enumerated() {
            print("[\(index)] \(String(describing: entry))")
        }
        
        print("========== TRANSCRIPT DEBUG END ==========")
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
