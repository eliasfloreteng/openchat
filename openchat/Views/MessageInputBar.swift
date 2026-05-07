import SwiftUI

struct MessageInputBar: View {
    @Binding var text: String
    let isSending: Bool
    let onSend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message", text: $text, axis: .vertical)
                .lineLimit(1...6)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Button {
                if isSending { onCancel() } else { onSend() }
            } label: {
                Image(systemName: isSending ? "stop.fill" : "arrow.up")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(canSend ? Color.accentColor : Color.secondary.opacity(0.4), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!isSending && !canSend)
            .accessibilityLabel(isSending ? "Stop" : "Send")
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
