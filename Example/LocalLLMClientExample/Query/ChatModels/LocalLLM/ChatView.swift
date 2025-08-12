import SwiftUI
import LocalLLMClient
import LocalLLMClientMLX

struct ChatView: View {
    let ai: AI
    @State var viewModel: ChatViewModel
    @State private var position = ScrollPosition(idType: LLMInput.Message.ID.self)

    var body: some View {
        VStack {
            MessageList(messages: viewModel.messages)

            BottomBar(
                ai: ai,
                text: $viewModel.inputText,
                attachments: $viewModel.inputAttachments,
                isGenerating: viewModel.isGenerating
            ) { _ in
                viewModel.sendMessage()
            } onCancel: {
                viewModel.cancelGeneration()
            }
            .padding([.horizontal, .bottom])
        }
        .navigationTitle("Chat")
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("Clear Chat") {
                        ai.resetMessages()
                    }

                    Divider()

                    Button {
                        Task {
                            await ai.toggleTools()
                        }
                    } label: {
                        HStack {
                            Text("Tools calling")
                            if ai.areToolsEnabled {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .disabled(!ai.model.supportsTools)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onChange(of: ai.model) { _, _ in
            ai.resetMessages()
        }
    }
}
struct MessageList: View {
    let messages: [LLMInput.Message]

    @State private var position = ScrollPosition(idType: LLMInput.Message.ID.self)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(messages.filter { $0.role != .system }) { message in
                    ChatBubbleView(message: message)
                        .id(message.id)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal)
        }
        .scrollPosition($position)
        .onChange(of: messages) { _, _ in
            position.scrollTo(edge: .bottom)
        }
    }
}

struct ChatBubbleView: View {
    let message: LLMInput.Message

    var body: some View {
        let isUser = message.role == .user

        VStack(alignment: isUser ? .trailing : .leading) {
            LazyVGrid(columns: [.init(.adaptive(minimum: 100))], alignment: .leading) {
                ForEach(message.attachments) { attachment in
                    switch attachment.content {
                    case let .image(image):
                        Image(llm: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(16)
                    }
                }
                .scaleEffect(x: isUser ? -1 : 1)
            }
            .scaleEffect(x: isUser ? -1 : 1)

            MarkdownChatText(text: message.content)
                .padding(12)
                .background(isUser ? Color.accentColor : .gray.opacity(0.2))
                .foregroundColor(isUser ? .white : .primary)
                .cornerRadius(16)
        }
        .padding(isUser ? .leading : .trailing, 50)
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}
