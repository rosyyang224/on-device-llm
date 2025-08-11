import SwiftUI
import PhotosUI
import Vision
import CoreGraphics
import ImageIO

struct OCRView: View {
    // Image as raw bytes (no UIKit / NSImage)
    @State private var imageData: Data? = nil
    @State private var selectedItem: PhotosPickerItem? = nil

    @State private var selectedCGImage: CGImage? = nil
    @State private var navigateToResult = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    HomeHeaderView(
                        title: "Passport OCR",
                        subtitle: "Scan a photo and extract key fields instantly.",
                        image: nil
                    )

                    PassportIllustration()

                    ImagePicker(imageData: $imageData)
                        .onChange(of: imageData) { oldValue, newValue in
                            // Convert to CGImage when imageData arrives
                            if let data = newValue, let cg = CGImageDecoder.cgImage(from: data) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    selectedCGImage = cg
                                    navigateToResult = true
                                }
                            } else if newValue != nil {
                                errorMessage = "Unable to decode the selected image."
                            }
                        }

                    if let errorMessage {
                        ResultCardView(
                            title: "Image Error",
                            subtitle: errorMessage,
                            icon: "exclamationmark.triangle.fill"
                        )
                        .transition(.opacity)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationDestination(isPresented: $navigateToResult) {
                if let image = selectedCGImage {
                    DocumentResultView(image: image)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
        }
    }
}
