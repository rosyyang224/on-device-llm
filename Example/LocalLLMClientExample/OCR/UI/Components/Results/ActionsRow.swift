//
//  ActionsRow.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/20/25.
//


import SwiftUI

/// Bottom action row with Save + Scan Again.
/// Hook up the same actions you already call from `DocumentResultView`.
public struct ActionsRow: View {
    public let onSave: () -> Void
    public let onScanAgain: () -> Void

    public init(onSave: @escaping () -> Void, onScanAgain: @escaping () -> Void) {
        self.onSave = onSave
        self.onScanAgain = onScanAgain
    }

    public var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Button {
                onSave()
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save JSON")
                }
                .padding(.horizontal, AppTheme.Spacing.l)
                .padding(.vertical, AppTheme.Spacing.s)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 6)
            }

            Spacer(minLength: AppTheme.Spacing.s)

            ScanAgainButton {
                onScanAgain()
            }
        }
    }
}
