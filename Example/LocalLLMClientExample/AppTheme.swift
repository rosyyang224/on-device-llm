import SwiftUI

struct AppTheme {
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs:  CGFloat = 8
        static let s:   CGFloat = 12
        static let m:   CGFloat = 16
        static let l:   CGFloat = 20
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Radii
    struct Radius {
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 20
        static let xl: CGFloat = 28
        static let pill: CGFloat = 999
    }

    // MARK: - Typography
    struct TypeScale {
        static let titleLarge: Font = .system(.largeTitle, design: .rounded).weight(.bold)
        static let title:      Font = .system(.title, design: .rounded).weight(.bold)
        static let title2:     Font = .system(.title2, design: .rounded).weight(.semibold)
        static let section:    Font = .system(size: 18, weight: .semibold, design: .rounded)
        static let body:       Font = .system(size: 16, weight: .regular, design: .rounded)
        static let caption:    Font = .system(size: 13, weight: .regular, design: .rounded)
        static let badge:      Font = .system(size: 12, weight: .semibold, design: .rounded)
    }

    // MARK: - Colors
    static let primaryBlue   = Color(red: 0.20, green: 0.47, blue: 0.96)
    static let blueDark      = Color(red: 0.14, green: 0.36, blue: 0.78)
    static let blueLight     = Color(red: 0.78, green: 0.87, blue: 1.00)

    static let purple        = Color(red: 0.49, green: 0.39, blue: 0.98)
    static let green         = Color(red: 0.21, green: 0.75, blue: 0.46)
    static let orange        = Color(red: 0.99, green: 0.57, blue: 0.21)

    // Neutral palette (no UIKit/AppKit)
    static let lightGray     = Color(.sRGB, red: 0.95, green: 0.96, blue: 0.98, opacity: 1.0)
    static let mediumGray    = Color(.sRGB, red: 0.75, green: 0.78, blue: 0.82, opacity: 1.0)
    static let primaryGray   = Color(.sRGB, red: 0.55, green: 0.58, blue: 0.62, opacity: 1.0)

    // Surfaces
    static let background    = Color(.sRGB, red: 0.97, green: 0.98, blue: 1.00, opacity: 1.0) // subtle blue-tinted background
    static let surface       = Color(.sRGB, red: 1.00, green: 1.00, blue: 1.00, opacity: 0.92)
    static let onSurface     = Color.primary
    
    static let cardShadowColor = Color.black.opacity(0.10)


    // MARK: - Gradients
    static let heroGradient = LinearGradient(
        colors: [blueLight.opacity(0.55), primaryBlue.opacity(0.35)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func capsuleGradient(_ base: Color) -> LinearGradient {
        .linearGradient(
            Gradient(colors: [base, base.opacity(0.8)]),
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - Reusable Modifiers
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous))
            .shadow(color: AppTheme.cardShadowColor, radius: 12, x: 0, y: 6)
    }
}

struct PillIconModifier: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(
                Circle().fill(
                    RadialGradient(
                        colors: [color, color.opacity(0.7)],
                        center: .center, startRadius: 5, endRadius: 40
                    )
                )
            )
            .shadow(color: color.opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

struct SectionHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.TypeScale.section)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.top, AppTheme.Spacing.m)
    }
}

struct HeaderBackground: View {
    let image: Image?
    var body: some View {
        ZStack {
            if let image {
                image
                    .resizable()
                    .scaledToFill()
                    .overlay(
                        LinearGradient(colors: [.black.opacity(0.35), .clear],
                                       startPoint: .top, endPoint: .center)
                    )
                    .clipped()
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            } else {
                AppTheme.heroGradient
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - View helpers
extension View {
    func card() -> some View { modifier(CardModifier()) }
    func pillIcon(color: Color) -> some View { modifier(PillIconModifier(color: color)) }
    func sectionHeader() -> some View { modifier(SectionHeaderModifier()) }

    // Inclusive, gentle animations matching the sample app style
    func defaultAnimate<V: Equatable>(value: V) -> some View {
        if #available(iOS 17.0, *) {
            return self.animation(.snappy(duration: 0.28), value: value)
        } else {
            return self.animation(.easeInOut(duration: 0.28), value: value)
        }
    }
}

// MARK: - Button Color Aliases
extension AppTheme {
    static let primaryButtonColor = primaryBlue
    static let primaryButtonTextColor = Color.white
    static let secondaryButtonColor = mediumGray
    static let secondaryButtonTextColor = primaryGray
}
