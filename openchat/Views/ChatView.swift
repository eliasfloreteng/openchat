import SwiftUI
import SwiftData

struct ChatView: View {
    @Bindable var conversation: Conversation
    let onFork: (UUID) -> Void
    let onNewChat: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var draft: String = ""
    @State private var streamingTask: Task<Void, Never>?
    @State private var streamingContent: String = ""
    @State private var isStreaming = false
    @State private var errorMessage: String?
    @State private var showModelPicker = false
    @State private var editingMessage: ChatMessage?
    @FocusState private var inputFocused: Bool

    private let settings = AppSettings.shared

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(conversation.orderedMessages) { message in
                        MessageBubbleView(
                            message: message,
                            onEdit: { editingMessage = message }
                        )
                        .id(message.id)
                    }
                    if isStreaming {
                        StreamingBubbleView(content: streamingContent)
                            .id("streaming")
                    }
                    if let errorMessage {
                        ErrorBanner(text: errorMessage) {
                            self.errorMessage = nil
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: conversation.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: streamingContent) { _, _ in
                scrollToBottom(proxy)
            }
        }
        .safeAreaInset(edge: .bottom) {
            MessageInputBar(
                text: $draft,
                isSending: isStreaming,
                onSend: send,
                onCancel: cancelStreaming
            )
            .focused($inputFocused)
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    showModelPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                        Text(modelShortName(conversation.modelId))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onNewChat) {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showModelPicker) {
            ModelPickerView(selectedModelId: $conversation.modelId)
        }
        .sheet(item: $editingMessage) { message in
            EditMessageSheet(message: message) { newContent in
                fork(from: message, withNewContent: newContent)
            }
        }
        .onDisappear {
            cancelStreaming()
        }
        .task(id: conversation.id) {
            if !isStreaming, conversation.orderedMessages.last?.role == .user {
                startStreaming()
            }
        }
        .task(id: conversation.id) {
            try? await Task.sleep(for: .milliseconds(50))
            inputFocused = true
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if isStreaming {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let last = conversation.orderedMessages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private func modelShortName(_ id: String) -> String {
        id.split(separator: "/").last.map(String.init) ?? id
    }

    // MARK: - Sending

    private func send() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed, conversation: conversation)
        modelContext.insert(userMessage)
        conversation.updatedAt = .now
        if conversation.title == "New Chat" {
            conversation.title = String(trimmed.prefix(40))
        }
        try? modelContext.save()
        draft = ""
        inputFocused = false
        startStreaming()
    }

    private func startStreaming() {
        errorMessage = nil
        streamingContent = ""
        isStreaming = true
        AppSettings.shared.lastSelectedModel = conversation.modelId

        let history = conversation.orderedMessages.map {
            ChatRequestMessage(role: $0.role.rawValue, content: $0.content)
        }
        let model = conversation.modelId
        let webSearch = settings.webSearchEnabled
        let webFetch = settings.webFetchEnabled

        streamingTask = Task { @MainActor in
            do {
                let stream = OpenRouterService.shared.streamChat(
                    model: model,
                    messages: history,
                    webSearch: webSearch,
                    webFetch: webFetch
                )
                for try await delta in stream {
                    streamingContent += delta
                }
                if !streamingContent.isEmpty {
                    let assistant = ChatMessage(role: .assistant, content: streamingContent, conversation: conversation)
                    modelContext.insert(assistant)
                    conversation.updatedAt = .now
                    try? modelContext.save()
                }
            } catch is CancellationError {
                // ignore
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            streamingContent = ""
            isStreaming = false
            streamingTask = nil
        }
    }

    private func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
        streamingContent = ""
    }

    // MARK: - Forking

    private func fork(from message: ChatMessage, withNewContent newContent: String) {
        let trimmed = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let ordered = conversation.orderedMessages
        guard let cutIndex = ordered.firstIndex(where: { $0.id == message.id }) else { return }

        let new = Conversation(
            title: String(trimmed.prefix(40)),
            modelId: conversation.modelId,
            parentConversationId: conversation.id
        )
        modelContext.insert(new)

        for (i, m) in ordered.enumerated() {
            if i < cutIndex {
                let copy = ChatMessage(role: m.role, content: m.content, createdAt: m.createdAt, conversation: new)
                modelContext.insert(copy)
            } else if i == cutIndex {
                let edited = ChatMessage(role: m.role, content: trimmed, createdAt: .now, conversation: new)
                modelContext.insert(edited)
                break
            }
        }
        new.updatedAt = .now
        try? modelContext.save()
        onFork(new.id)
    }
}

private struct ErrorBanner: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
