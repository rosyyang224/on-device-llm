import SwiftUI

struct HomeHeaderView: View {
    let title: String
    let subtitle: String
    let image: Image? // optional hero image (if nil we use gradient)
    @State private var appear = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HeaderBackground(image: image)
                .frame(height: 220)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.TypeScale.titleLarge)
                    .foregroundStyle(.white)
                    .shadow(radius: 3)
                    .contentTransition(.opacity)
                Text(subtitle)
                    .font(AppTheme.TypeScale.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .contentTransition(.opacity)
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.l)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 8)
            .onAppear { withAnimation(.easeOut(duration: 0.35)) { appear = true } }
        }
    }
}
