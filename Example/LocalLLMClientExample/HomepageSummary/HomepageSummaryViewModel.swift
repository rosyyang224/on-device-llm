import Foundation
import LocalLLMClient
import FoundationModels

@MainActor
class HomepageSummaryViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var currentSummary: String?
    @Published var errorMessage: String?
    
    private var generateTask: Task<Void, Never>?
    public var chatViewModel: ChatViewModel?
    private var initialMessageCount: Int = 0
    private var userPrefData: String?
    
    init(chatVM: ChatViewModel) {
        self.chatViewModel = chatVM
    }

    init() {}

    func setChatViewModel(_ chatViewModel: ChatViewModel) {
        self.chatViewModel = chatViewModel
    }
    
    func generateSummary() async {
        guard let chatViewModel = chatViewModel, !isGenerating else { return }
        
        isGenerating = true
        errorMessage = nil
        currentSummary = nil
        
        generateTask = Task {
            initialMessageCount = chatViewModel.messages.count
            
            // Load model on-demand if needed (non-foundation models)
            if chatViewModel.ai.model != .foundation && !chatViewModel.ai.isModelLoaded {
                await chatViewModel.ai.loadLLM()
            }
            
            chatViewModel.inputText = buildPortfolioSummaryPrompt()
            chatViewModel.sendMessage()
            
            while chatViewModel.isGenerating {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            if chatViewModel.messages.count > initialMessageCount,
               let lastMessage = chatViewModel.messages.last,
               lastMessage.role == .assistant {
                
                let response = extractTextFromMessage(lastMessage)
                
                await MainActor.run {
                    self.currentSummary = response
                    self.isGenerating = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "No response received from the model"
                    self.isGenerating = false
                }
            }
            
            generateTask = nil
        }
    }
    
    func cancelGeneration() {
        generateTask?.cancel()
        chatViewModel?.cancelGeneration()
        generateTask = nil
        isGenerating = false
    }
    
    private func extractTextFromMessage(_ message: LLMInput.Message) -> String {
        return message.content
    }
    
    func setUserPrefData(_ userPrefData: String) {
        self.userPrefData = userPrefData
    }
    
    private func buildPortfolioSummaryPrompt() -> String {
        return "Generate a comprehensive portfolio summary."
    }
}
