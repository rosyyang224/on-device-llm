import SwiftUI
import Vision

struct DocumentResultView: View {
    let image: CGImage

    @State private var isImageVisible: Bool = true
    @State private var keyValuePairs: [RecognizedKeyValue] = []
    @State private var detectedDocumentType: String = "Processing…"
    @Environment(\.dismiss) private var dismiss

    @State private var appear = false
    @State private var didRunOCR = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.l) {
                if isImageVisible {
                    ImagePreviewWithOverlay(image: image, keyValuePairs: keyValuePairs)
                        .transition(.opacity.combined(with: .scale))
                }

                DetectedDocTypeCard(text: detectedDocumentType)

                if !keyValuePairs.isEmpty {
                    ExtractedDetailsSection(pairs: keyValuePairs)
                }

                ActionsRow(onSave: { saveToJSON() }, onScanAgain: { dismiss() })
                    .padding(.top, AppTheme.Spacing.s)

                OverlayToggle(isOn: $isImageVisible) {
                    withAnimation(.easeInOut(duration: 0.25)) { isImageVisible.toggle() }
                }
                .padding(.top, AppTheme.Spacing.xs)
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.top, AppTheme.Spacing.l)
            .onAppear {
                guard !didRunOCR else { return }
                didRunOCR = true
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
        request.recognitionLanguages = ["cs-CZ", "en-GB"]
        request.regionOfInterest = regionOfInterest ?? CGRect(x: 0, y: 0, width: 1, height: 1)

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
