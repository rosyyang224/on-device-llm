import SwiftUI

struct MainHomeView: View {
    private let mockDataContainer = loadMockDataContainer(from: mockData)!
    
    private let aiClassic: AI
    private let aiUser1: AI
    private let aiUser2: AI
    private let aiQuery: AI

    init(aiClassic: AI, aiUser1: AI, aiUser2: AI, aiQuery: AI) {
        self.aiClassic = aiClassic
        self.aiUser1 = aiUser1
        self.aiUser2 = aiUser2
        self.aiQuery = aiQuery
    }

    var body: some View {
        TabView {
            Tab("OCR", systemImage: "viewfinder") {
                OCRView()
            }
            
            Tab("Summary", systemImage: "text.bubble") {
                HomepageSummaryView(
                    mockDataContainer: mockDataContainer,
                    aiClassic: aiClassic,
                    aiUser1: aiUser1,
                    aiUser2: aiUser2
                )
            }
            
            Tab("Query", systemImage: "questionmark.circle") {
                QueryView(ai: aiQuery)
            }
        }
    }
}
