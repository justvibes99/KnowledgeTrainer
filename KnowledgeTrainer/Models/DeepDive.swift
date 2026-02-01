import Foundation
import SwiftData

@Model
final class DeepDive {
    @Attribute(.unique) var id: UUID
    var topic: String
    var content: String
    var connectedTopics: [String]
    var dateCreated: Date

    init(id: UUID = UUID(), topic: String, content: String, connectedTopics: [String] = [], dateCreated: Date = Date()) {
        self.id = id
        self.topic = topic
        self.content = content
        self.connectedTopics = connectedTopics
        self.dateCreated = dateCreated
    }
}
