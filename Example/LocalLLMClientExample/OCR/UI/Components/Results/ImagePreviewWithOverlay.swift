//
//  ImagePreviewWithOverlay.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/20/25.
//

import SwiftUI
import Vision

public struct ImagePreviewWithOverlay: View {
    public let image: CGImage
    private let observations: [VNRecognizedTextObservation]

    init(image: CGImage, keyValuePairs: [RecognizedKeyValue]) {
        self.image = image
        self.observations = keyValuePairs.compactMap { $0.keyTextObservation }
    }

    public var body: some View {
        ZStack {
            GeometryReader { geo in
                Image(decorative: image, scale: 1.0, orientation: .up)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width)
                    .clipped()
                    .overlay(
                        TextOverlayBox(observations: observations)
                    )
            }
            .frame(height: 260)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                .strokeBorder(.white.opacity(0.6), lineWidth: 0.5)
        )
        .card()
    }
}
