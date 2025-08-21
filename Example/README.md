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

It was adapted from [`vision-ocr-demo`](https://github.com/marekpridal/Vision-OCR-Demo), but rewritten to merge in passport in addition to vision boxes.

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

# Use Case 3 + 4: Summarization + Query Pipeline – On-Device LLMs (Swift)

This pipeline enables both natural language **summarization** and **querying** of structured data such as holdings, transactions, and user activity logs. It supports multiple LLM backends and includes infrastructure for tool-based data retrieval and memory continuity.

It is based on [`LocalLLMClient`](https://github.com/marella/LocalLLMClient) and integrates both Apple FoundationModels and locally hosted LLMs via MLX and llama.cpp.

---

## Code Structure

This system is split between **FoundationModels** and **non-Foundation pipelines**. Both use the same frontend but differ in architecture, session management, and tooling logic.

| Subfolder / File                    | Purpose                                                                 |
|-------------------------------------|-------------------------------------------------------------------------|
| `ChatModels/`                       | Core model logic and session control for both FM and non-FM pipelines   |
| ├─ `Foundation/`                    | Handles FoundationChatSession and adapter-based tool calls              |
| └─ `LocalLLM/`                      | Handles AI.swift and session state for Qwen, Gemma, etc.                |
| `Functionality/`                    | Manages memory, compression, caching, and session continuity            |
| ├─ `Compression/`                   | Formats and compresses structured data for model injection              |
| ├─ `ConversationContinuity.swift`   | Injects past queries + answers to maintain session context              |
| └─ `Cache.swift`                    | Caches tool results and LLM responses for reuse                         |
| `Data/`                             | Contains mock data and system prompt definitions                        |
| ├─ `mockData.swift`                 | Includes holdings, transactions, portfolio, and user preferences        |
| └─ `sysPrompt.swift`                | Shared grounding prompt for all pipelines                               |
| `Tools/`                            | Tool schemas + implementations, split by backend                        |
| ├─ `FoundationModels/`              | Tools for FM runtime (getHoldings, getTransactions, etc.)              |
| └─ `LLMClient/`                     | Tools for local LLM runtime with same schema                           |
| `Views/`                            | SwiftUI UI for query + chat interface                                   |
| └─ `QueryView.swift`                | Unified frontend for all LLM pipelines                                 |
| `HomepageSummary/`                 | Full-screen summary rendering using shared backend                      |
| ├─ `Classic/`                       | Renders single-user summary                                            |
| ├─ `Comparison/`                    | Renders two-user side-by-side summary comparison                        |
| ├─ `Shared/`                        | UI components: buttons, cards, loading overlays                         |
| └─ `HomepageSummaryViewModel.swift`| Controls summary generation and pipeline toggling                       |


---

## How It Works

### 1. Data Prep

- Mock data lives in `Data/` and includes separate files for holdings, transactions, and user preferences.
- The system prompt is defined in `sysPrompt.swift`. I currently switch out sysPrompt and summarySysPrompt due to context limit errors (too long if I include both) 

### 2. Tooling & Data Access

- The user sends a natural language query.
- Tooling retrieves structured data (e.g. holdings, transactions) and returns processed data.  
  For example: `getHoldings` takes input from `mockData.swift` and outputs a filtered list of holdings based on query parameters (e.g. symbol, market value range).
- Tooling is split by backend:
  - `FoundationModels` tools use Apple’s tool-calling APIs
  - `LLMClient` tools use local logic and in-memory caching

### 3. Compression & Injection

- Retrieved data is compressed and formatted in `Compressor.swift`
- History is truncated or compressed before being injected into the LLM

### 4. LLM Pipeline Execution

- The `AI.swift` interface in `ChatModels/` runs the actual model
- Two pathways:
  - `FoundationChatSession` for Apple models
  - `ChatViewModel` for MLX/Gemma/Qwen via LocalLLMClient
- The same UI (QueryView) is used regardless of pipeline

### 5. Memory & Continuity

- One `AI` instance is shared across all views
- This can lead to **context bleeding** if summarization and query happen in the same session
- Conversation history is compressed and reinjected with `ConversationContinuity.swift`

---

## Development Notes

- Switching pipelines in the backend works, but the UI toggle button does not update correctly
- All views share a single `AI` instance; if you run summarization and switch to query, it may reuse that session
- Summary comparison runs two users in the same instance — the second run overwrites the first unless cached
- MarkDown rendering in `MarkdownChatText.swift` sometimes misformats output
- Keyboard takes time to load when first entering the query page (performance quirk)

---

## Known Issues

- MLX runs extremely slowly for unknown reasons — may be a backend or model I/O issue
- Some queries exceed context limits, especially after summarization history gets long
- In the summary comparison view, both users return the same output if run back-to-back
  - This happens because both are using the same `AI` instance — need to cache or isolate runs
- Clicking the pipeline toggle button in the UI (e.g., in Classic Summary) does switch the backend, but the button itself doesn’t update visually
- If you run the Classic summary and then switch to Query view, the AI instance isn’t properly refreshed — the session bleeds over
- Markdown rendering (via `MarkdownChatText.swift`) occasionally misformats output
- When entering the Query page for the first time, tapping the bottom bar to open the keyboard has a noticeable delay

---

## Going Forward

- Test the pipeline on beta 5 and upcoming versions to evaluate any system-level performance improvements
- Refactor tooling to be more dynamic (reduce redundancy between FM and local implementations)
- sysPrompt for summary sometimes returns different things for the same prompt
- Make a dynamic switching systemPrompt that injects the correct sysPrompt vs. summarySysPrompt based on what the user asks
   - Or have it inject the correct examples into the system prompt based on user query type
   - More better cross-dataset queries (eg. ones that combine holdings data and transactions data)
- Integrate a fine-tuned retrieval layer and test with a real dataset
  - Target: 10,000+ data points for training
  - Train for more epochs and test longer sequences
  - Try larger models (e.g. DeepSeek, Starcoder) and quantize for on-device use
- Finish setting up a proper test pipeline (currently scaffolded in the `Tests/` folder)
- Expand query coverage — test a wider variety of user queries and edge cases
- Refactor tool return arguments to include richer, more complete datasets
- Expand and normalize the mock data to reflect full schemas
  - Update both the mock sources and corresponding tool + compressor logic
- Replace the crude token estimate (`/ 4`) with a more accurate token counting method
- I think in the future we can consider implementing a **layered answering model**:

  - For each query, dynamically select one or more of:
    - **Direct queries**: Fuzzy match + return structured data via tooling
      - e.g., "What are my Apple holdings?" or "What was my performance last August?"
    - **Calculations**: Run algorithmic logic (e.g., XGBoost or custom rules)
      - e.g., "Calculate my estimated tax from holdings" or "Find most volatile 10-month period"
    - **Complex reasoning**: Use LLMs for summarization, explanation, or pattern analysis
      - e.g., "Summarize my user activity" or "Analyze changes in portfolio trends"

  - These could be combined depending on the query (e.g., direct + calc, or all three)

- Experiment with fine-tuning Qwen and quantizing it specifically for this use case
