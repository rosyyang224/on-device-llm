import SwiftUI

struct HomepageClassicSummaryView: View {
    @Environment(AI.self) private var ai
    @ObservedObject var soloViewModel: HomepageSummaryViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            HomepageSummaryHeaderView(
                title: "Portfolio Summary",
                subtitle: "Generate an AI-powered summary of your entire portfolio"
            )
            HomepageAIPipelineSelector()
            Spacer()
            ScrollView {
                VStack(spacing: 16) {
                    if soloViewModel.isGenerating {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.blue)
                        Text("Generating portfolio summary...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 16)
                    } else if let summary = soloViewModel.currentSummary {
                        HomepageSummaryPanel(summary: summary, modelName: ai.model.name, color: .blue)
                    } else {
                        HomepageEmptySummaryPanel()
                    }
                }
                .padding(.horizontal, 20)
            }
            Spacer()
            Button(action: {
                Task { await soloViewModel.generateSummary() }
            }) {
                HStack {
                    if soloViewModel.isGenerating {
                        ProgressView().scaleEffect(0.8).tint(.white)
                    } else {
                        Image(systemName: "sparkles").font(.system(size: 16, weight: .semibold))
                    }
                    Text(soloViewModel.isGenerating ? "Generating..." : "Generate Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(16)
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(soloViewModel.isGenerating || ai.isLoading)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            if let error = soloViewModel.errorMessage {
                Text(error).font(.caption).foregroundColor(.red).padding(.horizontal, 20).padding(.bottom, 10)
            }
        }
    }
}
