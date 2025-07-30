//
//  HomepageSummaryView.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/31/25.
//


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

#Preview {
    HomepageSummaryView()
        .environment(AI(mockData: mockData))
}