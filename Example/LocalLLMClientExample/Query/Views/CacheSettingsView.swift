import SwiftUI

struct CacheSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    private let cache = Cache.shared
    @State private var cacheStats = (contexts: 0, tools: 0)
    @State private var toolEntries: [(key: String, snippet: String)] = []
    @State private var contextEntries: [(key: String, snippet: String)] = []
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        metric(title: "Cached Tool Calls", value: "\(cacheStats.tools)")
                        metric(title: "Cached Contexts", value: "\(cacheStats.contexts)")
                    }
                    .listRowInsets(EdgeInsets())
                } header: {
                    Text("Cache Statistics")
                }

                if !toolEntries.isEmpty || !contextEntries.isEmpty {
                    Section("Cache Entries") {
                        if !toolEntries.isEmpty {
                            Text("Tool Calls")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(toolEntries, id: \.key) { entry in
                                CacheRow(key: entry.key, snippet: entry.snippet)
                            }
                        }
                        if !contextEntries.isEmpty {
                            Text("Contexts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)

                            ForEach(contextEntries, id: \.key) { entry in
                                CacheRow(key: entry.key, snippet: entry.snippet)
                            }
                        }
                    }
                }

                Section("Actions") {
                    Button {
                        showingClearAlert = true
                    } label: {
                        Label("Clear All Cache", systemImage: "trash")
                    }
                    .foregroundStyle(.red)
                }
                
                Section("Info") {
                    Text("The cache stores tool call results and session contexts to speed up repeated requests. It automatically manages memory usage.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .refreshable { updateStatsAndEntries() }
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
        .onAppear { updateStatsAndEntries() }
        .alert("Clear All Cache", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                cache.clearCache()
                updateStatsAndEntries()
            }
        } message: {
            Text("This will clear all cached tool call results and session contexts.")
        }
    }

    // MARK: - Pieces

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func updateStatsAndEntries() {
        cacheStats = cache.getCacheStats()
        toolEntries = cache.getToolEntries().map { ($0.key, makeSnippet(from: $0.value)) }
        contextEntries = cache.getContextEntries().map { ($0.key, makeSnippet(from: $0.value)) }
    }

    // Try to pretty-print JSON-like objects; otherwise describe value.
    private func makeSnippet(from value: Any) -> String {
        // JSON-compatible containers
        if let dict = value as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: dict, options: [.withoutEscapingSlashes]),
           let str = String(data: data, encoding: .utf8) {
            return clipped(str)
        }
        if let arr = value as? [Any],
           let data = try? JSONSerialization.data(withJSONObject: arr, options: [.withoutEscapingSlashes]),
           let str = String(data: data, encoding: .utf8) {
            return clipped(str)
        }
        // Strings
        if let str = value as? String { return clipped(str) }
        // Fallback
        return clipped(String(describing: value))
    }

    private func clipped(_ s: String, limit: Int = 120) -> String {
        s.count > limit ? String(s.prefix(limit)) + "…" : s
    }
}

// Simple row view with monospaced snippet + copy action
private struct CacheRow: View {
    let key: String
    let snippet: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(snippet)
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .contextMenu {
            Button {
                copyToPasteboard(snippet)
            } label: {
                Label("Copy Snippet", systemImage: "doc.on.doc")
            }
        }
        .padding(.vertical, 4)
    }

    private func copyToPasteboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}
