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
    private var foundationSession: FoundationChatSession?
    
    func generateSummary(using ai: AI, mockDataContainer: MockDataContainer) async {
        guard !isGenerating else { return }
        
        isGenerating = true
        errorMessage = nil
        
        generateTask = Task {
            do {
                let prompt = buildPortfolioSummaryPrompt()
                let response: String
                
                if ai.model == .foundation {
                    // Use FoundationModels pipeline
                    if foundationSession == nil {
                        foundationSession = FoundationChatSession(container: mockDataContainer)
                    }
                    response = try await foundationSession!.send(prompt)
                } else {
                    // Use local LLM pipeline (MLX or llama.cpp)
                    var fullResponse = ""
                    for try await token in try await ai.ask(prompt, attachments: []) {
                        fullResponse += token
                    }
                    response = fullResponse
                }
                
                await MainActor.run {
                    self.currentSummary = response
                    self.isGenerating = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate summary: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
            
            generateTask = nil
        }
    }
    
    func cancelGeneration() {
        generateTask?.cancel()
        generateTask = nil
        isGenerating = false
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