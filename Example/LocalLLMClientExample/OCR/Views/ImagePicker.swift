import SwiftUI
import PhotosUI
import CoreGraphics
import ImageIO

struct ImagePicker: View {
    /// Raw image bytes so we avoid UIImage/NSImage and work on iOS + macOS.
    @Binding var imageData: Data?

    @State private var selectedItem: PhotosPickerItem?
    @Namespace private var ns

    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            if let imageData, let cg = CGImageDecoder.cgImage(from: imageData) {
                Image(decorative: cg, scale: 1, orientation: .up)
                    .resizable()
                    .scaledToFit()
                    .matchedGeometryEffect(id: "pickedImage", in: ns)
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                            .strokeBorder(.white.opacity(0.6), lineWidth: 0.5)
                    )
                    .card()
                    .transition(.opacity.combined(with: .scale))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                        .fill(AppTheme.lightGray)
                    VStack(spacing: 10) {
                        Image(systemName: "doc.viewfinder")
                            .pillIcon(color: AppTheme.primaryBlue)
                        Text("Add a passport photo")
                            .font(AppTheme.TypeScale.title2)
                        Text("Import from Photos or take a new picture.")
                            .font(AppTheme.TypeScale.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, AppTheme.Spacing.l)
                }
                .frame(height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6,6]))
                        .foregroundStyle(AppTheme.mediumGray.opacity(0.8))
                )
                .transition(.opacity)
            }

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label(imageData == nil ? "Choose Photo" : "Replace Photo",
                      systemImage: "photo.on.rectangle")
                    .padding(.horizontal, AppTheme.Spacing.l)
                    .padding(.vertical, AppTheme.Spacing.s)
                    .background(AppTheme.primaryButtonColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .onChange(of: selectedItem) { _ in
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            imageData = data
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.l)
    }
}

/// Minimal Data -> CGImage decoder using ImageIO (cross-platform).
enum CGImageDecoder {
    static func cgImage(from data: Data) -> CGImage? {
        let cfData = data as CFData
        guard let source = CGImageSourceCreateWithData(cfData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, [
            kCGImageSourceShouldCache: true as CFBoolean,
            kCGImageSourceShouldAllowFloat: true as CFBoolean
        ] as CFDictionary)
    }
}
