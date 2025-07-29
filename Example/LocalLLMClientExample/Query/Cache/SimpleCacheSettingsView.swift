//
//  SimpleCacheSettingsView.swift
//  LocalLLMClientExample
//
//  Created by Assistant on 7/29/25.
//

import SwiftUI

struct acheSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    private let cache = Cache.shared
    
    @State private var cacheStats = (responses: 0, contexts: 0, recent: 0)
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Cache Statistics") {
                    HStack {
                        Text("Cached Responses")
                        Spacer()
                        Text("\(cacheStats.responses)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Cached Contexts")
                        Spacer()
                        Text("\(cacheStats.contexts)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Recent Queries")
                        Spacer()
                        Text("\(cacheStats.recent)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Actions") {
                    Button("Clear Response Cache") {
                        cache.clearResponseCache()
                        updateStats()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Clear All Cache") {
                        showingClearAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("Info") {
                    Text("The cache stores recent responses to speed up repeated questions. It automatically manages memory usage.")
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
                Text("This will clear all cached responses and recent queries.")
            }
        }
    }
    
    private func updateStats() {
        cacheStats = cache.getCacheStats()
    }
}
