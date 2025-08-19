//
//  TypingBubbleView.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/12/25.
//

import SwiftUI

struct TypingBubbleView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        HStack(spacing: 6) {
            Dot(delay: 0.0, animate: $animate)
            Dot(delay: 0.15, animate: $animate)
            Dot(delay: 0.30, animate: $animate)
        }
        .padding(AppTheme.Spacing.m)
        .glassCard()
        .onAppear {
            guard !reduceMotion else { return }
            // kick off the wave
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private struct Dot: View {
        let delay: Double
        @Binding var animate: Bool

        var body: some View {
            Circle()
                .frame(width: 6, height: 6)
                .foregroundStyle(AppTheme.onSurface.opacity(0.8))
                .scaleEffect(animate ? 1.15 : 0.85)
                .opacity(animate ? 1.0 : 0.4)
                .animation(
                    .easeInOut(duration: 0.8).delay(delay).repeatForever(autoreverses: true),
                    value: animate
                )
        }
    }
}
