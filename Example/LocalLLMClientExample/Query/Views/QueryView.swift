import SwiftUI

struct QueryView: View {
    @Environment(AI.self) private var ai
    private let mockDataContainer = loadMockDataContainer(from: mockData)!

    @State private var showingCacheSettings = false

    var body: some View {
        NavigationStack {
            ChatView(viewModel: .init(ai: ai, mockDataContainer: mockDataContainer))
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
        }
        .sheet(isPresented: $showingCacheSettings) {
            CacheSettingsView()
                .frame(minHeight: 350)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .disabled(ai.isLoading)
        .overlay {
            if ai.isLoading {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
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
#if !targetEnvironment(simulator)
        .onChange(of: ai.model, initial: true) { _, _ in
            Task {
                await ai.loadLLM()
            }
        }
#endif
    }
}

// Example preview
#Preview {
    QueryView()
        .environment(AI(mockData: mockData))
}
