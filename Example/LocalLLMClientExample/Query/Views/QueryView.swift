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
                ScrollView {
                    VStack(spacing: 0) {
                        QueryHeaderCard()
                        SuggestedQueriesStrip(suggested: suggested)
                        
                        MessageList(
                            messages: viewModel.messages,
                            isGenerating: viewModel.isGenerating
                        )
                    }
                }
                
                VStack {
                    Spacer()
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
