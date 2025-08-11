//
//  PassportIllustration.swift
//

import SwiftUI

struct PassportIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                .fill(AppTheme.capsuleGradient(AppTheme.primaryBlue))
                .frame(height: 140)
                .shadow(color: AppTheme.primaryBlue.opacity(0.25), radius: 12, x: 0, y: 8)

            HStack(spacing: 16) {
                Image(systemName: "rectangle.and.text.magnifyingglass")
                    .pillIcon(color: AppTheme.green)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Passport OCR")
                        .font(AppTheme.TypeScale.title2)
                        .foregroundStyle(.white)
                    Text("Import a photo to extract MRZ & fields")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.l)
        }
        .padding(.horizontal, AppTheme.Spacing.l)
    }
}
