import SwiftUI

@main
struct MyApp: App {
    @State private var ai = AI(mockData: mockData)
    
    init() {
        AppTheme()
    }
    
    var body: some Scene {
        WindowGroup {
            MainHomeView()
                .environment(ai)
        }
    }
}
