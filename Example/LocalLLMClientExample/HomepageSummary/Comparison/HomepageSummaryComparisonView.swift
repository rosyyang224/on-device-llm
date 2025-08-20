import SwiftUI

struct HomepageSummaryComparisonView: View {
    @ObservedObject var viewModel: HomepageSummaryViewModel
    let ai: AI

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HomepageSummaryHeaderView(title: "Portfolio Summary Comparison",
                                          subtitle: "Compare AI summaries across perspectives")

                ComparisonCard(title: "Holdings-Focused", color: .blue) {
                    UserSummaryPanel(viewModel: viewModel,
                                     userType: "Holdings",
                                     subtitle: "Holdings-focused analysis",
                                     color: .blue,
                                     aiModel: ai.model)
                }

                ComparisonCard(title: "Transactions-Focused", color: .green) {
                    UserSummaryPanel(viewModel: viewModel,
                                     userType: "Transactions",
                                     subtitle: "Transactions-focused analysis",
                                     color: .green,
                                     aiModel: ai.model)
                }

                GenerateSummaryButton(isGenerating: viewModel.isGenerating,
                                      isDisabled: ai.isLoading) {
                    Task { await viewModel.generateSummary() }
                }
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 20)
        }
    }
}
