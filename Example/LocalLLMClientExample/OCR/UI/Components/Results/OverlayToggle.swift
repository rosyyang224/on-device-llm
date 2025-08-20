//
//  OverlayToggle.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/20/25.
//


import SwiftUI

/// Show/Hide image toggle used under the results.
public struct OverlayToggle: View {
    @Binding public var isOn: Bool
    public let toggle: () -> Void

    public init(isOn: Binding<Bool>, toggle: @escaping () -> Void) {
        self._isOn = isOn
        self.toggle = toggle
    }

    public var body: some View {
        Button {
            toggle()
        } label: {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: isOn ? "eye.slash" : "eye")
                Text(isOn ? "Hide Image" : "Show Image")
            }
            .font(.callout)
        }
    }
}
