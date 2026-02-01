import Foundation
import SwiftData
import SwiftUI

@Observable
final class HomeViewModel {
    var topicInput: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    var createdTopic: Topic?
    var createdQuestions: [GeneratedQuestion] = []
    var createdLesson: LessonPayload?
    var navigateToPath: Bool = false

    // MARK: - Topic Creation

    @MainActor
    func startNewTopic(modelContext: ModelContext) async {
        let input = topicInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let (structure, questions, lesson, relatedTopics, category) = try await APIClient.shared.generateTopicAndFirstBatch(topic: input)

            let topic = Topic(
                name: structure.name,
                subtopics: structure.subtopics,
                dateCreated: Date(),
                lastPracticed: Date(),
                subtopicsOrdered: true,
                relatedTopics: relatedTopics,
                category: category
            )

            modelContext.insert(topic)

            for (index, subtopicName) in structure.subtopics.enumerated() {
                let progress = SubtopicProgress(
                    topicID: topic.id,
                    subtopicName: subtopicName,
                    sortOrder: index
                )
                if index == 0, let lesson = lesson {
                    progress.lessonOverview = lesson.overview
                    progress.lessonKeyFacts = lesson.keyFacts
                    progress.lessonMisconceptions = lesson.misconceptions ?? []
                    progress.lessonConnections = lesson.connections ?? []
                }
                modelContext.insert(progress)
            }

            try modelContext.save()

            createdTopic = topic
            createdQuestions = questions
            createdLesson = lesson
            topicInput = ""
            navigateToPath = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    // MARK: - Want to Learn Queue

    @MainActor
    func startFromQueue(item: WantToLearnItem, modelContext: ModelContext) async {
        topicInput = item.topicName
        modelContext.delete(item)
        try? modelContext.save()
        await startNewTopic(modelContext: modelContext)
    }

    @MainActor
    func removeFromQueue(item: WantToLearnItem, modelContext: ModelContext) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    @MainActor
    func addToQueue(topicName: String, sourceTopicID: UUID? = nil, sourceSubtopic: String? = nil, modelContext: ModelContext) {
        let item = WantToLearnItem(
            topicName: topicName,
            sourceTopicID: sourceTopicID,
            sourceSubtopic: sourceSubtopic
        )
        modelContext.insert(item)
        try? modelContext.save()
        HapticManager.success()
    }

    // MARK: - Stats Helpers

    func totalQuestions(records: [QuestionRecord]) -> Int {
        StatsCalculator.totalQuestionsAnswered(records: records)
    }

    func overallAccuracy(records: [QuestionRecord]) -> Double {
        StatsCalculator.overallAccuracy(records: records)
    }

    func currentStreak(streaks: [DailyStreak]) -> Int {
        StatsCalculator.currentStreak(dailyStreaks: streaks)
    }

    func dueReviewCount(items: [ReviewItem]) -> Int {
        SpacedRepetitionEngine.dueItems(from: items).count
    }

    func topicAccuracy(records: [QuestionRecord], topicID: UUID) -> Double {
        StatsCalculator.topicAccuracy(records: records, topicID: topicID)
    }

    func topicQuestionCount(records: [QuestionRecord], topicID: UUID) -> Int {
        StatsCalculator.questionsForTopic(records: records, topicID: topicID)
    }

    func masteredCount(progressItems: [SubtopicProgress], topicID: UUID) -> Int {
        progressItems.filter { $0.topicID == topicID && $0.isMastered }.count
    }

    func totalSubtopicCount(progressItems: [SubtopicProgress], topicID: UUID) -> Int {
        progressItems.filter { $0.topicID == topicID }.count
    }
}
