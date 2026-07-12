import SwiftUI
import Combine
import MarkdownUI

struct MessageBubbleView: View {
    let message: ChatMessage
    let onEdit: () -> Void

    @State private var showSelectText = false

    var body: some View {
        content
            .sheet(isPresented: $showSelectText) {
                SelectTextSheet(text: message.content)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 40)
                bubble
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundStyle(.white)
                    .contextMenu { menuItems }
            }
        case .assistant:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(.regularMaterial, in: Circle())
                markdownBubble
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundStyle(.primary)
                    .contextMenu { menuItems }
                Spacer(minLength: 40)
            }
        case .system:
            Text(message.content)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var menuItems: some View {
        if message.role == .user {
            Button {
                onEdit()
            } label: {
                Label("Edit & Fork", systemImage: "square.and.pencil")
            }
        }
        Button {
            UIPasteboard.general.string = message.content
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        Button {
            showSelectText = true
        } label: {
            Label("Select Text", systemImage: "character.cursor.ibeam")
        }
    }

    private var bubble: some View {
        Text(message.content)
            .font(.body)
            .textSelection(.enabled)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: 320, alignment: .leading)
    }

    private var markdownBubble: some View {
        Markdown(message.content)
            .markdownTextStyle(\.text) {
                FontFamilyVariant(.normal)
                FontSize(.em(1))
            }
            .textSelection(.enabled)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: 320, alignment: .leading)
    }
}

struct StreamingBubbleView: View {
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(.regularMaterial, in: Circle())
                .symbolEffect(.pulse, options: .repeating)
            Group {
                if content.isEmpty {
                    TypingIndicator()
                } else {
                    Markdown(content)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: 320, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer(minLength: 40)
        }
    }
}

private struct TypingIndicator: View {
    @State private var phase = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(phase == i ? 1.0 : 0.35)
            }
        }
        .frame(height: 18)
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}
