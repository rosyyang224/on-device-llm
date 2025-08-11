import SwiftUI

struct ResultCardView: View {
    let title: String
    let subtitle: String?
    let icon: String
    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: icon)
                .pillIcon(color: AppTheme.green)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.onSurface)
                    .contentTransition(.opacity)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.l)
        .card()
        .padding(.horizontal, AppTheme.Spacing.l)
    }
}
