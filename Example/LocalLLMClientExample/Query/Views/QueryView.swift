import SwiftUI
import LocalLLMClient
import LocalLLMClientMLX

struct QueryView: View {
    let ai: AI
    let mockDataContainer: MockDataContainer

    @State private var viewModel: ChatViewModel
    @State private var showCacheSettings = false

    private let suggested = [
        "Do I have Apple holdings?",
        "What's my portfolio performance from Aug 2024 to Oct 2024?",
        "Summarize my full portfolio.",
        "What are my transactions last August?"
    ]

    init(ai: AI, mockDataContainer: MockDataContainer) {
        self.ai = ai
        self.mockDataContainer = mockDataContainer
        self._viewModel = State(wrappedValue: ChatViewModel(
            ai: ai,
            mockDataContainer: mockDataContainer,
            userPreferenceData: nil
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Header + suggestions (your components)
                    QueryHeaderCard()
                    SuggestedQueriesStrip(suggested: suggested)

                    // Messages
                    MessageList(
                        messages: viewModel.messages,
                        isGenerating: viewModel.isGenerating
                    )

                    // Composer
                    BottomBar(
                        text: $viewModel.inputText,
                        attachments: $viewModel.inputAttachments,
                        isGenerating: viewModel.isGenerating
                    ) { _ in
                        viewModel.sendMessage()
                    } onCancel: {
                        viewModel.cancelGeneration()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                // Loading overlay (your component)
                LLMLoadingOverlay(isLoading: ai.isLoading, progress: ai.downloadProgress)
            }
            .navigationTitle(ai.model.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCacheSettings = true
                    } label: {
                        Label("Cache", systemImage: "internaldrive")
                    }
                }
            }
            .sheet(isPresented: $showCacheSettings) {
                CacheSettingsView()
            }
        }
    }
}
