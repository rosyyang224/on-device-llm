import SwiftUI

@main
struct MyApp: App {
    @State private var aiInstances: (AI, AI, AI, AI)?
    
    var body: some Scene {
        WindowGroup {
            if let instances = aiInstances {
                MainHomeView(
                    aiClassic: instances.0,
                    aiUser1: instances.1,
                    aiUser2: instances.2,
                    aiQuery: instances.3
                )
            } else {
                ProgressView("Loading AI Models...")
                    .onAppear {
                        initializeAISequentially()
                    }
            }
        }
    }
    
    private func initializeAISequentially() {
        Task { @MainActor in
            // Small delays between initializations to prevent resource conflicts
            let classic = AI(mockData: mockData, userlogProvider: { "" })
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            let user1 = AI(mockData: mockData, userlogProvider: { userPref1 })
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            let user2 = AI(mockData: mockData, userlogProvider: { userPref2 })
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            let query = AI(mockData: mockData, userlogProvider: { "" })
            
            aiInstances = (classic, user1, user2, query)
        }
    }
}
