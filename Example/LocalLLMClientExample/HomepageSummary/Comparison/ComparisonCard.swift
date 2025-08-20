//
//  ComparisonCard.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/20/25.
//


import SwiftUI

struct ComparisonCard<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                Spacer()
            }
            content
        }
        .padding(16)
        .background(color.opacity(0.06))
        .cornerRadius(16)
        .shadow(color: color.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}
