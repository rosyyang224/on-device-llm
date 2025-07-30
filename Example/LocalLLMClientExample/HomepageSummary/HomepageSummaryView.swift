import SwiftUI
import LocalLLMClient
import FoundationModels

struct HomepageSummaryView: View {
    @Environment(AI.self) private var ai
    private let mockDataContainer: MockDataContainer
    
    // Toggle for comparison mode
    @State private var showUserPrefComparison: Bool = false
    
    // For classic summary
    @StateObject private var soloViewModel = HomepageSummaryViewModel()
    // For side-by-side comparison
    @StateObject private var user1ViewModel = HomepageSummaryViewModel()
    @StateObject private var user2ViewModel = HomepageSummaryViewModel()
    
    init(mockDataContainer: MockDataContainer) {
        self.mockDataContainer = mockDataContainer
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Top toggle
                Toggle(isOn: $showUserPrefComparison) {
                    Label("Add User Preferences", systemImage: "person.2.crop.square.stack")
                }
                .toggleStyle(SwitchToggleStyle(tint: .purple))
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                if showUserPrefComparison {
                    // Double user preference comparison view
                    comparisonView
                } else {
                    // Single classic summary view
                    classicSummaryView
                }
            }
            .background(Color(red: 0.95, green: 0.95, blue: 0.97))
            .toolbar {
                ToolbarItem(placement: .principal) { EmptyView() }
            }
        }
        .disabled(ai.isLoading)
        .overlay {
            if ai.isLoading {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    Group {
                        if ai.downloadProgress < 1 {
                            ProgressView("Downloading LLM...", value: ai.downloadProgress)
                        } else {
                            ProgressView("Loading LLM...")
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
            }
        }
        .onAppear {
            // Setup single classic summary VM
            let chatVM = ChatViewModel(ai: ai, mockDataContainer: mockDataContainer)
            soloViewModel.setChatViewModel(chatVM)
            // Setup user-pref VMs
            let user1ChatVM = ChatViewModel(ai: ai, mockDataContainer: mockDataContainer)
            user1ViewModel.setChatViewModel(user1ChatVM)
            user1ViewModel.setUserActivityLog(userPref1, userType: "Holdings-Focused")
            let user2ChatVM = ChatViewModel(ai: ai, mockDataContainer: mockDataContainer)
            user2ViewModel.setChatViewModel(user2ChatVM)
            user2ViewModel.setUserActivityLog(userPref2, userType: "Transactions-Focused")
        }
#if !targetEnvironment(simulator)
        .onChange(of: ai.model, initial: true) { _, _ in
            Task { await ai.loadLLM() }
        }
#endif
    }
    
    // MARK: - Classic Single Summary View
    var classicSummaryView: some View {
        VStack(spacing: 24) {
            headerView(title: "Portfolio Summary", subtitle: "Generate an AI-powered summary of your entire portfolio")
            
            aiPipelineSelector
            
            Spacer()
            
            ScrollView {
                VStack(spacing: 16) {
                    if soloViewModel.isGenerating {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.blue)
                        Text("Generating portfolio summary...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 16)
                    } else if let summary = soloViewModel.currentSummary {
                        summaryPanel(summary: summary, modelName: ai.model.name, color: .blue)
                    } else {
                        emptySummaryPanel
                    }
                }
                .padding(.horizontal, 20)
            }
            Spacer()
            Button(action: {
                Task { await soloViewModel.generateSummary() }
            }) {
                HStack {
                    if soloViewModel.isGenerating {
                        ProgressView().scaleEffect(0.8).tint(.white)
                    } else {
                        Image(systemName: "sparkles").font(.system(size: 16, weight: .semibold))
                    }
                    Text(soloViewModel.isGenerating ? "Generating..." : "Generate Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(16)
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(soloViewModel.isGenerating || ai.isLoading)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            if let error = soloViewModel.errorMessage {
                Text(error).font(.caption).foregroundColor(.red).padding(.horizontal, 20).padding(.bottom, 10)
            }
        }
    }
    
    // MARK: - Comparison (Side-by-side) View
    var comparisonView: some View {
        VStack(spacing: 16) {
            headerView(title: "Portfolio Summary Comparison", subtitle: "Compare AI summaries for different user types")
            aiPipelineSelector
            HStack(spacing: 16) {
                UserSummaryPanel(
                    viewModel: user1ViewModel,
                    userType: "User 1",
                    subtitle: "Holdings-focused",
                    color: .blue,
                    aiModel: ai.model
                )
                UserSummaryPanel(
                    viewModel: user2ViewModel,
                    userType: "User 2",
                    subtitle: "Transactions-focused",
                    color: .green,
                    aiModel: ai.model
                )
            }
            .padding(.horizontal, 20)
            Spacer()
            Button(action: {
                Task {
                    async let s1 = user1ViewModel.generateSummary()
                    async let s2 = user2ViewModel.generateSummary()
                    _ = await (s1, s2)
                }
            }) {
                HStack {
                    if user1ViewModel.isGenerating || user2ViewModel.isGenerating {
                        ProgressView().scaleEffect(0.8).tint(.white)
                    } else {
                        Image(systemName: "sparkles").font(.system(size: 16, weight: .semibold))
                    }
                    Text(user1ViewModel.isGenerating || user2ViewModel.isGenerating ? "Generating..." : "Generate Both Summaries")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(16)
                .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(user1ViewModel.isGenerating || user2ViewModel.isGenerating || ai.isLoading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Header & Pipeline Controls (shared)
    func headerView(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    var aiPipelineSelector: some View {
        VStack(spacing: 16) {
            Text("AI Pipeline")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                PipelineToggleButton(
                    title: "Foundation",
                    isSelected: ai.model == .foundation,
                    action: { ai.model = .foundation }
                )
                PipelineToggleButton(
                    title: "MLX",
                    isSelected: ai.model.isMLX && ai.model != .foundation,
                    action: { ai.model = .qwen3_4b }
                )
                PipelineToggleButton(
                    title: "Llama.cpp",
                    isSelected: !ai.model.isMLX && ai.model != .foundation,
                    action: { ai.model = .phi4mini }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Misc UI Components
    var emptySummaryPanel: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.6))
            Text("No summary generated yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Tap the button below to generate an AI-powered summary of your portfolio")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    func summaryPanel(summary: String, modelName: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Portfolio Summary")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(modelName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(8)
            }
            Text(summary)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// -- Keep your UserSummaryPanel struct as is --


struct UserSummaryPanel: View {
    @ObservedObject var viewModel: HomepageSummaryViewModel
    let userType: String
    let subtitle: String
    let color: Color
    let aiModel: LLMModel

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(userType)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)
            .padding(.horizontal, 12)

            Divider()

            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.isGenerating {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.0)
                                .tint(color)
                            Text("Generating...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else if let summary = viewModel.currentSummary {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Summary")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(aiModel.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(color.opacity(0.2))
                                    .foregroundColor(color)
                                    .cornerRadius(4)
                            }
                            Text(summary)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineSpacing(2)
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.6))
                            Text("No summary yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(maxHeight: 300)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
