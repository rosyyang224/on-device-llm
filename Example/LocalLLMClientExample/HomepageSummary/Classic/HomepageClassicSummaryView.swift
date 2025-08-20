// HomepageClassicSummaryView.swift — refactored to use one shared viewModel
import SwiftUI

struct HomepageClassicSummaryView: View {
    @ObservedObject var viewModel: HomepageSummaryViewModel
    let ai: AI

    @State private var stickyBarVisible: Bool = true

    var body: some View {
        ZStack {
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

                        // ===== Header =====
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

                        // ===== Pipeline selector =====
                        HomepageAIPipelineSelector(ai: ai)
                            .padding(.horizontal, AppTheme.Spacing.l)

                        // ===== Content area =====
                        Group {
                            if viewModel.isGenerating {
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

                            } else if let summary = viewModel.currentSummary {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                                    MarkdownChatText(text: summary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        .textSelection(.enabled)
                                    }
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

                        if let error = viewModel.errorMessage {
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

                // ===== Sticky footer =====
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(Divider().opacity(0.3), alignment: .top)
                        .ignoresSafeArea(edges: .bottom)
                        .frame(height: 90)

                    HStack(spacing: AppTheme.Spacing.m) {
                        Button {
                            Task { await viewModel.generateSummary() }
                        } label: {
                            HStack(spacing: AppTheme.Spacing.s) {
                                if viewModel.isGenerating {
                                    ProgressView().scaleEffect(0.9).tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(viewModel.isGenerating ? "Generating…" : "Generate Summary")
                            }
                        }
                        .buttonStyle(PillPrimaryButtonStyle())
                        .disabled(viewModel.isGenerating || ai.isLoading)
                    }
                    .frame(maxWidth: 760)
                    .padding(.horizontal, AppTheme.Spacing.l)
                }
            }
        }
    }
}
