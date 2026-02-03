import Foundation
import SwiftData

@Model
final class CachedQuestion {
    @Attribute(.unique) var id: UUID
    var topicID: UUID
    var subtopic: String
    var questionText: String
    var correctAnswer: String
    var acceptableAnswers: [String]
    var explanation: String
    var difficulty: Int
    var choices: [String]?
    var dateCreated: Date

    init(
        id: UUID = UUID(),
        topicID: UUID,
        subtopic: String,
        questionText: String,
        correctAnswer: String,
        acceptableAnswers: [String],
        explanation: String,
        difficulty: Int,
        choices: [String]? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.topicID = topicID
        self.subtopic = subtopic
        self.questionText = questionText
        self.correctAnswer = correctAnswer
        self.acceptableAnswers = acceptableAnswers
        self.explanation = explanation
        self.difficulty = difficulty
        self.choices = choices
        self.dateCreated = dateCreated
    }

    func toGeneratedQuestion() -> GeneratedQuestion {
        GeneratedQuestion(
            questionText: questionText,
            correctAnswer: correctAnswer,
            acceptableAnswers: acceptableAnswers,
            explanation: explanation,
            subtopic: subtopic,
            difficulty: difficulty,
            choices: choices
        )
    }

    static func from(_ question: GeneratedQuestion, topicID: UUID) -> CachedQuestion {
        CachedQuestion(
            topicID: topicID,
            subtopic: question.subtopic,
            questionText: question.questionText,
            correctAnswer: question.correctAnswer,
            acceptableAnswers: question.acceptableAnswers,
            explanation: question.explanation,
            difficulty: question.difficulty,
            choices: question.choices
        )
    }
}
