import SwiftUI

struct QueryView: View {
    let ai: AI
    private let mockDataContainer = loadMockDataContainer(from: mockData)!

    @State private var showingCacheSettings = false
    @State private var viewModel: ChatViewModel

    private let suggested = [
        "Summarize my holdings",
        "Top movers this week",
        "Last 10 transactions",
        "Portfolio value by sector",
        "Cash vs. equities"
    ]

    init(ai: AI) {
        self.ai = ai
        self._viewModel = State(initialValue: ChatViewModel(
            ai: ai,
            mockDataContainer: loadMockDataContainer(from: mockData)!,
            userPreferenceData: nil
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        QueryHeaderCard()
                        SuggestedQueriesStrip(suggested: suggested)
                        MessageList(messages: viewModel.messages, isGenerating: viewModel.isGenerating)
                    }
                }

                BottomBar(
                    ai: ai,
                    text: $viewModel.inputText,
                    attachments: $viewModel.inputAttachments,
                    isGenerating: viewModel.isGenerating
                ) { _ in
                    viewModel.sendMessage()
                } onCancel: {
                    viewModel.cancelGeneration()
                }
                .padding([.horizontal, .bottom])
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Chat")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button { showingCacheSettings = true } label: {
                        Label("Cache Settings", systemImage: "archivebox")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }
        }
        .sheet(isPresented: $showingCacheSettings) {
            CacheSettingsView()
                .frame(minHeight: 350)
            #if os(iOS)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            #endif
        }
        .disabled(ai.isLoading)
        .overlay {
            LLMLoadingOverlay(isLoading: ai.isLoading, progress: ai.downloadProgress)
        }
        .onChange(of: ai.model) { _, _ in
            ai.resetMessages()
        }
    }
}
