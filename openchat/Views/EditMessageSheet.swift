import SwiftUI

struct EditMessageSheet: View {
    let message: ChatMessage
    let onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: String
    @FocusState private var focused: Bool

    init(message: ChatMessage, onSubmit: @escaping (String) -> Void) {
        self.message = message
        self.onSubmit = onSubmit
        _draft = State(initialValue: message.content)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Submitting will create a new chat branched from this point.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                TextEditor(text: $draft)
                    .focused($focused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
                    .background(Color(.secondarySystemBackground))
            }
            .navigationTitle("Edit Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fork") {
                        onSubmit(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                focused = true
            }
        }
    }
}
