import SwiftUI
import Vision

struct TextOverlayBox: View {
    var observations: [VNRecognizedTextObservation]

    var body: some View {
        GeometryReader { geometry in
            ForEach(observations.indices, id: \.self) { index in
                let obs = observations[index]
                let rect = convert(obs.boundingBox, in: geometry.size)
                let text = obs.topCandidates(1).first?.string ?? ""

                ZStack(alignment: .topLeading) {
                    // Soft, readable highlight
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.yellow.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.yellow.opacity(0.85), lineWidth: 1.5)
                        )
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .transition(.opacity)

                    // Tiny label to aid debugging/QA
                    if !text.isEmpty {
                        Text(text)
                            .font(.system(size: 7, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.9))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .position(x: rect.minX + 6, y: rect.minY + 8)
                            .frame(maxWidth: rect.width - 8, alignment: .leading)
                            .transition(.opacity)
                    }
                }
            }
        }
    }

    private func convert(_ boundingBox: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: boundingBox.origin.x * size.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * size.height,
            width: boundingBox.width * size.width,
            height: boundingBox.height * size.height
        )
    }
}
