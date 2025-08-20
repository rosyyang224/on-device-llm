// HomepageSummaryView.swift
import SwiftUI
import LocalLLMClient
import FoundationModels

struct HomepageSummaryView: View {
    init(
        mockDataContainer: MockDataContainer,
        ai: AI
    ) {
        self.mockDataContainer = mockDataContainer
        self.ai = ai
        _viewModel = StateObject(wrappedValue: HomepageSummaryViewModel())
    }

    let mockDataContainer: MockDataContainer
    let ai: AI

    @StateObject private var viewModel: HomepageSummaryViewModel
    @State private var isComparison: Bool = false

    var body: some View {
        let currentLoading = ai.isLoading
        let currentProgress = ai.downloadProgress

        NavigationStack {
            VStack(spacing: AppTheme.Spacing.m) {

                // === Mode toggle (Classic vs User Prefs) ===
                HStack(spacing: AppTheme.Spacing.s) {
                    PipelineToggleButton(
                        title: "Classic",
                        isSelected: !isComparison
                    ) {
                        if isComparison {
                            isComparison = false
                            print("[DEBUG] HomepageSummaryView: switched -> Classic")
                            // Start new session for classic mode
                            ai.resetMessages()
                        }
                    }

                    PipelineToggleButton(
                        title: "User Prefs",
                        isSelected: isComparison
                    ) {
                        if !isComparison {
                            isComparison = true
                            print("[DEBUG] HomepageSummaryView: switched -> Comparison")
                            // Start new session for comparison mode
                            ai.resetMessages()
                        }
                    }
                }
                .padding(.top, AppTheme.Spacing.m)

                // ===== Optional Summary Card (shows when we have text) =====
                if let summary = viewModel.currentSummary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Portfolio Snapshot")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                            .fill(AppTheme.background)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, AppTheme.Spacing.l)
                }

                // ===== Body: Classic or Comparison =====
                Group {
                    if isComparison {
                        // Uses your shared viewModel + single AI
                        HomepageSummaryComparisonView(
                            viewModel: viewModel,
                            ai: ai
                        )
                    } else {
                        HomepageClassicSummaryView(
                            viewModel: viewModel,
                            ai: ai
                        )
                    }
                }
                .transition(.opacity)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) { EmptyView() }
            }
        }
        .disabled(currentLoading)
        .overlay {
            if currentLoading {
                ZStack {
                    Color.black.opacity(0.45).ignoresSafeArea()
                    Group {
                        if currentProgress < 1 {
                            ProgressView("Downloading LLM…", value: currentProgress)
                        } else {
                            ProgressView("Loading LLM…")
                        }
                    }
                    .padding(AppTheme.Spacing.l)
                    .background(
                        .regularMaterial,
                        in: RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
                    .padding()
                }
                .transition(.opacity)
            }
        }
        // Initialize ViewModel with shared AI instance
        .onAppear {
            print("[DEBUG] HomepageSummaryView: Setting up viewModel with shared AI")
            viewModel.setChatViewModel(
                ChatViewModel(ai: ai, mockDataContainer: mockDataContainer, userPreferenceData: nil)
            )
        }
        // Reset session when switching modes
        .onChange(of: isComparison) { _, _ in
            print("[DEBUG] HomepageSummaryView: Mode changed, resetting AI session")
            ai.resetMessages()
            viewModel.clearCurrentSummary()
        }
    }
}
