import SwiftUI

struct HomepageClassicSummaryView: View {
    @ObservedObject var viewModel: HomepageSummaryViewModel
    let ai: AI

    var body: some View {
        AppTheme.background
            .ignoresSafeArea()
            .overlay(contentOverlay)
    }

    // MARK: - Content

    private var contentOverlay: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Shared header
                HomepageSummaryHeaderView(
                    title: "Portfolio Summary",
                    subtitle: "Fast, on-device insights composed from your portfolio data."
                )

                // Shared pipeline selector
                HomepageAIPipelineSelector(ai: ai)
                    .padding(.horizontal, AppTheme.Spacing.l)

                // Content area
                Group {
                    if viewModel.isGenerating {
                        generatingCard
                    } else if let summary = viewModel.currentSummary, !summary.isEmpty {
                         HomepageSummaryPanel(
                             summary: summary,
                             modelName: ai.model.name,
                             color: AppTheme.primaryBlue
                         )
                         .padding(.horizontal, AppTheme.Spacing.l)
                    } else {
                        emptyCard
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(AppTheme.TypeScale.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, AppTheme.Spacing.l)
                }

                // Generate button (inside scroll, like comparison view)
                GenerateSummaryButton(
                    isGenerating: viewModel.isGenerating,
                    isDisabled: ai.isLoading
                ) {
                    Task { await viewModel.generateSummary() }
                }
                .padding(.horizontal, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.l)
            }
            .frame(maxWidth: 760)
            .padding(.top, AppTheme.Spacing.l)
        }
    }

    // MARK: - Pieces

    private var generatingCard: some View {
        VStack(spacing: AppTheme.Spacing.s) {
            ProgressView()
                .scaleEffect(1.05)
                .tint(AppTheme.primaryBlue)
            Text("Generating your portfolio summary…")
                .font(AppTheme.TypeScale.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xl)
        .glassCard()
        .padding(.horizontal, AppTheme.Spacing.l)
        .transition(.opacity)
    }

    private var emptyCard: some View {
        VStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.9))
            Text("No summary yet")
                .font(.headline.weight(.semibold))
            Text("Use the Generate button to create an AI-powered overview of your portfolio.")
                .font(AppTheme.TypeScale.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xl)
        .glassCard()
        .padding(.horizontal, AppTheme.Spacing.l)
        .transition(.opacity)
    }
}
