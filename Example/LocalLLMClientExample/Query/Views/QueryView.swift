import SwiftUI

struct QueryView: View {
    let ai: AI?
    private let mockDataContainer = loadMockDataContainer(from: mockData)!

    @State private var showingCacheSettings = false

    var body: some View {
        NavigationStack {
            if let ai = ai {
                ChatView(ai: ai, viewModel: ChatViewModel(ai: ai, mockDataContainer: mockDataContainer, userPreferenceData: nil))
                    .navigationTitle("Chat")
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button {
                                showingCacheSettings = true
                            } label: {
                                Label("Cache Settings", systemImage: "archivebox")
                            }
                        }
                    }
            } else {
                ProgressView("Loading Query AI...")
            }
        }
        .sheet(isPresented: $showingCacheSettings) {
            CacheSettingsView()
                .frame(minHeight: 350)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .disabled(ai?.isLoading ?? true)
        .overlay {
            if ai?.isLoading ?? false {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    Group {
                        if (ai?.downloadProgress ?? 0) < 1 {
                            ProgressView("Downloading LLM...", value: ai?.downloadProgress ?? 0)
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
        .onChange(of: ai?.model, initial: true) { _, _ in
            if let ai = ai {
                Task {
                    await ai.loadLLM()
                }
            }
        }
#endif
    }
}
