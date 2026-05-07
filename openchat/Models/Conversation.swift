import Foundation
import SwiftData

@Model
final class Conversation {
    @Attribute(.unique) var id: UUID
    var title: String
    var modelId: String
    var createdAt: Date
    var updatedAt: Date
    var parentConversationId: UUID?

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.conversation)
    var messages: [ChatMessage] = []

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        modelId: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        parentConversationId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.modelId = modelId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.parentConversationId = parentConversationId
    }

    var orderedMessages: [ChatMessage] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }
}
