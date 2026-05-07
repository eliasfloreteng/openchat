import SwiftUI
import SwiftData

struct ConversationListView: View {
    let conversations: [Conversation]
    @Binding var selectedID: UUID?
    let onNewChat: () -> Void
    let onOpenSettings: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""

    private var filtered: [Conversation] {
        guard !searchText.isEmpty else { return conversations }
        return conversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(selection: $selectedID) {
            ForEach(filtered) { convo in
                NavigationLink(value: convo.id) {
                    ConversationRow(conversation: convo)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        delete(convo)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Chats")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .overlay {
            if conversations.isEmpty {
                ContentUnavailableView {
                    Label("No Chats Yet", systemImage: "bubble.left.and.bubble.right")
                } description: {
                    Text("Tap the compose button to start a conversation.")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onOpenSettings()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onNewChat) {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
            }
        }
    }

    private func delete(_ conversation: Conversation) {
        if selectedID == conversation.id { selectedID = nil }
        modelContext.delete(conversation)
        try? modelContext.save()
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(1)
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .imageScale(.small)
                Text(modelDisplay(conversation.modelId))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(conversation.updatedAt, format: .relative(presentation: .numeric))
                    .lineLimit(1)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func modelDisplay(_ id: String) -> String {
        id.split(separator: "/").last.map(String.init) ?? id
    }
}
