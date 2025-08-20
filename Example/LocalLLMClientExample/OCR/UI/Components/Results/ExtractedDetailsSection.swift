//
//  ExtractedDetailsSection.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/20/25.
//


import SwiftUI

/// Section header + table for your recognized key/value pairs.
public struct ExtractedDetailsSection: View {
    let pairs: [RecognizedKeyValue]

    init(pairs: [RecognizedKeyValue]) {
        self.pairs = pairs
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text("Extracted Details")
                .font(AppTheme.TypeScale.section)
                .foregroundStyle(.primary)

            KeyValueTableView(
                pairs: pairs.asKeyValuePairs
            )
        }
    }
}

// Small helper to keep mapping noise out of your screen.
extension Array where Element == RecognizedKeyValue {
    var asKeyValuePairs: [KeyValuePair] {
        map { KeyValuePair(key: $0.key, value: $0.value ?? "") }
    }
}
