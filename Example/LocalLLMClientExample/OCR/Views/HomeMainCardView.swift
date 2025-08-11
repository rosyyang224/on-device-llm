import SwiftUI

struct HomeMainCardView: View {
    let title: String
    let subtitle: String?
    let icon: String
    let actionTitle: String
    let action: (() -> Void)?

    @State private var hovering = false

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: AppTheme.Spacing.m) {
                Image(systemName: icon)
                    .pillIcon(color: AppTheme.primaryBlue)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(AppTheme.TypeScale.title2)
                        .foregroundStyle(AppTheme.onSurface)
                        .contentTransition(.opacity)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppTheme.TypeScale.body)
                            .foregroundStyle(.secondary)
                            .contentTransition(.opacity)
                    }
                    Text(actionTitle)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .padding(.top, 4)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(AppTheme.Spacing.l)
            .background(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous))
            .shadow(color: AppTheme.cardShadowColor, radius: hovering ? 18 : 12, x: 0, y: hovering ? 10 : 6)
            .scaleEffect(hovering ? 1.01 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .defaultAnimate(value: hovering)
        .padding(.horizontal, AppTheme.Spacing.l)
    }
}
