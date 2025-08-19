import Foundation
import LocalLLMClient
import FoundationModels

@Observable @MainActor
final class ChatViewModel {
    public let ai: AI
    public let foundationSession: FoundationChatSession
    private let cache = Cache.shared

    init(ai: AI, mockDataContainer: MockDataContainer, userPreferenceData: String?) {
        self.ai = ai
        self.foundationSession = FoundationChatSession(container: mockDataContainer, userPreferenceData: userPreferenceData)
    }

    var inputText = ""
    var inputAttachments: [LLMAttachment] = []

    private var generateTask: Task<Void, Never>?
    private var generatingText = ""

    var messages: [LLMInput.Message] {
        var msgs = ai.messages
        if !generatingText.isEmpty, msgs.last?.role != .assistant {
            msgs.append(.assistant(generatingText))
        }
        return msgs
    }

    var isGenerating: Bool { generateTask != nil }

    // MARK: - Message Handling

    func sendMessage() {
        guard !inputText.isEmpty, !isGenerating else { return }

        let currentInput = (text: inputText, images: inputAttachments)
        inputText = ""
        inputAttachments = []

        // Always append the user message ourselves (keeps history in ai.messages)
        ai.messages.append(.user(currentInput.text, attachments: currentInput.images))

        generateTask = Task {
            generatingText = ""
            do {
                if ai.model == .foundation {
                    for try await chunk in foundationSession.stream(currentInput.text) {
                        appendChunkSafely(chunk)
                        // Force-publish (array element mutation won’t publish)
                        _ = messages
                    }
                    // preserve final text in message history
                    if !generatingText.isEmpty {
                        ai.messages.append(.assistant(generatingText))
                    }
                } else {
                    // Non-foundation (your existing streaming path)
                    if !ai.isModelLoaded { await ai.loadLLM() }
                    for try await token in try await ai.ask(currentInput.text, attachments: currentInput.images) {
                        generatingText += token
                        _ = messages
                    }
                    if !generatingText.isEmpty {
                        ai.messages.append(.assistant(generatingText))
                    }
                }
            } catch is CancellationError {
                // Keep whatever partial we had, append as assistant so the user doesn’t lose it
                if !generatingText.isEmpty {
                    ai.messages.append(.assistant(generatingText))
                }
            } catch {
                ai.messages.append(.assistant("Error: \(error.localizedDescription)"))
                (inputText, inputAttachments) = currentInput
                print("[sendMessage] Error occurred:", error.localizedDescription)
            }

            generateTask = nil
            generatingText = ""
        }
    }

    func cancelGeneration() {
        generateTask?.cancel()
        generateTask = nil
        // do not clear `generatingText` here; let the task append the partial on cancel
    }
    
    private func appendChunkSafely(_ chunk: String) {
        guard !chunk.isEmpty else { return }
        if let last = generatingText.unicodeScalars.last,
           let first = chunk.unicodeScalars.first {

            let lastIsWord   = CharacterSet.alphanumerics.contains(last)
            let firstIsWord  = CharacterSet.alphanumerics.contains(first)
            let firstIsPunct = CharacterSet.punctuationCharacters.contains(first)

            // Insert a space only when joining two “wordy” pieces
            if lastIsWord && firstIsWord {
                generatingText.append(" ")
            }
            // (no space before punctuation; models already emit spaces after punctuation)
        }
        generatingText.append(chunk)
    }
    // MARK: - Cache Utilities

    /// Clear cache to free memory
    func clearCache() {
        cache.clearCache()
    }

    /// Get cache performance stats
    func getCacheStats() -> String {
        let stats = cache.getCacheStats()
        return "Cache.contexts) contexts, \(stats.tools) tools"
    }
}
