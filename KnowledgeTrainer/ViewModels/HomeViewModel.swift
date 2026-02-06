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
            let depth = LearningDepth.current

            // Call 1: Get structure (fast)
            let (structure, relatedTopics, category) = try await APIClient.shared.generateTopicStructure(topic: input)

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
                modelContext.insert(progress)
            }

            try modelContext.save()

            // Navigate immediately — lesson and questions load in the background
            createdTopic = topic
            createdQuestions = []
            createdLesson = nil
            topicInput = ""
            isLoading = false
            navigateToPath = true

            // Calls 2 & 3: Lesson and questions in parallel (background)
            let firstSubtopic = structure.subtopics.first ?? structure.name
            let topicName = structure.name
            let topicID = topic.id

            Task {
                // Call 2: Generate lesson first
                let lesson = try? await APIClient.shared.generateInitialLesson(topic: topicName, subtopic: firstSubtopic, depth: depth)

                if let lesson {
                    await MainActor.run {
                        self.createdLesson = lesson
                        // Save lesson to SubtopicProgress
                        let descriptor = FetchDescriptor<SubtopicProgress>(
                            predicate: #Predicate { $0.topicID == topicID && $0.subtopicName == firstSubtopic }
                        )
                        if let progress = try? modelContext.fetch(descriptor).first {
                            progress.lessonOverview = lesson.overview
                            progress.lessonKeyFacts = lesson.keyFacts
                            progress.lessonMisconceptions = lesson.misconceptions ?? []
                            progress.lessonConnections = lesson.connections ?? []
                            try? modelContext.save()
                        }
                    }
                }

                // Call 3: Generate questions, seeded with lesson key facts
                let questions = try? await APIClient.shared.generateInitialQuestions(
                    topic: topicName,
                    subtopic: firstSubtopic,
                    keyFacts: lesson?.keyFacts ?? [],
                    depth: depth
                )

                if let questions {
                    await MainActor.run {
                        self.createdQuestions = questions
                        // Cache generated questions
                        for question in questions {
                            modelContext.insert(CachedQuestion.from(question, topicID: topicID))
                        }
                        try? modelContext.save()
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
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

    func quickContinueData(topics: [Topic], progressItems: [SubtopicProgress]) -> (topic: Topic, subtopic: String, masteredCount: Int, totalCount: Int)? {
        for topic in topics {  // Already sorted by lastPracticed desc
            let progress = progressItems
                .filter { $0.topicID == topic.id }
                .sorted { $0.sortOrder < $1.sortOrder }
            let mastered = progress.filter(\.isMastered).count
            if let firstUnmastered = progress.first(where: { !$0.isMastered }) {
                return (topic, firstUnmastered.subtopicName, mastered, progress.count)
            }
        }
        return nil
    }
}
