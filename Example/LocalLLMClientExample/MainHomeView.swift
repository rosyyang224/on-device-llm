import SwiftUI

struct MainHomeView: View {
    private let mockDataContainer = loadMockDataContainer(from: mockData)!
    @State private var aiClassic: AI?
    @State private var aiUser1: AI?
    @State private var aiUser2: AI?
    @State private var aiQuery: AI?
    @State private var summaryModeIsComparison: Bool = false
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
                aiClassic: aiClassic,
                aiUser1: aiUser1,
                aiUser2: aiUser2,
                summaryModeIsComparison: summaryModeIsComparison,
                onToggleComparison: { isComparison in
                    handleComparisonToggle(isComparison: isComparison)
                },
                requestLoadClassic: loadClassicAI,
                requestLoadUserAIs: loadUserAIs
            )
                .tabItem {
                    Label("Summary", systemImage: "text.bubble")
                }
                .tag(1)

            Group {
                if let aiQuery = aiQuery {
                    QueryView(ai: aiQuery)
                } else {
                    ProgressView("Loading Query AI...")
                }
            }
            .tabItem {
                Label("Query", systemImage: "questionmark.circle")
            }
            .tag(2)
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            if oldTab == 1 && newTab != 1 {
                cleanupAllSummaryAIs()
            }
            if newTab == 1 && !summaryModeIsComparison && aiClassic == nil {
                loadClassicAI()
            }
            if oldTab == 2 && newTab != 2 {
                if aiQuery != nil { print("[DEBUG] Dropping aiQuery instance.") }
                aiQuery = nil
            }
            if oldTab != 2 && newTab == 2 && aiQuery == nil {
                loadQueryAI()
            }
        }

        .onAppear {
            // On initial appearance, pre-load AI for selected tab if needed
            if selectedTab == 1 && !summaryModeIsComparison && aiClassic == nil {
                loadClassicAI()
            }
            if selectedTab == 2 && aiQuery == nil {
                loadQueryAI()
            }
        }
    }

    // MARK: - AI Instance Management

    private func loadClassicAI() {
        guard aiClassic == nil else { return }
        Task { @MainActor in
            print("[DEBUG] Adding aiClassic instance.")
            aiClassic = AI(mockData: mockData, userlogProvider: { "" })
        }
    }
    private func loadUserAIs() {
        Task { @MainActor in
            if aiUser1 == nil {
                print("[DEBUG] Adding aiUser1 instance.")
                aiUser1 = AI(mockData: mockData, userlogProvider: { userPref1 })
            }
            try? await Task.sleep(nanoseconds: 120_000_000)
            if aiUser2 == nil {
                print("[DEBUG] Adding aiUser2 instance.")
                aiUser2 = AI(mockData: mockData, userlogProvider: { userPref2 })
            }
        }
    }
    private func cleanupAllSummaryAIs() {
        Task { @MainActor in
            if aiClassic != nil { print("[DEBUG] Dropping aiClassic instance.") }
            if aiUser1 != nil { print("[DEBUG] Dropping aiUser1 instance.") }
            if aiUser2 != nil { print("[DEBUG] Dropping aiUser2 instance.") }
            aiClassic = nil
            aiUser1 = nil
            aiUser2 = nil
            await Task.yield()
        }
    }
    private func loadQueryAI() {
        guard aiQuery == nil else { return }
        Task { @MainActor in
            print("[DEBUG] Adding aiQuery instance.")
            aiQuery = AI(mockData: mockData, userlogProvider: { "" })
        }
    }
    private func handleComparisonToggle(isComparison: Bool) {
        summaryModeIsComparison = isComparison
        if isComparison {
            loadUserAIs()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                if aiClassic != nil { print("[DEBUG] Dropping aiClassic instance (comparison mode).") }
                aiClassic = nil
                await Task.yield()
            }
        } else {
            loadClassicAI()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                if aiUser1 != nil { print("[DEBUG] Dropping aiUser1 instance (classic mode).") }
                if aiUser2 != nil { print("[DEBUG] Dropping aiUser2 instance (classic mode).") }
                aiUser1 = nil
                aiUser2 = nil
                await Task.yield()
            }
        }
    }
}
