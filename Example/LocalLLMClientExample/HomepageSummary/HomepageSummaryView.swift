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
                LoadingOverlay(progress: currentProgress)
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
