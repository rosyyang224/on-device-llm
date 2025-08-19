import SwiftUI
import PhotosUI
import LocalLLMClient

struct BottomBar: View {
    let ai: AI

    @Binding var text: String
    @Binding var attachments: [LLMAttachment]   // kept for API compatibility; not shown
    let isGenerating: Bool
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            modelMenu
                .buttonStyle(.plain)

            Button {
                Task { await ai.toggleTools() }
            } label: {
                Image(systemName: ai.areToolsEnabled ? "wand.and.stars.inverse" : "wand.and.stars")
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(!ai.model.supportsTools)
            .foregroundStyle(ai.model.supportsTools ? AppTheme.onSurface : .secondary)

            TextField("Message", text: $text)
                .textFieldStyle(.plain)
                .padding(.vertical, AppTheme.Spacing.xs)
                .padding(.horizontal, AppTheme.Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                        .fill(.thinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 0.5)
                )
                .submitLabel(.send)
                .onSubmit { onSubmit(text) }
                .disabled(isGenerating)

            Group {
                if isGenerating {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.red))
                            .shadow(color: Color.red.opacity(0.22), radius: 8, x: 0, y: 4)
                            .accessibilityLabel("Cancel")
                    }
                } else {
                    Button {
                        onSubmit(text)
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppTheme.primaryBlue))
                            .shadow(color: AppTheme.primaryBlue.opacity(0.24), radius: 10, x: 0, y: 5)
                            .accessibilityLabel("Send")
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.s)
        .padding(.vertical, AppTheme.Spacing.xs)
        .glassCard()
        .padding(.horizontal)
    }

    // MARK: - Model menu (logic unchanged)
    @ViewBuilder
    private var modelMenu: some View {
    #if os(macOS)
        @Bindable var ai = ai
        Picker(selection: $ai.model) {
            ForEach(LLMModel.allCases) { model in
                Text(model.supportsVision ? "\(model.name) [VLM]" : model.name)
                    .tag(model)
            }
        } label: {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 16, weight: .semibold))
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .fixedSize()
    #elseif os(iOS)
        Menu {
            ForEach(LLMModel.allCases) { model in
                Button {
                    ai.model = model
                } label: {
                    Text(model.supportsVision ? "\(model.name) [VLM]" : model.name)
                    if ai.model == model { Image(systemName: "checkmark") }
                }
            }
        } label: {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 16, weight: .semibold))
        }
        .menuStyle(.button)
    #endif
    }
}
