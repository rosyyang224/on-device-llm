import SwiftUI

struct MainHomeView: View {
    var body: some View {
        TabView {
            OCRView()
                .tabItem {
                    Label("OCR", systemImage: "viewfinder")
                }
            
            QueryView()
                .tabItem {
                    Label("Query", systemImage: "questionmark.circle")
                }
        }
    }
}
