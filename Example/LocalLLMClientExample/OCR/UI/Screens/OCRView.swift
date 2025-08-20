import SwiftUI
import PhotosUI
import Vision
import CoreGraphics
import ImageIO

struct OCRView: View {
    @State private var imageData: Data? = nil
    @State private var selectedItem: PhotosPickerItem? = nil

    @State private var selectedCGImage: CGImage? = nil
    @State private var navigateToResult = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {

                    // Hero Illustration
                    PassportHero()
                        .padding(.top, AppTheme.Spacing.m)

                    // Context text
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        Text("Upload an ID")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)

                        Text("Add a clear photo of your passport, national ID, or driver’s license to automatically extract and fill in form fields.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, AppTheme.Spacing.l)

                    // Upload Card
                    ImagePicker(imageData: $imageData)
                        .onChange(of: imageData) { _, newValue in
                            if let data = newValue, let cg = CGImageDecoder.cgImage(from: data) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    selectedCGImage = cg
                                    navigateToResult = true
                                }
                            } else if newValue != nil {
                                errorMessage = "Unable to decode the selected image."
                            }
                        }

                    // Error State
                    if let errorMessage {
                        ResultCardView(
                            title: "Image Error",
                            subtitle: errorMessage,
                            icon: "exclamationmark.triangle.fill"
                        )
                        .padding(.horizontal, AppTheme.Spacing.l)
                        .transition(.opacity)
                    }

                    Spacer(minLength: AppTheme.Spacing.xxl)
                }
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Easy Form")
            .navigationDestination(isPresented: $navigateToResult) {
                if let image = selectedCGImage {
                    DocumentResultView(image: image)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
        }
    }
}
