//
//  QueryViewComponents.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/12/25.
//

import SwiftUI

// MARK: - Header

struct QueryHeaderCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.primaryBlue.opacity(0.12))
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryBlue)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Generate insights")
                    .font(AppTheme.TypeScale.title2)
                Text("Fast, on-device analysis of your portfolio.")
                    .font(AppTheme.TypeScale.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text("Generate")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.primaryBlue.opacity(0.16), in: Capsule())
                .foregroundStyle(AppTheme.primaryBlue)
                .overlay(
                    Capsule().stroke(AppTheme.primaryBlue.opacity(0.28), lineWidth: 0.5)
                )
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.cardShadowColor, radius: 10, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .background(AppTheme.background)
    }
}

// MARK: - Suggested chips

struct SuggestedQueriesStrip: View {
    let suggested: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested queries")
                .sectionHeader()
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggested, id: \.self) { text in
                        SuggestedChip(text: text)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
            .contentMargins(.horizontal, 0, for: .scrollContent)
        }
        .padding(.top, 6)
        .padding(.bottom, 12)
        .background(AppTheme.background)
    }
}

private struct SuggestedChip: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: AppTheme.cardShadowColor, radius: 6, x: 0, y: 3)
        .accessibilityHidden(true)
    }
}

// MARK: - Loading overlay

struct LLMLoadingOverlay: View {
    let isLoading: Bool
    let progress: Double

    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)

                Group {
                    if progress < 1 {
                        ProgressView("Downloading LLM...", value: progress)
                    } else {
                        ProgressView("Loading LLM...")
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
                .padding()
                .transition(.scale.combined(with: .opacity))
            }
            .animation(.easeInOut(duration: 0.25), value: progress)
        }
    }
}
