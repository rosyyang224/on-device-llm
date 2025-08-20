//
//  EasyFormCard.swift
//

import SwiftUI

struct PassportHero: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                .fill(AppTheme.capsuleGradient(AppTheme.primaryBlue))
                .frame(height: 140)
                .shadow(color: AppTheme.primaryBlue.opacity(0.25), radius: 12, x: 0, y: 8)

            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.18))
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Easy Form")
                        .font(AppTheme.TypeScale.title2)
                        .foregroundStyle(.white)

                    Text("Upload a passport, national ID, or driver’s license and we’ll auto-fill your forms.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.l)
        }
        .padding(.horizontal, AppTheme.Spacing.l)
    }
}
