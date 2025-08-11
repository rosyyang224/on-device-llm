// HomepageClassicSummaryView.swift — layout & buttons refreshed (logic unchanged)
import SwiftUI

struct HomepageClassicSummaryView: View {
    @ObservedObject var soloViewModel: HomepageSummaryViewModel
    let ai: AI

    @State private var stickyBarVisible: Bool = true

    var body: some View {
        ZStack {
            // Subtle decorative background to match TripPlanner feel
            AppTheme.background.ignoresSafeArea()
                .overlay(
                    ZStack {
                        Circle()
                            .fill(AppTheme.primaryBlue.opacity(0.10))
                            .blur(radius: 80)
                            .frame(width: 280, height: 280)
                            .offset(x: -180, y: -260)
                        Circle()
                            .fill(AppTheme.purple.opacity(0.08))
                            .blur(radius: 90)
                            .frame(width: 260, height: 260)
                            .offset(x: 220, y: -120)
                    }
                )

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {

                        HStack(alignment: .center, spacing: AppTheme.Spacing.m) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                                    .fill(AppTheme.primaryBlue.opacity(0.16))
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(AppTheme.primaryBlue)
                            }
                            .frame(width: 52, height: 52)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Portfolio Summary")
                                    .font(AppTheme.TypeScale.title2)
                                Text("Fast, on-device insights composed from your portfolio data.")
                                    .font(AppTheme.TypeScale.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.Spacing.l)
                        .padding(.vertical, AppTheme.Spacing.l)
                        .glassCard()
                        .padding(.top, AppTheme.Spacing.m)

                        // ===== Pipeline selector (glass section) =====
                        HomepageAIPipelineSelector(ai: ai)
                            .padding(.horizontal, AppTheme.Spacing.l)

                        // ===== Content area =====
                        Group {
                            if soloViewModel.isGenerating {
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

                            } else if let summary = soloViewModel.currentSummary {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                                    HomepageSummaryPanel(
                                        summary: summary,
                                        modelName: ai.model.name,
                                        color: AppTheme.primaryBlue
                                    )
                                }
                                .padding(AppTheme.Spacing.l)
                                .glassCard()
                                .transition(.opacity.combined(with: .scale))
                                .padding(.horizontal, AppTheme.Spacing.l)

                            } else {
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

                        if let error = soloViewModel.errorMessage {
                            Text(error)
                                .font(AppTheme.TypeScale.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal, AppTheme.Spacing.l)
                        }

                        Spacer(minLength: 120) // space for sticky footer
                    }
                    .frame(maxWidth: 760)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }

                // ===== Sticky footer (sleek primary pill) =====
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(Divider().opacity(0.3), alignment: .top)
                        .ignoresSafeArea(edges: .bottom)
                        .frame(height: 90)

                    HStack(spacing: AppTheme.Spacing.m) {
                        Button {
                            Task { await soloViewModel.generateSummary() }
                        } label: {
                            HStack(spacing: AppTheme.Spacing.s) {
                                if soloViewModel.isGenerating {
                                    ProgressView().scaleEffect(0.9).tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(soloViewModel.isGenerating ? "Generating…" : "Generate Summary")
                            }
                        }
                        .buttonStyle(PillPrimaryButtonStyle())
                        .disabled(soloViewModel.isGenerating || ai.isLoading)
                    }
                    .frame(maxWidth: 760)
                    .padding(.horizontal, AppTheme.Spacing.l)
                }
            }
        }
    }
}
