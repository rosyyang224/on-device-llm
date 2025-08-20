import SwiftUI
import PhotosUI
import ImageIO
import CoreGraphics

struct ImagePicker: View {
    @Binding var imageData: Data?

    @State private var selectedItem: PhotosPickerItem?
    @State private var showSourceChooser = false
    @State private var showCameraSheet = false
    @State private var showPhotosPicker = false
    @Namespace private var ns

    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            if let data = imageData, let cg = CGImageDecoder.cgImage(from: data) {
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
                        Text("Take a photo or choose from your library.")
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

            Button {
                showSourceChooser = true
            } label: {
                Label("Add Photo", systemImage: "plus")
                    .padding(.horizontal, AppTheme.Spacing.l)
                    .padding(.vertical, AppTheme.Spacing.s)
                    .background(AppTheme.primaryButtonColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Spacing.l)

        // Hidden PhotosPicker, toggled programmatically
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        imageData = data
                    }
                }
            }
        }

        // One dialog -> choose Camera (iOS) or Photos
        .confirmationDialog("Add Photo", isPresented: $showSourceChooser, titleVisibility: .visible) {
            #if os(iOS)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { showCameraSheet = true }
            }
            #endif
            Button("Choose from Photos") { showPhotosPicker = true }
            Button("Cancel", role: .cancel) {}
        }

        // Present system camera UI (iOS only)
        #if os(iOS)
        .sheet(isPresented: $showCameraSheet) {
            SystemCameraView { data in
                if let data {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        imageData = data
                    }
                }
                showCameraSheet = false
            }
            .ignoresSafeArea()
        }
        #endif
    }
}

// Minimal Data -> CGImage decoder (cross-platform)
enum CGImageDecoder {
    static func cgImage(from data: Data) -> CGImage? {
        let cfData = data as CFData
        guard let src = CGImageSourceCreateWithData(cfData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, [
            kCGImageSourceShouldCache: true as CFBoolean,
            kCGImageSourceShouldAllowFloat: true as CFBoolean
        ] as CFDictionary)
    }
}
