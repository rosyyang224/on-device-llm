import SwiftUI

struct HomeQuickActionsView: View {
    let actions: [QuickAction]
    var onTap: ((QuickAction) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text("Quick Actions").sectionHeader()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.m) {
                    ForEach(actions) { action in
                        Button {
                            onTap?(action)
                        } label: {
                            HStack(spacing: AppTheme.Spacing.s) {
                                Image(systemName: action.icon)
                                    .pillIcon(color: action.tint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(action.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.onSurface)
                                    if let note = action.subtitle {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, AppTheme.Spacing.m)
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous))
                            .shadow(color: action.tint.opacity(0.15), radius: 10, x: 0, y: 6)
                            .contentTransition(.opacity)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.s)
            }
        }
        .padding(.top, AppTheme.Spacing.m)
    }
}

struct QuickAction: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String
    let tint: Color
}
