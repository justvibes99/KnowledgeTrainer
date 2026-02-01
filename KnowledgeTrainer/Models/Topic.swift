import Foundation
import SwiftData

@Model
final class Topic {
    @Attribute(.unique) var id: UUID
    var name: String
    var subtopics: [String]
    var dateCreated: Date
    var lastPracticed: Date
    var subtopicsOrdered: Bool = false
    var relatedTopics: [String] = []
    var category: String = "Other"

    init(id: UUID = UUID(), name: String, subtopics: [String] = [], dateCreated: Date = Date(), lastPracticed: Date = Date(), subtopicsOrdered: Bool = false, relatedTopics: [String] = [], category: String = "Other") {
        self.id = id
        self.name = name
        self.subtopics = subtopics
        self.dateCreated = dateCreated
        self.lastPracticed = lastPracticed
        self.subtopicsOrdered = subtopicsOrdered
        self.relatedTopics = relatedTopics
        self.category = category
    }
}
