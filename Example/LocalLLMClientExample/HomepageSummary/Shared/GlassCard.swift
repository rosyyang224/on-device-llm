//
//  GlassCard.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/12/25.
//

import SwiftUI

struct GlassCard: ViewModifier {
    var blur: Material = .ultraThinMaterial
    func body(content: Content) -> some View {
        content
            .background(blur, in: RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.55), lineWidth: 0.6)
            )
            .shadow(color: AppTheme.cardShadowColor, radius: 14, x: 0, y: 8)
    }
}
extension View { func glassCard() -> some View { modifier(GlassCard()) } }

struct PillPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.primaryButtonTextColor)
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(
                ZStack {
                    AppTheme.capsuleGradient(AppTheme.primaryButtonColor)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous))
                    RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                        .fill(.white.opacity(configuration.isPressed ? 0.12 : 0.06))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.6)
            )
            .shadow(color: AppTheme.primaryBlue.opacity(configuration.isPressed ? 0.15 : 0.28),
                    radius: configuration.isPressed ? 8 : 16, x: 0, y: configuration.isPressed ? 4 : 10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

struct PillGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 0.6))
            .shadow(color: AppTheme.cardShadowColor, radius: configuration.isPressed ? 4 : 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
