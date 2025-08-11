import SwiftUI

struct ScanAgainButton: View {
    var title: String = "Scan Again"
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.primaryButtonTextColor)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.vertical, AppTheme.Spacing.s)
                .background(AppTheme.primaryButtonColor)
                .clipShape(Capsule())
                .shadow(color: AppTheme.primaryBlue.opacity(0.25), radius: 8, x: 0, y: 6)
                .scaleEffect(pressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: pressed)
        }
        .buttonStyle(.plain)
        .pressEvents {
            pressed = true
        } onRelease: {
            pressed = false
        }
    }
}

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

private struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() })
    }
}
