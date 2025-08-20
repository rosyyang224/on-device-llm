import SwiftUI

struct PipelineToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(
                    Group {
                        if isSelected {
                            AppTheme.capsuleGradient(AppTheme.primaryBlue)
                        } else {
                            Color.white.opacity(0.6)
                        }
                    }
                )
                .clipShape(Capsule())
                .shadow(color: (isSelected ? AppTheme.primaryBlue : .black).opacity(0.12),
                        radius: hovering ? 8 : 6, x: 0, y: hovering ? 4 : 3)
                .scaleEffect(hovering ? 1.01 : 1.0)
                .animation(.snappy(duration: 0.18), value: hovering)
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .onHover { hovering = $0 }
        #endif
    }
}
