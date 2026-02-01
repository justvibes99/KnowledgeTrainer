import Foundation
import SwiftData

@Model
final class WantToLearnItem {
    @Attribute(.unique) var id: UUID
    var topicName: String
    var sourceTopicID: UUID?
    var sourceSubtopic: String?
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        topicName: String,
        sourceTopicID: UUID? = nil,
        sourceSubtopic: String? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.topicName = topicName
        self.sourceTopicID = sourceTopicID
        self.sourceSubtopic = sourceSubtopic
        self.dateAdded = dateAdded
    }
}
