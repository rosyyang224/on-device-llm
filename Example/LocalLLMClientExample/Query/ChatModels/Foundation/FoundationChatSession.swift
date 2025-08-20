//
//  FoundationChatSession.swift (Single Chat Flow + Context Rebuild; no temp-session persistence)
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/29/25.
//  Minimal patch by Assistant
//

import Foundation
import FoundationModels

@MainActor
public final class FoundationChatSession {
    private var session: LanguageModelSession?
    private var isFirstInteraction = true

    // ===== Session state =====
    private var conversationHistory: [ConversationTurn] = []
    private var sessionAttempts = 0
    private let maxSessionAttempts = 3

    // (kept for local trimming; rebuild uses separate thresholds below)
    private let maxHistoryLength = 10

    // ===== Context tracking =====
    private var totalTokensUsed: Int = 0
    private var estimatedContextSize: Int = 0

    // ===== Rebuild thresholds =====
    private let maxEntries = 40                // total entries allowed before rebuild
    private let maxTokensBudget = 12000        // rough model context estimate
    private let keepTailCount = 8              // how many recent entries to retain verbatim

    // ===== IDs (kept; but no temp-session persistence) =====
    private(set) public var sessionId: UUID

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

    // MARK: - Init

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
            instructions: instructions
        )
        // very rough initial estimate
        estimatedContextSize = estimateTokenCount(String(describing: instructions))
    }

    // MARK: - Public: stream & send

    public func stream(_ query: String, chunkSize: Int = 8) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let full = try await attemptSendQuery(query)

                    // yield in simple word chunks
                    for piece in Self.chunk(full, size: chunkSize) {
                        continuation.yield(piece)
                        try await Task.sleep(nanoseconds: 8_0_00_000)
                    }

                    let tokenEstimate = estimateTokenCount(query + full)
                    let turn = ConversationTurn(query: query, response: full, tokenEstimate: tokenEstimate)
                    conversationHistory.append(turn)
                    totalTokensUsed += tokenEstimate

                    trimConversationHistory()
                    checkContextHealth() // now delegates to maybeRebuildIfNeeded()

                    continuation.finish()
                } catch {
                    if isContextLimitError(error) {
                        do {
                            try await recreateSessionWithContinuity()
                            let retried = try await attemptSendQuery(query)
                            for piece in Self.chunk(retried, size: chunkSize) {
                                continuation.yield(piece)
                                try await Task.sleep(nanoseconds: 8_0_00_000)
                            }
                            let tokenEstimate = estimateTokenCount(query + retried)
                            let turn = ConversationTurn(query: query, response: retried, tokenEstimate: tokenEstimate)
                            conversationHistory.append(turn)
                            totalTokensUsed += tokenEstimate

                            trimConversationHistory()
                            checkContextHealth()

                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }
            continuation.onTermination = { @Sendable _ in }
        }
    }

    private static func chunk(_ s: String, size: Int) -> [String] {
        guard size > 0 else { return [s] }
        var out: [String] = []
        let tokens = s.split(separator: " ", omittingEmptySubsequences: false)
        var buffer: [Substring] = []
        buffer.reserveCapacity(size)
        for t in tokens {
            buffer.append(t)
            if buffer.count >= size {
                out.append(buffer.joined(separator: " "))
                buffer.removeAll(keepingCapacity: true)
            }
        }
        if !buffer.isEmpty { out.append(buffer.joined(separator: " ")) }
        return out
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

            return response
        } catch {
            if isContextLimitError(error) {
                try await recreateSessionWithContinuity()
                return try await attemptSendQuery(query)
            }
            throw error
        }
    }

    // MARK: - Core query

    private func attemptSendQuery(_ query: String) async throws -> String {
        guard let session else { throw SessionError.sessionCreationFailed }

        // ===== Prompt debug (unchanged) =====
        print("========== PROMPT DEBUG START ==========")
        let queryLength = query.count
        let queryTokens = queryLength / 2
        let historyText = conversationHistory.map { "\($0.query)\n\($0.response)" }.joined(separator: "\n")
        let historyLength = historyText.count
        let historyTokens = historyLength / 2
        let instructionsLength = String(describing: instructions).count
        let instructionsTokens = instructionsLength / 2
        let estimatedToolContext = conversationHistory.reduce(0) { total, turn in
            total + (turn.response.contains("Tool") ? 500 : 0)
        }
        let totalEstimatedChars = queryLength + historyLength + instructionsLength + estimatedToolContext
        let totalEstimatedTokens = totalEstimatedChars / 2

        print("[PROMPT DEBUG] Query length: \(queryLength) chars (\(queryTokens) tokens)")
        print("[PROMPT DEBUG] History length: \(historyLength) chars (\(historyTokens) tokens)")
        print("[PROMPT DEBUG] Instructions length: \(instructionsLength) chars (\(instructionsTokens) tokens)")
        print("[PROMPT DEBUG] Estimated tool context: \(estimatedToolContext) chars")
        print("[PROMPT DEBUG] Total estimated: \(totalEstimatedChars) chars (\(totalEstimatedTokens) tokens)")
        print("[PROMPT DEBUG] Context utilization: \(Double(totalEstimatedTokens)/12000.0 * 100)%")
        print("[PROMPT DEBUG] Conversation turns breakdown:")
        for (index, turn) in conversationHistory.enumerated() {
            let turnLength = turn.query.count + turn.response.count
            print("  Turn \(index + 1): \(turnLength) chars (Q:\(turn.query.count) + R:\(turn.response.count))")
        }
        print("[PROMPT DEBUG] About to send query to LanguageModelSession...")

        if isFirstInteraction { isFirstInteraction = false }

        // ===== Metrics =====
        let startTime = Date()
        var samplerTask: Task<Double, Never>? = nil
        samplerTask = Task.detached {
            var peak = MemoryUsage.residentMB()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                let now = MemoryUsage.residentMB()
                if now > peak { peak = now }
            }
            return peak
        }
        defer { samplerTask?.cancel() }

        do {
            print("[PROMPT DEBUG] 🚀 Calling session.respond(to: \"\(query.prefix(50))...\")")
            let result = try await session.respond(to: query)

            samplerTask?.cancel()
            let peak = await samplerTask?.value ?? -1
            let duration = Date().timeIntervalSince(startTime)

            print("[METRICS] Response in \(String(format: "%.2f", duration))s")
            if peak >= 0 { print("[METRICS] Peak RAM: \(String(format: "%.1f", peak)) MB") }

            print("[PROMPT DEBUG] Response length: \(result.content.count) chars")
            print("========== PROMPT DEBUG END ==========")

            guard !result.content.isEmpty else { throw SessionError.invalidResponse }
            return result.content
        } catch {
            samplerTask?.cancel()
            _ = await samplerTask?.value

            let duration = Date().timeIntervalSince(startTime)
            print("[PROMPT DEBUG] ❌ ERROR after \(duration)s: \(error)")
            print("[PROMPT DEBUG] Error type: \(type(of: error))")
            print("[PROMPT DEBUG] Error localized: \(error.localizedDescription)")
            let errorString = String(describing: error)
            print("[PROMPT DEBUG] Full error description: \(errorString)")
            if errorString.lowercased().contains("context") {
                print("[PROMPT DEBUG] 🎯 CONTEXT ERROR DETECTED!")
                print("[PROMPT DEBUG] Estimated context at failure: \(totalEstimatedTokens) tokens")
            }
            if errorString.lowercased().contains("window") {
                print("[PROMPT DEBUG] 🎯 WINDOW SIZE ERROR DETECTED!")
            }
            if errorString.lowercased().contains("token") {
                print("[PROMPT DEBUG] 🎯 TOKEN ERROR DETECTED!")
            }
            print("========== PROMPT DEBUG ERROR END ==========")
            throw error
        }
    }

    // MARK: - Rebuild with continuity (NEW behavior; replaces temp-session persistence)

    private func isOverBudget() -> Bool {
        // quick estimate: number of entries or rough tokens
        if conversationHistory.count > maxEntries { return true }
        let approxTokens = conversationHistory.reduce(0) { $0 + ($1.query.count + $1.response.count) / 4 }
        return approxTokens > maxTokensBudget
    }

    private func maybeRebuildIfNeeded() {
        if isOverBudget() {
            Task { try await recreateSessionWithContinuity() }
        }
    }

    private func recreateSessionWithContinuity() async throws {
        // Build a compact seed: compressed summary of older turns + keep recent turns
        let nonSystem = conversationHistory // your turns are already user/assistant pairs
        let keepTail = Array(nonSystem.suffix(keepTailCount))
        let summarizeHead = Array(nonSystem.dropLast(keepTail.count))

        // small, deterministic summary of older context
        var contextSummary = ""
        if !summarizeHead.isEmpty {
            let bullets = summarizeHead.prefix(8).map { t in
                "- U: \(t.query.prefix(120))\n  A: \(t.response.prefix(160))"
            }.joined(separator: "\n")
            contextSummary = "Previous context (compressed):\n" + bullets
        }

        // rebuild underlying session with same tools/config
        session = nil
        isFirstInteraction = true
        initializeSession()
        guard let session else { throw SessionError.sessionCreationFailed }

        // Replay a single compact history message so the model “remembers”
        if !contextSummary.isEmpty {
            _ = try await session.respond(to: "Context summary:\n\(contextSummary)\n\nContinue the conversation.")
        }

        // Re-append the recent tail turns as plain text “reminders” (optional, cheap)
        if !keepTail.isEmpty {
            let tailText = keepTail.map { "U: \($0.query)\nA: \($0.response)" }.joined(separator: "\n\n")
            _ = try await session.respond(to: "Recent messages for continuity:\n\(tailText)\n\nAcknowledge and wait for the next user message.")
        }
    }

    // MARK: - Health & trimming

    private func checkContextHealth() {
        // Old heuristic replaced with rebuild gate
        maybeRebuildIfNeeded()
    }

    private func trimConversationHistory() {
        // keep early 2 + most recent (maxHistoryLength - 2)
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

    // MARK: - Public helpers

    public func refreshContext() {
        sessionAttempts = 0
        initializeSession()
        isFirstInteraction = true
    }

    public func clearHistory() {
        conversationHistory.removeAll()
        totalTokensUsed = 0
        sessionAttempts = 0
        sessionId = UUID()
        // Removed: no temp-session persistence in UserDefaults anymore
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

    // MARK: - (Kept) SessionState/Stats types

    public struct SessionState: Codable {
        public let sessionId: UUID
        public let conversationHistory: [FoundationChatSession.ConversationTurn]
        public let totalTokensUsed: Int
        public let estimatedContextSize: Int
        public let sessionAttempts: Int
        public let lastUpdated: Date
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
}
