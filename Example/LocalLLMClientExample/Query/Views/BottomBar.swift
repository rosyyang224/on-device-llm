import SwiftUI
import PhotosUI
import LocalLLMClient

struct BottomBar: View {
    @EnvironmentObject var ai: AI

    @Binding var text: String
    @Binding var attachments: [LLMAttachment]
    let isGenerating: Bool
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var pickedItem: PhotosPickerItem?

    var body: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            // Model switcher
            modelMenu
                .buttonStyle(.plain)

            // Vision image picker (disabled if model isn’t VLM)
            PhotosPicker(
                selection: $pickedItem,
                matching: .images,
                preferredItemEncoding: .compatible
            ) {
                Image(systemName: "photo")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ai.model.supportsVision ? AppTheme.primaryBlue : .gray)
            }
            .disabled(!ai.model.supportsVision)
            .onChange(of: pickedItem) { _, item in
                guard let item else { return }
                pickedItem = nil
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = LLMInputImage(data: data) {
                        attachments.append(.image(image))
                    }
                }
            }

            // Tool icon (visual only)
            Image(systemName: "wand.and.stars.inverse")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.primaryBlue)

            // Input
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

            // Send / Cancel
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
        .safeAreaInset(edge: .top) {
            if !attachments.isEmpty {
                attachmentList
            }
        }
        .padding(.horizontal, AppTheme.Spacing.s)
        .padding(.vertical, AppTheme.Spacing.xs)
        .glassCard()
        .padding(.horizontal)
        .animation(.default, value: text.isEmpty)
        .animation(.default, value: attachments.count)
    }

    // MARK: - Attachment strip (matches first version)
    @ViewBuilder
    private var attachmentList: some View {
        ScrollView(.horizontal) {
            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(attachments) { attachment in
                    switch attachment.content {
                    case let .image(image):
                        Image(llm: image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(8)
                            .contextMenu {
                                Button("Remove") {
                                    attachments.removeAll { $0.id == attachment.id }
                                }
                            }
                    }
                }
            }
            .frame(height: 60)
            .padding(.horizontal, AppTheme.Spacing.s)
            .padding(.vertical, AppTheme.Spacing.xs)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Model menu (same switching semantics)
    @ViewBuilder
        private var modelMenu: some View {
        #if os(macOS)
            Picker(
                selection: Binding(
                    get: { ai.model },
                    set: { ai.model = $0 }
                )
            ) {
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
                    Button { ai.model = model } label: {
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
