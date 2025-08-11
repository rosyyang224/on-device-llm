// HomepageSummaryView.swift
import SwiftUI
import LocalLLMClient
import FoundationModels

struct HomepageSummaryView: View {
    init(
        mockDataContainer: MockDataContainer,
        aiClassic: AI?,
        aiUser1: AI?,
        aiUser2: AI?,
        summaryModeIsComparison: Bool,
        onToggleComparison: @escaping (Bool) -> Void,
        requestLoadClassic: @escaping () -> Void,
        requestLoadUserAIs: @escaping () -> Void
    ) {
        self.mockDataContainer = mockDataContainer
        self.aiClassic = aiClassic
        self.aiUser1 = aiUser1
        self.aiUser2 = aiUser2
        self.summaryModeIsComparison = summaryModeIsComparison
        self.onToggleComparison = onToggleComparison
        self.requestLoadClassic = requestLoadClassic
        self.requestLoadUserAIs = requestLoadUserAIs
        _soloViewModel = StateObject(wrappedValue: HomepageSummaryViewModel())
        _user1ViewModel = StateObject(wrappedValue: HomepageSummaryViewModel())
        _user2ViewModel = StateObject(wrappedValue: HomepageSummaryViewModel())
    }
    
    let mockDataContainer: MockDataContainer
    let aiClassic: AI?
    let aiUser1: AI?
    let aiUser2: AI?
    let summaryModeIsComparison: Bool
    let onToggleComparison: (Bool) -> Void
    let requestLoadClassic: () -> Void
    let requestLoadUserAIs: () -> Void
    
    @StateObject private var soloViewModel = HomepageSummaryViewModel()
    @StateObject private var user1ViewModel = HomepageSummaryViewModel()
    @StateObject private var user2ViewModel = HomepageSummaryViewModel()

    var body: some View {
        let currentLoading =
            summaryModeIsComparison
            ? ((user1ViewModel.chatViewModel?.ai.isLoading ?? false) ||
               (user2ViewModel.chatViewModel?.ai.isLoading ?? false))
            : (soloViewModel.chatViewModel?.ai.isLoading ?? false)

        let currentProgress: Double =
            summaryModeIsComparison
            ? max(user1ViewModel.chatViewModel?.ai.downloadProgress ?? 0,
                  user2ViewModel.chatViewModel?.ai.downloadProgress ?? 0)
            : (soloViewModel.chatViewModel?.ai.downloadProgress ?? 0)

        NavigationStack {
            VStack(spacing: AppTheme.Spacing.m) {
                // Mode toggle
                Toggle(isOn: Binding(
                    get: { summaryModeIsComparison },
                    set: { newValue in
                        onToggleComparison(newValue)
                        if newValue { requestLoadUserAIs() } else { requestLoadClassic() }
                    }
                )) {
                    Label("Add User Preferences", systemImage: "person.2.crop.square.stack")
                }
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.purple))
                .padding(.horizontal, AppTheme.Spacing.l)
                .padding(.top, AppTheme.Spacing.m)

                // Body
                Group {
                    if summaryModeIsComparison {
                        if let aiUser1 = aiUser1, let aiUser2 = aiUser2 {
                            HomepageSummaryComparisonView(
                                user1ViewModel: user1ViewModel,
                                user2ViewModel: user2ViewModel,
                                aiUser1: aiUser1,
                                aiUser2: aiUser2
                            )
                            .transition(.opacity)
                        } else {
                            ProgressView("Loading User Preference AIs…")
                                .padding()
                                .card()
                                .padding(.horizontal, AppTheme.Spacing.l)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        }
                    } else {
                        if let aiClassic = aiClassic {
                            HomepageClassicSummaryView(
                                soloViewModel: soloViewModel,
                                ai: aiClassic
                            )
                            .transition(.opacity)
                        } else {
                            ProgressView("Loading Classic AI…")
                                .padding()
                                .card()
                                .padding(.horizontal, AppTheme.Spacing.l)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        }
                    }
                }
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
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
                    .padding()
                }
                .transition(.opacity)
            }
        }
        // Assign ChatViewModels (unchanged logic)
        .task(id: ObjectIdentifier(aiClassic as AnyObject)) {
            if let ai = aiClassic {
                print("[DEBUG] HomepageSummaryView: Assigning aiClassic to soloViewModel")
                soloViewModel.setChatViewModel(
                    ChatViewModel(ai: ai, mockDataContainer: mockDataContainer, userPreferenceData: nil)
                )
            }
        }
        .task(id: ObjectIdentifier(aiUser1 as AnyObject)) {
            if let ai = aiUser1 {
                print("[DEBUG] HomepageSummaryView: Assigning aiUser1 to user1ViewModel")
                user1ViewModel.setChatViewModel(
                    ChatViewModel(ai: ai, mockDataContainer: mockDataContainer, userPreferenceData: userPref1)
                )
            }
        }
        .task(id: ObjectIdentifier(aiUser2 as AnyObject)) {
            if let ai = aiUser2 {
                print("[DEBUG] HomepageSummaryView: Assigning aiUser2 to user2ViewModel")
                user2ViewModel.setChatViewModel(
                    ChatViewModel(ai: ai, mockDataContainer: mockDataContainer, userPreferenceData: userPref2)
                )
            }
        }
        // Keep on-demand model loading behavior as-is
    }
}
