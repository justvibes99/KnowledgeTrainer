import Foundation
import SwiftData

@Model
final class ReviewItem {
    @Attribute(.unique) var id: UUID
    var questionText: String
    var correctAnswer: String
    var acceptableAnswers: [String]
    var explanation: String
    var topicID: UUID
    var subtopic: String
    var dateMissed: Date
    var nextReviewDate: Date
    var intervalDays: Double
    var easeFactor: Double
    var reviewCount: Int

    init(
        id: UUID = UUID(),
        questionText: String,
        correctAnswer: String,
        acceptableAnswers: [String],
        explanation: String,
        topicID: UUID,
        subtopic: String,
        dateMissed: Date = Date(),
        nextReviewDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
        intervalDays: Double = 1.0,
        easeFactor: Double = 2.5,
        reviewCount: Int = 0
    ) {
        self.id = id
        self.questionText = questionText
        self.correctAnswer = correctAnswer
        self.acceptableAnswers = acceptableAnswers
        self.explanation = explanation
        self.topicID = topicID
        self.subtopic = subtopic
        self.dateMissed = dateMissed
        self.nextReviewDate = nextReviewDate
        self.intervalDays = intervalDays
        self.easeFactor = easeFactor
        self.reviewCount = reviewCount
    }
}
