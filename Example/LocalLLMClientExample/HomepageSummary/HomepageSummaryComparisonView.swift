import SwiftUI

struct HomepageSummaryComparisonView: View {
    @Environment(AI.self) private var ai
    @ObservedObject var user1ViewModel: HomepageSummaryViewModel
    @ObservedObject var user2ViewModel: HomepageSummaryViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HomepageSummaryHeaderView(
                title: "Portfolio Summary Comparison",
                subtitle: "Compare AI summaries for different user types"
            )
            HomepageAIPipelineSelector()
            HStack(spacing: 16) {
                UserSummaryPanel(
                    viewModel: user1ViewModel,
                    userType: "User 1",
                    subtitle: "Holdings-focused",
                    color: .blue,
                    aiModel: ai.model
                )
                UserSummaryPanel(
                    viewModel: user2ViewModel,
                    userType: "User 2",
                    subtitle: "Transactions-focused",
                    color: .green,
                    aiModel: ai.model
                )
            }
            .padding(.horizontal, 20)
            Spacer()
            Button(action: {
                Task {
                    async let s1 = user1ViewModel.generateSummary()
                    async let s2 = user2ViewModel.generateSummary()
                    _ = await (s1, s2)
                }
            }) {
                HStack {
                    if user1ViewModel.isGenerating || user2ViewModel.isGenerating {
                        ProgressView().scaleEffect(0.8).tint(.white)
                    } else {
                        Image(systemName: "sparkles").font(.system(size: 16, weight: .semibold))
                    }
                    Text(user1ViewModel.isGenerating || user2ViewModel.isGenerating ? "Generating..." : "Generate Both Summaries")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(16)
                .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(user1ViewModel.isGenerating || user2ViewModel.isGenerating || ai.isLoading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}
