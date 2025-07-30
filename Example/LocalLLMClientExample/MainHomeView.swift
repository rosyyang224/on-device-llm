import SwiftUI

struct MainHomeView: View {
    var body: some View {
        TabView {
            OCRView()
                .tabItem {
                    Label("OCR", systemImage: "viewfinder")
                }
            
            HomepageSummaryView()
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
