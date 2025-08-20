//
//  ConversationContinuity.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/21/25.
//


import Foundation
import FoundationModels

/// Owns transcript continuity, budget checks, and in-place rebuilds.
@MainActor
final class ConversationContinuity {
    // Stored history (not persisted)
    private(set) var history: [ConversationTurn] = []

    // Rebuild policy (kept consistent with your current values)
    private let maxEntries: Int
    private let maxTokensBudget: Int
    private let keepTailCount: Int

    init(maxEntries: Int = 40, maxTokensBudget: Int = 4000, keepTailCount: Int = 1) {
        self.maxEntries = maxEntries
        self.maxTokensBudget = maxTokensBudget
        self.keepTailCount = keepTailCount
    }

    // MARK: - History

    func recordTurn(query: String, response: String) {
        let tokenEstimate = estimateTokenCount(query + response)
        history.append(.init(query: query, response: response, tokenEstimate: tokenEstimate))
    }

    func clear() {
        history.removeAll()
    }

    // MARK: - Budgets

    func isOverBudget() -> Bool {
        if history.count > maxEntries { return true }
        let approxTokens = history.reduce(0) { $0 + ($1.query.count + $1.response.count) / 4 }
        return approxTokens > maxTokensBudget
    }

    // MARK: - Rebuild

    /// If over budget, rebuild the underlying session and seed minimal continuity.
    ///
    /// - Parameter recreate: async closure that recreates and returns a fresh `LanguageModelSession`.
    /// - Returns: A new session if rebuilt, otherwise `nil`.
    func maybeRebuildIfNeeded(
        recreate: @escaping () async throws -> LanguageModelSession
    ) async throws -> LanguageModelSession? {
        guard isOverBudget() else { return nil }
        return try await rebuild(recreate: recreate)
    }

    private func rebuild(
        recreate: @escaping () async throws -> LanguageModelSession
    ) async throws -> LanguageModelSession {
        // Split history into (older) head for summary + (recent) tail for verbatim seed
        let tail = Array(history.suffix(keepTailCount))
        let head = Array(history.dropLast(tail.count))

        var contextSummary = ""
        if !head.isEmpty {
            let bullets = head.prefix(8).map { t in
                "- U: \(t.query.prefix(120))\n  A: \(t.response.prefix(160))"
            }.joined(separator: "\n")
            contextSummary = "Previous context (compressed):\n" + bullets
        }

        let newSession = try await recreate()

        // Prime with a single compact seed message to avoid extra context bloat
        if !contextSummary.isEmpty || !tail.isEmpty {
            let tailText = tail
                .map { "U: \($0.query)\nA: \($0.response)" }
                .joined(separator: "\n\n")

            let seed = [
                contextSummary.isEmpty ? nil : "Context summary:\n\(contextSummary)",
                tailText.isEmpty ? nil : "Recent messages:\n\(tailText)"
            ]
            .compactMap { $0 }
            .joined(separator: "\n\n")

            _ = try await newSession.respond(to: "\(seed)\n\nAcknowledge and wait for the next user message.")
        }

        return newSession
    }

    // MARK: - Utils

    private func estimateTokenCount(_ text: String) -> Int {
        // cheap heuristic; keeps things deterministic
        text.count / 2
    }
}
