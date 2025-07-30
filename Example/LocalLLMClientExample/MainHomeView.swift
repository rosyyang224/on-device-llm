import SwiftUI

struct MainHomeView: View {
    @Environment(AI.self) private var ai
    private let mockDataContainer = loadMockDataContainer(from: mockData)!
    
    var body: some View {
        TabView {
            OCRView()
                .tabItem {
                    Label("OCR", systemImage: "viewfinder")
                }
            
            HomepageSummaryView(mockDataContainer: mockDataContainer)
                .tabItem {
                    Label("Summary", systemImage: "text.bubble")
                }
            
            QueryView()
                .tabItem {
                    Label("Query", systemImage: "questionmark.circle")
                }
        }
    }
}
