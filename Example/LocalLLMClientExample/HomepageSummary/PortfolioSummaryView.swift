import SwiftUI
import LocalLLMClient
import FoundationModels

struct HomepageSummaryView: View {
    @StateObject private var viewModel = HomepageSummaryViewModel()
    @Environment(AI.self) private var ai
    private let mockDataContainer = loadMockDataContainer(from: mockData)!
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Portfolio Summary")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Generate an AI-powered summary of your entire portfolio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Pipeline Selection
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
                            action: { ai.model = .qwen3 }
                        )
                        
                        PipelineToggleButton(
                            title: "Llama.cpp",
                            isSelected: !ai.model.isMLX && ai.model != .foundation,
                            action: { ai.model = .phi4mini }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Summary Content Area
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.isGenerating {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.blue)
                                
                                Text("Generating portfolio summary...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if let summary = viewModel.currentSummary {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Portfolio Summary")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(ai.model.name)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
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
                        } else {
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
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Generate Summary Button
                Button(action: {
                    Task {
                        await viewModel.generateSummary(using: ai, mockDataContainer: mockDataContainer)
                    }
                }) {
                    HStack {
                        if viewModel.isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text(viewModel.isGenerating ? "Generating..." : "Generate Summary")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(viewModel.isGenerating || ai.isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                }
            }
            .background(Color(red: 0.95, green: 0.95, blue: 0.97))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
        }
        .disabled(ai.isLoading)
        .overlay {
            if ai.isLoading {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
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
#if !targetEnvironment(simulator)
        .onChange(of: ai.model, initial: true) { _, _ in
            Task {
                await ai.loadLLM()
            }
        }
#endif
    }
}

struct PipelineToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    isSelected ?
                    Color.blue :
                    Color.gray.opacity(0.15)
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.clear : Color.gray.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ViewModel
@MainActor
class HomepageSummaryViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var currentSummary: String?
    @Published var errorMessage: String?
    
    private var generateTask: Task<Void, Never>?
    private var foundationSession: FoundationChatSession?
    
    func generateSummary(using ai: AI, mockDataContainer: MockDataContainer) async {
        guard !isGenerating else { return }
        
        isGenerating = true
        errorMessage = nil
        
        generateTask = Task {
            do {
                let prompt = buildPortfolioSummaryPrompt()
                let response: String
                
                if ai.model == .foundation {
                    // Use FoundationModels pipeline
                    if foundationSession == nil {
                        foundationSession = FoundationChatSession(container: mockDataContainer)
                    }
                    response = try await foundationSession!.send(prompt)
                } else {
                    // Use local LLM pipeline (MLX or llama.cpp)
                    var fullResponse = ""
                    for try await token in try await ai.ask(prompt, attachments: []) {
                        fullResponse += token
                    }
                    response = fullResponse
                }
                
                await MainActor.run {
                    self.currentSummary = response
                    self.isGenerating = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate summary: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
            
            generateTask = nil
        }
    }
    
    func cancelGeneration() {
        generateTask?.cancel()
        generateTask = nil
        isGenerating = false
    }
    
    private func buildPortfolioSummaryPrompt() -> String {
        return """
        Please provide a comprehensive summary of my entire portfolio. Include the following aspects:
        
        1. **Overall Performance**: Key metrics, returns, and performance highlights
        2. **Asset Allocation**: Breakdown of investments across different categories
        3. **Top Holdings**: Most significant positions and their impact
        4. **Risk Assessment**: Current risk profile and diversification status
        5. **Recent Activity**: Notable changes, additions, or transactions
        6. **Market Context**: How the portfolio is positioned relative to current market conditions
        7. **Recommendations**: Any suggested adjustments or opportunities
        
        Please make the summary concise yet informative, focusing on actionable insights and key takeaways that would be valuable for portfolio decision-making.
        """
    }
}

#Preview {
    HomepageSummaryView()
        .environment(AI(mockData: mockData))
}
