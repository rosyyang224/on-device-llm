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
        #if DEBUG
        print("[DEBUG] ChatViewModel.sendMessage() called")
        print("[DEBUG] inputText: '\(inputText)'")
        print("[DEBUG] isGenerating: \(isGenerating)")
        #endif

        guard !inputText.isEmpty, !isGenerating else {
            #if DEBUG
            print("[DEBUG] sendMessage() guard failed - returning early")
            #endif
            return
        }

        let currentInput = (text: inputText, images: inputAttachments)
        inputText = ""
        inputAttachments = []

        #if DEBUG
        print("[DEBUG] Current input captured: '\(currentInput.text)'")
        print("[DEBUG] Current model: \(ai.model)")
        #endif

        generateTask = Task {
            #if DEBUG
            print("[DEBUG] Inside generateTask - starting")
            #endif

            generatingText = ""
            do {
                if ai.model == .foundation {
                    #if DEBUG
                    print("[DEBUG] Using foundation model branch")
                    #endif

                    // Append user message immediately (foundationSession doesn't depend on ai.session)
                    ai.messages.append(.user(currentInput.text, attachments: currentInput.images))
                    #if DEBUG
                    print("[DEBUG] User message appended (foundation). Total messages: \(ai.messages.count)")
                    #endif

                    for try await chunk in foundationSession.stream(currentInput.text) {
                        appendChunkSafely(chunk)
                        _ = messages // force-publish
                    }

                    if !generatingText.isEmpty {
                        ai.messages.append(.assistant(generatingText))
                        #if DEBUG
                        print("[DEBUG] Assistant message appended to ai.messages (foundation)")
                        #endif
                    }

                } else {
                    
                    for try await token in try await ai.ask(currentInput.text, attachments: currentInput.images) {
                        generatingText += token
                    }
                }
            } catch {
                #if DEBUG
                print("[DEBUG] Error occurred in generateTask: \(error)")
                print("[DEBUG] Error type: \(type(of: error))")
                print("[DEBUG] Error localized: \(error.localizedDescription)")
                #endif
                ai.messages.append(.assistant("Error: \(error.localizedDescription)"))
                (inputText, inputAttachments) = currentInput
                print("[sendMessage] Error occurred:", error.localizedDescription)
            }

            #if DEBUG
            print("[DEBUG] generateTask completing - cleaning up")
            #endif
            generateTask = nil
            generatingText = ""
            #if DEBUG
            print("[DEBUG] generateTask completed")
            #endif
        }
    }

    func cancelGeneration() {
        #if DEBUG
        print("[DEBUG] cancelGeneration() called")
        #endif
        generateTask?.cancel()
        generateTask = nil
    }

    private func appendChunkSafely(_ chunk: String) {
        guard !chunk.isEmpty else { return }
        if let last = generatingText.unicodeScalars.last,
           let first = chunk.unicodeScalars.first {

            let lastIsWord   = CharacterSet.alphanumerics.contains(last)
            let firstIsWord  = CharacterSet.alphanumerics.contains(first)
            let firstIsPunct = CharacterSet.punctuationCharacters.contains(first)

            if lastIsWord && firstIsWord {
                generatingText.append(" ")
            }
            // no space before punctuation; models usually emit needed spaces
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
        return "Cache: \(stats.contexts) contexts, \(stats.tools) tools"
    }
}
