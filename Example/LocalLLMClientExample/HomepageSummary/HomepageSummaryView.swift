import SwiftUI
import LocalLLMClient
import FoundationModels

struct HomepageSummaryView: View {
    @Environment(AI.self) private var ai
    private let mockDataContainer: MockDataContainer
    
    @State private var showUserPrefComparison: Bool = false
    @StateObject private var soloViewModel = HomepageSummaryViewModel()
    @StateObject private var user1ViewModel = HomepageSummaryViewModel()
    @StateObject private var user2ViewModel = HomepageSummaryViewModel()
    
    init(mockDataContainer: MockDataContainer) {
        self.mockDataContainer = mockDataContainer
    }
    
    var body: some View {
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
                        user2ViewModel: user2ViewModel
                    )
                } else {
                    HomepageClassicSummaryView(
                        soloViewModel: soloViewModel
                    )
                }
            }
            .background(Color(red: 0.95, green: 0.95, blue: 0.97))
            .toolbar {
                ToolbarItem(placement: .principal) { EmptyView() }
            }
        }
        .disabled(ai.isLoading)
        .overlay {
            if ai.isLoading {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    Group {
                        if ai.downloadProgress < 1 {
                            ProgressView("Downloading LLM...", value: ai.downloadProgress)
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
        .onAppear {
            let chatVM = ChatViewModel(ai: ai, mockDataContainer: mockDataContainer)
            soloViewModel.setChatViewModel(chatVM)
            let user1ChatVM = ChatViewModel(ai: ai, mockDataContainer: mockDataContainer)
            user1ViewModel.setChatViewModel(user1ChatVM)
            user1ViewModel.setUserActivityLog(userPref1, userType: "Holdings-Focused")
            let user2ChatVM = ChatViewModel(ai: ai, mockDataContainer: mockDataContainer)
            user2ViewModel.setChatViewModel(user2ChatVM)
            user2ViewModel.setUserActivityLog(userPref2, userType: "Transactions-Focused")
        }
#if !targetEnvironment(simulator)
        .onChange(of: ai.model, initial: true) { _, _ in
            Task { await ai.loadLLM() }
        }
#endif
    }
}
