import SwiftUI

@main
struct MyApp: App {
    @State private var aiQuery: AI?
    
    var body: some Scene {
        WindowGroup {
            if let query = aiQuery {
                MainHomeView(aiQuery: query)
            } else {
                ProgressView("Loading AI Query Model...")
                    .onAppear {
                        initializeQueryAI()
                    }
            }
        }
    }
    
    private func initializeQueryAI() {
        Task { @MainActor in
            let query = AI(mockData: mockData, userlogProvider: { "" })
            aiQuery = query
        }
    }
}
