import Foundation
import SwiftData

@Model
final class SubtopicProgress {
    @Attribute(.unique) var id: UUID
    var topicID: UUID
    var subtopicName: String
    var sortOrder: Int
    var questionsAnswered: Int
    var questionsCorrect: Int
    var isMastered: Bool
    var lessonOverview: String
    var lessonKeyFacts: [String]
    var lessonMisconceptions: [String] = []
    var lessonConnections: [String] = []
    var lessonViewed: Bool

    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(questionsCorrect) / Double(questionsAnswered) * 100
    }

    var hasMasteryThreshold: Bool {
        questionsAnswered >= 10 && accuracy >= 80
    }

    init(
        id: UUID = UUID(),
        topicID: UUID,
        subtopicName: String,
        sortOrder: Int,
        questionsAnswered: Int = 0,
        questionsCorrect: Int = 0,
        isMastered: Bool = false,
        lessonOverview: String = "",
        lessonKeyFacts: [String] = [],
        lessonMisconceptions: [String] = [],
        lessonConnections: [String] = [],
        lessonViewed: Bool = false
    ) {
        self.id = id
        self.topicID = topicID
        self.subtopicName = subtopicName
        self.sortOrder = sortOrder
        self.questionsAnswered = questionsAnswered
        self.questionsCorrect = questionsCorrect
        self.isMastered = isMastered
        self.lessonOverview = lessonOverview
        self.lessonKeyFacts = lessonKeyFacts
        self.lessonMisconceptions = lessonMisconceptions
        self.lessonConnections = lessonConnections
        self.lessonViewed = lessonViewed
    }
}
