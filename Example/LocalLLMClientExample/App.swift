import SwiftUI

@main
struct MyApp: App {
    @StateObject private var ai = AI(mockData: mockData, userlogProvider: { "" })

    var body: some Scene {
        WindowGroup {
            MainHomeView()
                .environmentObject(ai) // one shared AI instance app-wide
        }
    }
}
