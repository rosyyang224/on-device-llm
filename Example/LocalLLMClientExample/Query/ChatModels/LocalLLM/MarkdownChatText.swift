import SwiftUI

struct MarkdownChatText: View {
    let text: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.s) {
            ForEach(parseBlocks(from: text), id: \.id) { block in
                switch block.kind {
                case .heading(let level, let t):
                    Text(attributed(t))
                        .font(fontForHeading(level))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, level == 1 ? AppTheme.Spacing.s : 0)

                case .code(let code):
                    CodeBlockView(code: code)

                case .list(let items):
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(items, id: \.self) { item in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("•").bold()
                                Text(attributed(item))
                                    .font(AppTheme.TypeScale.body)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }

                case .numberedList(let items):
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(idx + 1).").bold()
                                Text(attributed(item))
                                    .font(AppTheme.TypeScale.body)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }

                case .paragraph(let p):
                    Text(attributed(p))
                        .font(AppTheme.TypeScale.body)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    // MARK: - Markdown helpers

    private func attributed(_ s: String) -> AttributedString {
        // Inline markdown (bold/italic/links/inline-code) parsed natively
        (try? AttributedString(
            markdown: s,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(s)
    }

    private func fontForHeading(_ level: Int) -> Font {
        switch level {
        case 1: return AppTheme.TypeScale.title       // larger than title2
        case 2: return AppTheme.TypeScale.title2
        case 3: return .system(size: 16, weight: .semibold, design: .rounded)
        default: return .system(size: 15, weight: .semibold, design: .rounded)
        }
    }

    private func headingLevel(_ trimmed: String) -> Int? {
        // Matches "# Title", "## Title", ... up to "###### Title"
        guard trimmed.first == "#" else { return nil }
        let count = trimmed.prefix { $0 == "#" }.count
        guard (1...6).contains(count) else { return nil }
        // Require a space after the hashes (CommonMark-ish)
        guard trimmed.dropFirst(count).first == " " else { return nil }
        return count
    }

    private func parseBlocks(from input: String) -> [Block] {
        // Split code fences first, detect headings, then split paragraphs into lists/paragraphs
        var blocks: [Block] = []
        var inCode = false
        var codeBuffer: [String] = []
        var paragraphBuffer = ""

        let normalized = input.replacingOccurrences(of: "\r\n", with: "\n")
                              .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.components(separatedBy: "\n")

        func flushParagraph() {
            let trimmed = paragraphBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { paragraphBuffer = ""; return }
            blocks.append(contentsOf: splitParagraphIntoBlocks(trimmed))
            paragraphBuffer = ""
        }

        for raw in lines {
            let line = raw
            let t = line.trimmingCharacters(in: .whitespaces)

            // toggle code fence ``` (any language tag ignored for now)
            if t.hasPrefix("```") {
                if inCode {
                    // close fence
                    blocks.append(.init(kind: .code(codeBuffer.joined(separator: "\n"))))
                    codeBuffer.removeAll()
                } else {
                    // open fence; flush any pending paragraph
                    flushParagraph()
                }
                inCode.toggle()
                continue
            }

            if inCode {
                codeBuffer.append(line)
                continue
            }

            // Headings (H1–H6) — treat as their own blocks
            if let level = headingLevel(t) {
                flushParagraph()
                let text = String(t.drop { $0 == "#" || $0 == " " })
                blocks.append(.init(kind: .heading(level: level, text: text)))
                continue
            }

            // Blank line ends paragraph
            if t.isEmpty {
                flushParagraph()
            } else {
                paragraphBuffer.append(line + "\n")
            }
        }

        // leftovers
        if inCode {
            blocks.append(.init(kind: .code(codeBuffer.joined(separator: "\n"))))
        } else {
            flushParagraph()
        }

        return blocks
    }

    private func splitParagraphIntoBlocks(_ paragraph: String) -> [Block] {
        // Detect simple bullets (- / *) or 1. 2. numbering across lines
        let lines = paragraph.components(separatedBy: .newlines).filter { !$0.isEmpty }

        let isBulletList = lines.allSatisfy {
            let t = $0.trimmingCharacters(in: .whitespaces)
            return t.hasPrefix("- ") || t.hasPrefix("* ")
        }

        if isBulletList {
            let items = lines.map {
                let t = $0.trimmingCharacters(in: .whitespaces)
                return String(t.dropFirst(2))
            }
            return [.init(kind: .list(items))]
        }

        let isNumberedList = lines.allSatisfy {
            // match "N. " prefix
            let t = $0.trimmingCharacters(in: .whitespaces)
            guard let dot = t.firstIndex(of: ".") else { return false }
            let before = t[..<dot]
            let afterDotIndex = t.index(after: dot)
            let hasSpace = afterDotIndex < t.endIndex ? t[afterDotIndex] == " " : false
            return before.allSatisfy(\.isNumber) && hasSpace
        }

        if isNumberedList {
            let items = lines.map {
                var t = $0.trimmingCharacters(in: .whitespaces)
                if let dot = t.firstIndex(of: ".") {
                    t.removeSubrange(t.startIndex...dot)
                    if t.first == " " { t.removeFirst() }
                }
                return t
            }
            return [.init(kind: .numberedList(items))]
        }

        return [.init(kind: .paragraph(lines.joined(separator: "\n")))]
    }

    // MARK: - Model

    struct Block: Identifiable {
        let id = UUID()
        enum Kind {
            case heading(level: Int, text: String)
            case paragraph(String), list([String]), numberedList([String]), code(String)
        }
        let kind: Kind
    }
}

// MARK: - Code block appearance (uses AppTheme, no forced side alignment)
private struct CodeBlockView: View {
    let code: String
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .padding(AppTheme.Spacing.m)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                        .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                )
        }
    }
}
