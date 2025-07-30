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
    
    // Add user activity log property
    var userActivityLog: String?
    var userType: String = "Unknown"
    
    init() {
        // Empty init - ChatViewModel will be set later via setChatViewModel
    }
    
    func setChatViewModel(_ chatViewModel: ChatViewModel) {
        self.chatViewModel = chatViewModel
    }
    
    // Method to set user activity log (call this with your user's activity data)
    func setUserActivityLog(_ activityLog: String, userType: String) {
        self.userActivityLog = activityLog
        self.userType = userType
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
        let basePrompt = """
        Please provide a comprehensive and personalized summary of my entire portfolio. 
        
        **Important**: First analyze my user preferences from my activity log to understand what I care about most, then tailor your summary accordingly.
        """
        
        if let activityLog = userActivityLog {
            return basePrompt + """
            
            My recent activity log:
            \(activityLog)
            
            Based on my preferences and activity patterns, please include:
            
            1. **Focus Areas**: Emphasize the aspects I engage with most (holdings, transactions, performance)
            2. **Preferred Assets**: Highlight my most-viewed symbols and asset classes
            3. **Geographic Focus**: Prioritize regions I'm most interested in
            4. **Timeframes**: Use my preferred date ranges for analysis
            5. **Detail Level**: Match my preferred granularity (individual securities vs portfolio-level)
            6. **Key Metrics**: Present data sorted by metrics I commonly use
            7. **Recent Activity**: Focus on transaction types I analyze most
            8. **Actionable Insights**: Provide recommendations aligned with my interests
            
            Make the summary feel personalized to my specific investment focus and behavior patterns.
            """
        } else {
            return basePrompt + """
            
            Include the following aspects:
            
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
}
