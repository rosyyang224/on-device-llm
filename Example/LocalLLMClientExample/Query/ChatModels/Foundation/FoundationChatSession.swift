//
//  FoundationChatSession.swift
//

import Foundation
import FoundationModels

@MainActor
public final class FoundationChatSession {
    // Underlying FM session (rebuilt in-place when context is large)
    private var session: LanguageModelSession?

    // Minimal continuity we own (not cached to disk)
    private var conversationHistory: [ConversationTurn] = []

    // Rebuild policy (tune as you like)
    private let maxEntries = 40           // rebuild if more than this many turns
    private let maxTokensBudget = 12_000  // rough token estimate budget
    private let keepTailCount = 8         // keep this many most-recent turns verbatim

    private let container: MockDataContainer
    private let userPreferenceData: String?

    // Simple turn model for continuity/estimates
    public struct ConversationTurn: Codable {
        public let query: String
        public let response: String
        public let timestamp: Date
        public let tokenEstimate: Int

        public init(query: String, response: String, tokenEstimate: Int) {
            self.query = query
            self.response = response
            self.timestamp = Date()
            self.tokenEstimate = tokenEstimate
        }
    }

    // MARK: - Init

    init(container: MockDataContainer, userPreferenceData: String? = nil) {
        self.container = container
        self.userPreferenceData = userPreferenceData
        initializeSession()
    }

    private func initializeSession() {
        // Attach your tools. If your tool implementations already consult Cache.shared,
        // you'll get memoized results automatically.
        let getHoldingsTool = FoundationModelsGetHoldingsTool(holdingsProvider: { self.container.holdings })
        let getPortfolioValTool = FoundationModelsGetPortfolioValTool(portfolioValProvider: { self.container.portfolio_value })
        let getTransactionsTool = FoundationModelsGetTransactionsTool(transactionsProvider: { self.container.transactions })
        let getUserPrefTool = FoundationModelsGetUserPrefTool(userPreferenceProvider: {
            self.userPreferenceData ?? userPref1
        })

        let tools: [any Tool] = [
            getHoldingsTool,
            getPortfolioValTool,
            getTransactionsTool,
            getUserPrefTool
        ]

        session = LanguageModelSession(
            tools: tools,
            instructions: instructions   // keep your existing system prompt
        )
    }

    // MARK: - Public API

    /// One-shot send that returns the full assistant response.
    public func send(_ query: String) async throws -> String {
        do {
            let response = try await attemptSendQuery(query)
            recordTurn(query: query, response: response)
            try await maybeRebuildIfNeeded()
            return response
        } catch {
            if isContextLimitError(error) {
                try await recreateSessionWithContinuity()
                let retry = try await attemptSendQuery(query)
                recordTurn(query: query, response: retry)
                try await maybeRebuildIfNeeded()
                return retry
            }
            throw error
        }
    }

    /// Convenience streaming that yields simple word chunks from the final text.
    public func stream(_ query: String, chunkSize: Int = 8) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let full = try await self.attemptSendQuery(query)

                    for piece in Self.chunk(full, size: chunkSize) {
                        continuation.yield(piece)
                        try? await Task.sleep(nanoseconds: 8_0_00_000) // light pacing
                    }

                    self.recordTurn(query: query, response: full)
                    try await self.maybeRebuildIfNeeded()
                    continuation.finish()

                } catch {
                    if self.isContextLimitError(error) {
                        do {
                            try await self.recreateSessionWithContinuity()
                            let retried = try await self.attemptSendQuery(query)
                            for piece in Self.chunk(retried, size: chunkSize) {
                                continuation.yield(piece)
                                try? await Task.sleep(nanoseconds: 8_0_00_000)
                            }
                            self.recordTurn(query: query, response: retried)
                            try await self.maybeRebuildIfNeeded()
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }
            continuation.onTermination = { _ in }
        }
    }

    // MARK: - Core send

    private func attemptSendQuery(_ query: String) async throws -> String {
        guard let session else { throw NSError(domain: "FoundationChatSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "Session not initialized"]) }
        let result = try await session.respond(to: query)
        guard !result.content.isEmpty else {
            throw NSError(domain: "FoundationChatSession", code: 2, userInfo: [NSLocalizedDescriptionKey: "Empty response from model"])
        }
        return result.content
    }

    private func recordTurn(query: String, response: String) {
        let tokenEstimate = estimateTokenCount(query + response)
        conversationHistory.append(.init(query: query, response: response, tokenEstimate: tokenEstimate))
        // (No local trimming here; we rely on rebuild gate below)
    }

    // MARK: - Rebuild logic (continuity preserved)

    private func isOverBudget() -> Bool {
        if conversationHistory.count > maxEntries { return true }
        let approxTokens = conversationHistory.reduce(0) { $0 + ($1.query.count + $1.response.count) / 4 }
        return approxTokens > maxTokensBudget
    }

    private func maybeRebuildIfNeeded() async throws {
        if isOverBudget() {
            try await recreateSessionWithContinuity()
        }
    }

    /// Rebuilds the underlying session and seeds it with a compact summary + recent tail.
    private func recreateSessionWithContinuity() async throws {
        // Split history into summary head and recent tail
        let keepTail = Array(conversationHistory.suffix(keepTailCount))
        let summarizeHead = Array(conversationHistory.dropLast(keepTail.count))

        var contextSummary = ""
        if !summarizeHead.isEmpty {
            let bullets = summarizeHead.prefix(8).map { t in
                "- U: \(t.query.prefix(120))\n  A: \(t.response.prefix(160))"
            }.joined(separator: "\n")
            contextSummary = "Previous context (compressed):\n" + bullets
        }

        // Recreate the FM session with the same tools/instructions
        session = nil
        initializeSession()
        guard let session else {
            throw NSError(domain: "FoundationChatSession", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to recreate session"])
        }

        // Lightly “prime” continuity without re-running tools:
        if !contextSummary.isEmpty {
            _ = try await session.respond(to: "Context summary:\n\(contextSummary)\n\nContinue the conversation.")
        }
        if !keepTail.isEmpty {
            let tailText = keepTail.map { "U: \($0.query)\nA: \($0.response)" }.joined(separator: "\n\n")
            _ = try await session.respond(to: "Recent messages for continuity:\n\(tailText)\n\nAcknowledge and wait for the next user message.")
        }
    }

    // MARK: - Helpers

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

    private func isContextLimitError(_ error: Error) -> Bool {
        let s = error.localizedDescription.lowercased()
        return s.contains("context") && (s.contains("limit") || s.contains("length") || s.contains("token"))
    }

    private func estimateTokenCount(_ text: String) -> Int {
        // rough heuristic; keep cheap & deterministic
        return text.count / 2
    }

    // MARK: - Public maintenance (optional)

    public func clearHistory() {
        conversationHistory.removeAll()
        // Do not clear the session unless you want a completely fresh start:
        // session = nil; initializeSession()
    }

    public func getConversationHistory() -> [ConversationTurn] {
        conversationHistory
    }
}
