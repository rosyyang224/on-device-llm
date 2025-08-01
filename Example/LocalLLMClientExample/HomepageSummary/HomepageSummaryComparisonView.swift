import SwiftUI

struct HomepageSummaryComparisonView: View {
    @ObservedObject var user1ViewModel: HomepageSummaryViewModel
    @ObservedObject var user2ViewModel: HomepageSummaryViewModel
    let aiUser1: AI
    let aiUser2: AI

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HomepageSummaryHeaderView(
                    title: "Portfolio Summary Comparison",
                    subtitle: "Compare AI summaries for different user types"
                )

                // --- User 1 Card ---
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("User 1")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Spacer()
                        HomepageAIPipelineSelector(ai: aiUser1)
                    }
                    UserSummaryPanel(
                        viewModel: user1ViewModel,
                        userType: "User 1",
                        subtitle: "Holdings-focused",
                        color: .blue,
                        aiModel: aiUser1.model
                    )
                }
                .padding(.all, 16)
                .background(Color(.systemBlue).opacity(0.06))
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.08), radius: 4, x: 0, y: 2)

                // --- User 2 Card ---
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("User 2")
                            .font(.headline)
                            .foregroundColor(.green)
                        Spacer()
                        HomepageAIPipelineSelector(ai: aiUser2)
                    }
                    UserSummaryPanel(
                        viewModel: user2ViewModel,
                        userType: "User 2",
                        subtitle: "Transactions-focused",
                        color: .green,
                        aiModel: aiUser2.model
                    )
                }
                .padding(.all, 16)
                .background(Color(.systemGreen).opacity(0.06))
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.08), radius: 4, x: 0, y: 2)

                // --- Action Button ---
                Button(action: {
                    Task {
                        await user1ViewModel.generateSummary()
                        await user2ViewModel.generateSummary()
                    }
                }) {
                    HStack {
                        if user1ViewModel.isGenerating || user2ViewModel.isGenerating {
                            ProgressView().scaleEffect(0.8).tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(user1ViewModel.isGenerating || user2ViewModel.isGenerating
                             ? "Generating..."
                             : "Generate Both Summaries")
                        .font(.headline)
                        .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(LinearGradient(gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]),
                                               startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
                    .shadow(color: Color.purple.opacity(0.18), radius: 6, x: 0, y: 2)
                }
                .disabled(
                    user1ViewModel.isGenerating
                    || user2ViewModel.isGenerating
                    || aiUser1.isLoading
                    || aiUser2.isLoading
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 8)
        }
    }
}
