import SwiftUI
import Vision

struct DocumentResultView: View {
    let image: CGImage

    @State private var isImageVisible: Bool = true
    @State private var keyValuePairs: [RecognizedKeyValue] = []
    @State private var detectedDocumentType: String = "Processing…"
    @Environment(\.dismiss) private var dismiss

    @State private var appear = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.l) {

                // Image preview with overlay boxes (toggleable)
                if isImageVisible {
                    ZStack {
                        GeometryReader { geo in
                            Image(decorative: image, scale: 1.0, orientation: .up)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width)
                                .clipped()
                                .overlay(
                                    TextOverlayBox(
                                        observations: keyValuePairs.compactMap { $0.keyTextObservation }
                                    )
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
                    .transition(.opacity.combined(with: .scale))
                }

                // Detected doc type card
                ResultCardView(
                    title: "Detected Document",
                    subtitle: detectedDocumentType,
                    icon: "doc.text.magnifyingglass"
                )

                // Extracted fields list
                if !keyValuePairs.isEmpty {
                    Text("Extracted Details").sectionHeader()

                    let displayPairs: [KeyValuePair] = keyValuePairs.map {
                        KeyValuePair(key: $0.key, value: $0.value ?? "")
                    }

                    KeyValueTableView(pairs: displayPairs) { pair in
                        // Row tap: you could present a detail editor if desired.
                        print("Tapped \(pair.key)")
                    }
                    .defaultAnimate(value: keyValuePairs.count)
                }

                // Actions row
                HStack(spacing: AppTheme.Spacing.m) {
                    Button {
                        saveToJSON()
                    } label: {
                        Label("Save", systemImage: "tray.and.arrow.down.fill")
                            .font(.headline)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .padding(.vertical, AppTheme.Spacing.s)
                            .background(AppTheme.primaryButtonColor)
                            .foregroundStyle(AppTheme.primaryButtonTextColor)
                            .clipShape(Capsule())
                            .shadow(color: AppTheme.primaryBlue.opacity(0.25), radius: 8, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)

                    ScanAgainButton(title: "Scan Another") {
                        dismiss()
                    }
                }
                .padding(.top, AppTheme.Spacing.s)

                // Show/Hide overlay toggle
                Button(isImageVisible ? "Hide Image" : "Show Image") {
                    withAnimation(.easeInOut(duration: 0.25)) { isImageVisible.toggle() }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.primaryBlue)
                .padding(.top, AppTheme.Spacing.xs)
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.top, AppTheme.Spacing.l)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.35)) { appear = true }
                runFullOCR(on: image)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Results")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif

    }

    private func saveToJSON() {
        var dict: [String: String] = [:]
        for pair in keyValuePairs {
            if let value = pair.value {
                dict[pair.key] = value
            }
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Saved ID JSON:\n\(jsonString)")
            }
        } catch {
            print("Error encoding to JSON: \(error)")
        }
    }

    private func runFullOCR(on cgImage: CGImage) {
        let rectangleRequest = VNDetectRectanglesRequest { request, _ in
            if let rect = request.results?.first as? VNRectangleObservation {
                self.runTextRecognition(cgImage: cgImage, regionOfInterest: rect.boundingBox)
            } else {
                self.runTextRecognition(cgImage: cgImage, regionOfInterest: nil)
            }
        }

        rectangleRequest.minimumConfidence = 0.8
        rectangleRequest.minimumAspectRatio = 0.5
        rectangleRequest.maximumAspectRatio = 1.0

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([rectangleRequest])
        }
    }

    private func runTextRecognition(cgImage: CGImage, regionOfInterest: CGRect?) {
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil, let results = request.results as? [VNRecognizedTextObservation] else { return }

            let recognizedWords = results.compactMap { obs in
                obs.topCandidates(1).first.map {
                    RecognizedWord(
                        text: $0.string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
                        boundingBox: obs.boundingBox
                    )
                }
            }

            var extractedPairs: [RecognizedKeyValue] = []
            var docType = "Unknown"

            if let parsedLines = MRZProcessor.detectAndPrintMRZ(from: recognizedWords),
               MRZProcessor.isLikelyMRZBlock(parsedLines),
               let parsed = PassportMRZParser.parse(lines: parsedLines.map { $0.text }) {
                docType = "Passport (MRZ)"
                extractedPairs = [
                    .init(key: "SURNAME", value: parsed.surname),
                    .init(key: "GIVEN NAMES", value: parsed.givenNames),
                    .init(key: "PASSPORT NO", value: parsed.passportNumber),
                    .init(key: "DATE OF BIRTH", value: parsed.dateOfBirth),
                    .init(key: "NATIONALITY", value: parsed.nationality),
                    .init(key: "SEX", value: parsed.sex),
                    .init(key: "DATE OF EXPIRY", value: parsed.expirationDate)
                ]
            } else {
                docType = "ID Card"
                let normalizedLines = IDCardLayoutHelper.normalizeObservations(results)
                extractedPairs = IDCardFieldExtractor.extractKeyValuePairs(from: normalizedLines)
            }

            DispatchQueue.main.async {
                withAnimation(.snappy(duration: 0.28)) {
                    self.keyValuePairs = extractedPairs
                    self.detectedDocumentType = docType
                }
            }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["cs_CZ", "en_GB"]
        request.regionOfInterest = regionOfInterest ?? CGRect(x: 0, y: 0, width: 1, height: 1)

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
