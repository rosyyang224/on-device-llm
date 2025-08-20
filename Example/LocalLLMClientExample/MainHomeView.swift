import SwiftUI

struct MainHomeView: View {
    @EnvironmentObject var ai: AI
    private let mockDataContainer = loadMockDataContainer(from: mockData)!
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            OCRView()
                .tabItem {
                    Label("OCR", systemImage: "viewfinder")
                }
                .tag(0)

            HomepageSummaryView(
                mockDataContainer: mockDataContainer,
                ai: ai
            )
            .tabItem {
                Label("Summary", systemImage: "text.bubble")
            }
            .tag(1)

            QueryView(
                ai: ai,
                mockDataContainer: mockDataContainer
            )
            .tabItem {
                Label("Query", systemImage: "questionmark.circle")
            }
            .tag(2)
        }
        .overlay {
            if ai.isLoading {
                ProgressView(ai.downloadProgress < 1 ? "Downloading LLM..." : "Loading LLM...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .disabled(ai.isLoading)
        .onChange(of: ai.model, initial: true) { _, _ in
            Task { await ai.loadLLM() }
        }
    }
}
