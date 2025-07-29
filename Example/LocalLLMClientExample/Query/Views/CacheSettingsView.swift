import SwiftUI

struct CacheSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    private let cache = Cache.shared
    @State private var cacheStats = (contexts: 0, tools: 0)
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Cache Statistics") {
                    ForEach(statsItems, id: \.title) { item in
                        HStack {
                            Text(item.title)
                            Spacer()
                            Text("\(item.value)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Clear All Cache") {
                        showingClearAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("Info") {
                    Text("The cache stores tool call results and session contexts to speed up repeated requests. It automatically manages memory usage.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .refreshable {
                updateStats()
            }
            .navigationTitle("Cache Settings")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear { updateStats() }
        .alert("Clear All Cache", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                cache.clearCache()
                updateStats()
            }
        } message: {
            Text("This will clear all cached tool call results and session contexts.")
        }
    }
    
    private var statsItems: [(title: String, value: Int)] {
        [
            ("Cached Tool Calls", cacheStats.tools),
            ("Cached Contexts", cacheStats.contexts)
        ]
    }
    
    private func updateStats() {
        cacheStats = cache.getCacheStats()
    }
}
