import Foundation
import SwiftData
import SwiftUI

@Observable
final class TrainViewModel {
    var topicInput: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    var navigateToDrill: Bool = false

    var currentTopic: Topic?
    var currentSubtopics: [String] = []
    var selectedSubtopics: Set<String> = []
    var initialQuestions: [GeneratedQuestion] = []
    var initialLesson: LessonPayload?

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

            // Create SubtopicProgress records for each subtopic
            for (index, subtopicName) in structure.subtopics.enumerated() {
                let progress = SubtopicProgress(
                    topicID: topic.id,
                    subtopicName: subtopicName,
                    sortOrder: index
                )
                // Store lesson content for the first subtopic if available
                if index == 0, let lesson = lesson {
                    progress.lessonOverview = lesson.overview
                    progress.lessonKeyFacts = lesson.keyFacts
                    progress.lessonMisconceptions = lesson.misconceptions ?? []
                    progress.lessonConnections = lesson.connections ?? []
                }
                modelContext.insert(progress)
            }

            try modelContext.save()

            currentTopic = topic
            currentSubtopics = structure.subtopics
            selectedSubtopics = Set(structure.subtopics)
            initialQuestions = questions
            initialLesson = lesson
            topicInput = ""
            navigateToDrill = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func resumeTopic(_ topic: Topic) {
        currentTopic = topic
        currentSubtopics = topic.subtopics
        selectedSubtopics = Set(topic.subtopics)
        initialQuestions = []
        initialLesson = nil
        navigateToDrill = true
    }

    func dueReviewCount(reviewItems: [ReviewItem]) -> Int {
        return SpacedRepetitionEngine.dueItems(from: reviewItems).count
    }

    func topicAccuracy(records: [QuestionRecord], topicID: UUID) -> Double {
        return StatsCalculator.topicAccuracy(records: records, topicID: topicID)
    }

    func topicQuestionCount(records: [QuestionRecord], topicID: UUID) -> Int {
        return StatsCalculator.questionsForTopic(records: records, topicID: topicID)
    }

    func masteredCount(progressItems: [SubtopicProgress], topicID: UUID) -> Int {
        progressItems.filter { $0.topicID == topicID && $0.isMastered }.count
    }

    func totalSubtopicCount(progressItems: [SubtopicProgress], topicID: UUID) -> Int {
        progressItems.filter { $0.topicID == topicID }.count
    }
}
