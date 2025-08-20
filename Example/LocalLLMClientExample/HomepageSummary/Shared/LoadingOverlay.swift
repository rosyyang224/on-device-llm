//
//  LoadingOverlay.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/20/25.
//


import SwiftUI

struct LoadingOverlay: View {
    let progress: Double

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            Group {
                if progress < 1 {
                    ProgressView("Downloading LLM…", value: progress)
                } else {
                    ProgressView("Loading LLM…")
                }
            }
            .padding(AppTheme.Spacing.l)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
            )
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
            .padding()
        }
    }
}
