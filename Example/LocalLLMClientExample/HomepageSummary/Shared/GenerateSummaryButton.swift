//
//  GenerateSummaryButton.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/20/25.
//


import SwiftUI

struct GenerateSummaryButton: View {
    let isGenerating: Bool
    let isDisabled: Bool
    let action: () -> Void
    var title: String = "Generate Summary"

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                if isGenerating {
                    ProgressView().scaleEffect(0.9).tint(.white)
                    Text("Generating…")
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text(title)
                }
            }
        }
        .buttonStyle(PillPrimaryButtonStyle())
        .disabled(isDisabled || isGenerating)
    }
}
