import Foundation
import SwiftData

@Model
final class QuestionRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var topicID: UUID
    var subtopic: String
    var difficulty: Int
    var questionText: String
    var userResponse: String
    var correctAnswer: String
    var wasCorrect: Bool
    var explanation: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        topicID: UUID,
        subtopic: String,
        difficulty: Int,
        questionText: String,
        userResponse: String,
        correctAnswer: String,
        wasCorrect: Bool,
        explanation: String
    ) {
        self.id = id
        self.date = date
        self.topicID = topicID
        self.subtopic = subtopic
        self.difficulty = difficulty
        self.questionText = questionText
        self.userResponse = userResponse
        self.correctAnswer = correctAnswer
        self.wasCorrect = wasCorrect
        self.explanation = explanation
    }
}
