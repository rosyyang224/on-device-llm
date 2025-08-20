import SwiftUI

struct HomepageSummaryComparisonView: View {
    @ObservedObject var viewModel: HomepageSummaryViewModel
    let ai: AI

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HomepageSummaryHeaderView(
                    title: "Portfolio Summary Comparison",
                    subtitle: "Compare AI summaries across perspectives"
                )

                // --- Holdings-Focused Card ---
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Holdings-Focused")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Spacer()
                        HomepageAIPipelineSelector(ai: ai)
                    }
                    UserSummaryPanel(
                        viewModel: viewModel,
                        userType: "Holdings",
                        subtitle: "Holdings-focused analysis",
                        color: .blue,
                        aiModel: ai.model
                    )
                }
                .padding(.all, 16)
                .background(Color(.systemBlue).opacity(0.06))
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.08), radius: 4, x: 0, y: 2)

                // --- Transactions-Focused Card ---
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Transactions-Focused")
                            .font(.headline)
                            .foregroundColor(.green)
                        Spacer()
                        HomepageAIPipelineSelector(ai: ai)
                    }
                    UserSummaryPanel(
                        viewModel: viewModel,
                        userType: "Transactions",
                        subtitle: "Transactions-focused analysis",
                        color: .green,
                        aiModel: ai.model
                    )
                }
                .padding(.all, 16)
                .background(Color(.systemGreen).opacity(0.06))
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.08), radius: 4, x: 0, y: 2)

                // --- Action Button ---
                Button(action: {
                    Task {
                        await viewModel.generateSummary()
                    }
                }) {
                    HStack {
                        if viewModel.isGenerating {
                            ProgressView().scaleEffect(0.8).tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(viewModel.isGenerating
                             ? "Generating..."
                             : "Generate Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(LinearGradient(
                        gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]),
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .cornerRadius(14)
                    .shadow(color: Color.purple.opacity(0.18), radius: 6, x: 0, y: 2)
                }
                .disabled(viewModel.isGenerating || ai.isLoading)
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 8)
        }
    }
}
