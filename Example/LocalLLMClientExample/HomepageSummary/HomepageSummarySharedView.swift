//
//  HomepageSummarySharedView.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/31/25.
//

import SwiftUI

struct HomepageSummaryHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
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
}

struct HomepageAIPipelineSelector: View {
    @Environment(AI.self) private var ai

    var body: some View {
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
}

struct HomepageEmptySummaryPanel: View {
    var body: some View {
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

struct HomepageSummaryPanel: View {
    let summary: String
    let modelName: String
    let color: Color

    var body: some View {
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
