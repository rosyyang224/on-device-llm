//
//  FoundationChatSession.swift
//

import Foundation
import FoundationModels

@MainActor
final class FoundationChatSession {
    private var session: LanguageModelSession?

    private let continuity = ConversationContinuity(
        maxEntries: 40,
        maxTokensBudget: 4000,
        keepTailCount: 1
    )

    private let container: MockDataContainer
    private let userPreferenceData: String?

    init(container: MockDataContainer, userPreferenceData: String? = nil) {
        self.container = container
        self.userPreferenceData = userPreferenceData
        initializeSession()
    }

    private func initializeSession() {
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

    func send(_ query: String) async throws -> String {
        do {
            // Preflight: rebuild if already over budget
            _ = try? await continuity.maybeRebuildIfNeeded(recreate: recreateSession)

            let response = try await attemptSendQuery(query)
            continuity.recordTurn(query: query, response: response)

            // Postflight: rebuild if needed
            _ = try? await continuity.maybeRebuildIfNeeded(recreate: recreateSession)
            return response

        } catch {
            if isContextLimitError(error) {
                // Hard error, rebuild and retry
                _ = try await recreateSession()
                let retry = try await attemptSendQuery(query)
                continuity.recordTurn(query: query, response: retry)
                _ = try? await continuity.maybeRebuildIfNeeded(recreate: recreateSession)
                return retry
            }
            throw error
        }
    }

    func stream(_ query: String, chunkSize: Int = 8) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task { [weak self] in
                guard let self else { return }
                do {
                    _ = try? await self.continuity.maybeRebuildIfNeeded(recreate: self.recreateSession)

                    let full = try await self.attemptSendQuery(query)
                    for piece in Self.chunk(full, size: chunkSize) {
                        continuation.yield(piece)
                        try? await Task.sleep(nanoseconds: 8_0_00_000) // light pacing
                    }

                    self.continuity.recordTurn(query: query, response: full)
                    _ = try? await self.continuity.maybeRebuildIfNeeded(recreate: self.recreateSession)
                    continuation.finish()

                } catch {
                    if self.isContextLimitError(error) {
                        do {
                            _ = try await self.recreateSession()
                            let retried = try await self.attemptSendQuery(query)
                            for piece in Self.chunk(retried, size: chunkSize) {
                                continuation.yield(piece)
                                try? await Task.sleep(nanoseconds: 8_0_00_000)
                            }
                            self.continuity.recordTurn(query: query, response: retried)
                            _ = try? await self.continuity.maybeRebuildIfNeeded(recreate: self.recreateSession)
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

    private func attemptSendQuery(_ query: String) async throws -> String {
        guard let session else {
            throw NSError(domain: "FoundationChatSession", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Session not initialized"])
        }
        let result = try await session.respond(to: query)
        guard !result.content.isEmpty else {
            throw NSError(domain: "FoundationChatSession", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Empty response from model"])
        }
        return result.content
    }

    // Create a fresh session with same tools/instructions; return it
    private func recreateSession() async throws -> LanguageModelSession {
        session = nil
        initializeSession()
        guard let session else {
            throw NSError(domain: "FoundationChatSession", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to recreate session"])
        }
        return session
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

    private func isContextLimitError(_ error: Error) -> Bool {
        if case FoundationModels.LanguageModelSession.GenerationError.exceededContextWindowSize = error {
            return true
        }
        let s = error.localizedDescription.lowercased()
        return s.contains("context") && (
            s.contains("limit") || s.contains("length") || s.contains("token") || s.contains("window")
        )
    }

    func clearHistory() {
        continuity.clear()
    }

    func getConversationHistory() -> [ConversationTurn] {
        continuity.history
    }
}
