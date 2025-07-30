//
//  HomepageSummaryViewModel.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/31/25.
//

import Foundation
import LocalLLMClient
import FoundationModels

@MainActor
class HomepageSummaryViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var currentSummary: String?
    @Published var errorMessage: String?
    
    private var generateTask: Task<Void, Never>?
    private var chatViewModel: ChatViewModel?
    private var initialMessageCount: Int = 0
    
    init() {
        // Empty init - ChatViewModel will be set later via setChatViewModel
    }
    
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
    
    private func buildPortfolioSummaryPrompt() -> String {
        return """
        Please provide a comprehensive summary of my entire portfolio. Include the following aspects:
        
        1. **Overall Performance**: Key metrics, returns, and performance highlights
        2. **Asset Allocation**: Breakdown of investments across different categories
        3. **Top Holdings**: Most significant positions and their impact
        4. **Risk Assessment**: Current risk profile and diversification status
        5. **Recent Activity**: Notable changes, additions, or transactions
        6. **Market Context**: How the portfolio is positioned relative to current market conditions
        7. **Recommendations**: Any suggested adjustments or opportunities
        
        Please make the summary concise yet informative, focusing on actionable insights and key takeaways that would be valuable for portfolio decision-making.
        """
    }
}
