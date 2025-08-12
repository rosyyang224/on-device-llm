import SwiftUI

struct MarkdownChatText: View {
    let text: String

    var body: some View {
        // No hardcoded horizontal alignment here.
        // Your ChatBubbleView controls left/right placement.
        VStack(spacing: AppTheme.Spacing.s) {
            ForEach(parseBlocks(from: text), id: \.id) { block in
                switch block.kind {
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
        // Inline markdown (bold/italic/links/headings inline) parsed natively
        (try? AttributedString(
            markdown: s,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(s)
    }

    private func parseBlocks(from input: String) -> [Block] {
        // Split code fences first, then split paragraphs into lists/paragraphs
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
            } else {
                if t.isEmpty {
                    flushParagraph()
                } else {
                    paragraphBuffer.append(line + "\n")
                }
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
            // ensure everything before '.' is digits and next char is space
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
        enum Kind { case paragraph(String), list([String]), numberedList([String]), code(String) }
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
