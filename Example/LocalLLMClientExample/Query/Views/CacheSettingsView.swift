import SwiftUI

struct CacheSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    private let cache = Cache.shared

    @State private var cacheStats = (contexts: 0, tools: 0)
    @State private var showingClearAlert = false

    var body: some View {
        NavigationView {
            List {
                Section("Cache Statistics") {
                    HStack {
                        Text("Cached Tool Calls")
                        Spacer()
                        Text("\(cacheStats.tools)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Cached Contexts")
                        Spacer()
                        Text("\(cacheStats.contexts)")
                            .foregroundColor(.secondary)
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
            .navigationTitle("Cache Settings")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
#else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
#endif
            }
            .onAppear {
                updateStats()
            }
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
    }

    private func updateStats() {
        cacheStats = cache.getCacheStats()
    }
}
