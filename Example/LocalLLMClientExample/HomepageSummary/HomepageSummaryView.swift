import SwiftUI
import LocalLLMClient
import FoundationModels

struct HomepageSummaryView: View {
    private let mockDataContainer: MockDataContainer
    private let aiClassic: AI
    private let aiUser1: AI
    private let aiUser2: AI

    @State private var showUserPrefComparison: Bool = false
    @StateObject private var soloViewModel: HomepageSummaryViewModel
    @StateObject private var user1ViewModel: HomepageSummaryViewModel
    @StateObject private var user2ViewModel: HomepageSummaryViewModel

    init(
        mockDataContainer: MockDataContainer,
        aiClassic: AI,
        aiUser1: AI,
        aiUser2: AI
    ) {
        self.mockDataContainer = mockDataContainer
        self.aiClassic = aiClassic
        self.aiUser1 = aiUser1
        self.aiUser2 = aiUser2

        _soloViewModel = StateObject(
            wrappedValue: HomepageSummaryViewModel(
                chatVM: ChatViewModel(ai: aiClassic, mockDataContainer: mockDataContainer, userPreferenceData: nil)
            )
        )
        _user1ViewModel = StateObject(
            wrappedValue: HomepageSummaryViewModel(
                chatVM: ChatViewModel(ai: aiUser1, mockDataContainer: mockDataContainer, userPreferenceData: userPref1)
            )
        )
        _user2ViewModel = StateObject(
            wrappedValue: HomepageSummaryViewModel(
                chatVM: ChatViewModel(ai: aiUser2, mockDataContainer: mockDataContainer, userPreferenceData: userPref2)
            )
        )
    }

    var body: some View {
        let currentLoading =
            showUserPrefComparison
            ? ((user1ViewModel.chatViewModel?.ai.isLoading ?? false) ||
               (user2ViewModel.chatViewModel?.ai.isLoading ?? false))
            : (soloViewModel.chatViewModel?.ai.isLoading ?? false)

        let currentProgress: Double =
            showUserPrefComparison
            ? max(user1ViewModel.chatViewModel?.ai.downloadProgress ?? 0,
                  user2ViewModel.chatViewModel?.ai.downloadProgress ?? 0)
            : (soloViewModel.chatViewModel?.ai.downloadProgress ?? 0)

        NavigationStack {
            VStack(spacing: 20) {
                Toggle(isOn: $showUserPrefComparison) {
                    Label("Add User Preferences", systemImage: "person.2.crop.square.stack")
                }
                .toggleStyle(SwitchToggleStyle(tint: .purple))
                .padding(.horizontal, 20)
                .padding(.top, 16)

                if showUserPrefComparison {
                    HomepageSummaryComparisonView(
                        user1ViewModel: user1ViewModel,
                        user2ViewModel: user2ViewModel,
                        aiUser1: aiUser1,
                        aiUser2: aiUser2
                    )
                } else {
                    HomepageClassicSummaryView(
                        soloViewModel: soloViewModel,
                        ai: aiClassic
                    )
                }
            }
            .background(Color(red: 0.95, green: 0.95, blue: 0.97))
            .toolbar {
                ToolbarItem(placement: .principal) { EmptyView() }
            }
        }
        .disabled(currentLoading)
        .overlay {
            if currentLoading {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    Group {
                        if currentProgress < 1 {
                            ProgressView("Downloading LLM...", value: currentProgress)
                        } else {
                            ProgressView("Loading LLM...")
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
            }
        }
#if !targetEnvironment(simulator)
        .onChange(of: aiClassic.model, initial: true) { _, _ in
            Task { await aiClassic.loadLLM() }
        }
        .onChange(of: aiUser1.model, initial: true) { _, _ in
            Task { await aiUser1.loadLLM() }
        }
        .onChange(of: aiUser2.model, initial: true) { _, _ in
            Task { await aiUser2.loadLLM() }
        }
#endif
    }
}
