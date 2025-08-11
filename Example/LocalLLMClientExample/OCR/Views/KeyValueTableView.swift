import SwiftUI

struct KeyValueTableView: View {
    var title: String = "Extracted Details"
    var pairs: [KeyValuePair]
    var onTapRow: ((KeyValuePair) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text(title).sectionHeader()

            LazyVStack(spacing: AppTheme.Spacing.xs) {
                ForEach(pairs) { pair in
                    Button {
                        onTapRow?(pair)
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(pair.key)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 120, alignment: .leading)
                            Text(pair.value)
                                .font(.body)
                                .foregroundStyle(AppTheme.onSurface)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, AppTheme.Spacing.m)
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, AppTheme.Spacing.l)
        }
        .padding(.top, AppTheme.Spacing.m)
    }
}

struct KeyValuePair: Identifiable, Hashable {
    let id = UUID()
    let key: String
    let value: String
}
