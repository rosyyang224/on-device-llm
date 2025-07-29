import Foundation
import LocalLLMClient
import FoundationModels

@Observable @MainActor
final class ChatViewModel {
    private let ai: AI
    private let foundationSession: FoundationChatSession
    private let cache = Cache.shared

    init(ai: AI, mockDataContainer: MockDataContainer) {
        self.ai = ai
        self.foundationSession = FoundationChatSession(container: mockDataContainer)
    }

    var inputText = ""
    var inputAttachments: [LLMAttachment] = []

    private var generateTask: Task<Void, Never>?
    private var generatingText = ""

    var messages: [LLMInput.Message] {
        var messages = ai.messages
        if !generatingText.isEmpty, messages.last?.role != .assistant {
            messages.append(.assistant(generatingText))
        }
        return messages
    }

    var isGenerating: Bool {
        generateTask != nil
    }

    // MARK: - Message Handling

    func sendMessage() {
        guard !inputText.isEmpty, !isGenerating else { return }

        let currentInput = (text: inputText, images: inputAttachments)
        inputText = ""
        inputAttachments = []

        if ai.model == .foundation {
            ai.messages.append(.user(currentInput.text, attachments: currentInput.images))
        }

        generateTask = Task {
            generatingText = ""
            do {
                let response: String

                if ai.model == .foundation {
                    response = try await foundationSession.send(currentInput.text)
                    generatingText = response
                    print("[sendMessage] FoundationModels reply:", response)
                    ai.messages.append(.assistant(response))
                } else {
                    for try await token in try await ai.ask(currentInput.text, attachments: currentInput.images) {
                        generatingText += token
                    }
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
    }

    // MARK: - Cache Utilities

    /// Clear cache to free memory
    func clearCache() {
        cache.clearCache()
    }

    /// Get cache performance stats
    func getCacheStats() -> String {
        let stats = cache.getCacheStats()
        return "Cache: \(stats.contexts) contexts, \(stats.tools) tools"
    }
}
