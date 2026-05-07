import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]

    @State private var selectedConversationID: UUID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var showSettings = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ConversationListView(
                conversations: conversations,
                selectedID: $selectedConversationID,
                onNewChat: newConversation,
                onOpenSettings: { showSettings = true }
            )
        } detail: {
            if let id = selectedConversationID,
               let conversation = conversations.first(where: { $0.id == id }) {
                ChatView(conversation: conversation, onFork: openForked)
                    .id(conversation.id)
            } else {
                EmptyChatPlaceholder(onNewChat: newConversation)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            if selectedConversationID == nil {
                selectedConversationID = conversations.first?.id
            }
        }
    }

    private func newConversation() {
        let convo = Conversation(modelId: AppSettings.shared.lastSelectedModel)
        modelContext.insert(convo)
        try? modelContext.save()
        selectedConversationID = convo.id
    }

    private func openForked(_ id: UUID) {
        selectedConversationID = id
    }
}

private struct EmptyChatPlaceholder: View {
    let onNewChat: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Chat Selected", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Start a new conversation to chat with a model.")
        } actions: {
            Button(action: onNewChat) {
                Label("New Chat", systemImage: "square.and.pencil")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
