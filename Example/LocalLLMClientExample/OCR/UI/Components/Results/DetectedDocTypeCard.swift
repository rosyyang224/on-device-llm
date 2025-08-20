//
//  DetectedDocTypeCard.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/20/25.
//


import SwiftUI

/// Thin wrapper so `DocumentResultView` reads like a storyboard line.
public struct DetectedDocTypeCard: View {
    public let text: String

    public init(text: String) { self.text = text }

    public var body: some View {
        ResultCardView(
            title: "Detected Document",
            subtitle: text,
            icon: "doc.text.magnifyingglass"
        )
    }
}
