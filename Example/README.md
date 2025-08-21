## Requirements

- iOS 26.0+ / macOS 26.0+
- Xcode 16 beta 4

## Usage

To run the example app:

1. Clone the repository:
  ```bash
  git clone --recursive HTTPS_URL
  ```
  If you already cloned the repository without `--recursive`, run:
  ```bash
  git submodule update --init --recursive
  ```
2. Open `LocalLLMClientExample.xcodeproj` in Xcode
3. Build and run the app on your device, not a simulator

*Note: The app requires a physical device*

# Use Case 1: Passport & ID OCR Pipeline – iOS (Swift + VisionKit)

This project implements an on-device OCR pipeline for parsing passports and national ID cards. It uses Apple's Vision framework for OCR, with custom logic for extracting and parsing structured fields from scanned documents.

It was adapted from [`passport-ocr`](https://github.com/namnp1998/passport-ocr), but rewritten entirely in Swift for native iOS use.

## Code Structure

The code is modularized under the `OCR/` directory. It's split into two main layers: **Processing** and **UI**.

### `OCR/Processing/` – Core Logic

Handles all non-UI processing for document analysis and text extraction.

| File                          | Purpose                                                                 |
|-------------------------------|-------------------------------------------------------------------------|
| `PassportMRZParser.swift`     | Parses raw MRZ strings into structured fields (name, DOB, expiration). |
| `MRZProcessor.swift`          | Entry point for MRZ detection and cleanup.                             |
| `MRZHeuristics.swift`         | Rules for scoring and filtering candidate MRZ blocks.                  |
| `IDCardFieldExtractor.swift`  | Attempts to pair key-value text fields on scanned IDs.                 |
| `IDCardLayoutHelper.swift`    | Layout-aware heuristics (spatial clustering, alignment).               |
| `RecognizedKeyValue.swift`    | Data model for extracted fields.                                       |
| `SystemCameraView.swift`      | UIKit camera picker wrapper for use in SwiftUI.                        |

### `OCR/UI/` – SwiftUI Views

All UI components are split by feature:

- `Components/`
  - `Home/` – Image selection interface
  - `Results/` – Structured OCR output with overlays
  - `Shared/` – Generic views (field tables, overlay boxes, etc.)
- `Screens/`
  - `OCRView.swift` – Main entry screen for scanning
  - `DocumentResultView.swift` – Final structured result display
 
## How It Works

### Image Selection

The user selects an image of a passport or ID card from their photo library or camera.

### OCR via VisionKit

Apple Vision processes the image using `VNRecognizedTextObservation`, returning text blocks with bounding boxes.

### Document Type Detection

A simple heuristic determines whether the input is a passport (based on MRZ format) or a national ID (based on layout).

### Parsing

- **Passport**: `PassportMRZParser` decodes the MRZ region into structured fields.
- **ID**: `IDCardFieldExtractor` applies layout heuristics to match field labels and values.

### Rendering

Results are passed to `DocumentResultView` and displayed as key-value fields, with an optional overlay of bounding boxes.

## Development Notes

- All OCR is performed on-device using Apple Vision APIs; no network calls.
- `IDCardFieldExtractor` uses heuristic-based logic that may break with uncommon ID layouts.
- The system is optimized for U.S. passports; U.S. state ID (from Maryland) is alright.
- Not good at parsing documents in languages other than English.

## Known Issues

- Bounding boxes can be misaligned, especially on multi-line fields or tightly packed IDs.
- Field label detection is sensitive to layout and may fail when labels are missing or misaligned.
- Not good at recognizing non-English text and labels.
- MRZ parser assumes ICAO-compliant formatting and will fail on non-standard passports.

# Use Case 2: PDF Pipeline

This project does **not currently include** the PDF processing pipeline — but the work and exploration have been scoped for future integration.

## Status

- The pipeline is **not included in this repo**
- Main blocker: extracting structured data (especially **tables**) from PDF reports
- Two useful libraries were found — [`PyPDF`](https://pypi.org/project/pypdf/) and [`Docling`](https://github.com/docling-project/docling) — but both are Python-based
- No viable Swift-native alternative found:
  - Apple VisionKit is effective for text extraction
  - However, it does not handle tabular data well
  - Apple’s newer table recognition APIs assume rigid rows and columns, which our PDFs don’t follow, but maybe there's a way to manipulate it (add rows and columns to the page before running it thru visionkit) 

## Challenges

- Table extraction fails when:
  - Column/row layouts are inconsistent or irregular
  - Data is embedded inside visual artifacts or split across lines
- Apple Vision’s table recognition is not yet suited for free-form financial documents

## Going Forward

- Explore fine-tuning custom models for structured table recognition
- Try manipulating the image to add rows and col lines before running it through OCR / Apple's [table extraction api](https://developer.apple.com/documentation/Vision/recognize-tables-within-a-document)
- Consider using Foundation Model adapters to train to extract tabular content
- Try VLMs (Vision Language Models) in the `QueryView` pipeline:
  - May still run into context size limits
  - `Qwen1.7B` may be suitable; test against various table-heavy documents
- Use LM Studio to test multiple on-device LLMs for:
  - Table understanding
  - Key-value pairing
  - Instruction-following performance


