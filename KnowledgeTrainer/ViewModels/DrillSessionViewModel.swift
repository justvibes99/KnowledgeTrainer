import Foundation
import SwiftData
import SwiftUI

enum QuestionFormat: String {
    case mixed
    case multipleChoice
    case shortAnswer
}

@Observable
final class DrillSessionViewModel {
    // Session State
    var currentQuestion: GeneratedQuestion?
    var userAnswer: String = ""
    var isAnswerSubmitted: Bool = false
    var isCorrect: Bool = false
    var showExplanation: Bool = false
    var isLoading: Bool = false
    var isFetchingBatch: Bool = false
    var sessionEnded: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    // Lesson Phase
    var showingLesson: Bool = false
    var currentLesson: LessonPayload?
    var pendingLessonForNext: LessonPayload?

    // Mastery Celebration
    var showMasteryCelebration: Bool = false
    var masteredSubtopicName: String = ""
    var nextSubtopicName: String?

    // Session Stats
    var questionsAnswered: Int = 0
    var correctAnswers: Int = 0
    var currentStreak: Int = 0
    var consecutiveCorrect: Int = 0
    var consecutiveWrong: Int = 0
    var currentDifficulty: Int = 1

    // Per-Subtopic Session Stats
    var subtopicSessionStats: [String: (answered: Int, correct: Int)] = [:]
    var masteredThisSession: [String] = []

    // Timer
    var timerEnabled: Bool = false
    var timerDuration: Int = 15
    var timerRemaining: Int = 0
    var timerActive: Bool = false

    // Current Focus
    var focusSubtopic: String?
    var subtopicQuestionNumber: Int = 0
    var questionFormat: QuestionFormat = .mixed

    // Quiz Length
    let maxQuestions: Int = 20

    // Data
    var topic: Topic?
    var selectedSubtopics: Set<String> = []
    private var questionQueue: [GeneratedQuestion] = []
    private var askedQuestions: [String] = []
    private var wrongQuestions: [(question: GeneratedQuestion, userAnswer: String)] = []
    private var reviewItemsQueue: [ReviewItem] = []
    private var isServingReview: Bool = false
    private var currentReviewItem: ReviewItem?
    private var timerTask: Task<Void, Never>?
    private var allSubtopicsOrdered: [String] = []

    // Gamification
    var gamificationService: GamificationService?

    var sessionAccuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered) * 100
    }

    enum ComboTier: Int {
        case none = 0
        case three = 3
        case five = 5
        case ten = 10

        var label: String {
            switch self {
            case .none: ""
            case .three: "3x COMBO"
            case .five: "5x COMBO"
            case .ten: "10x COMBO"
            }
        }

        var color: Color {
            switch self {
            case .none: .clear
            case .three: .brutalTeal
            case .five: .brutalYellow
            case .ten: .brutalCoral
            }
        }
    }

    var comboTier: ComboTier {
        if currentStreak >= 10 { return .ten }
        if currentStreak >= 5 { return .five }
        if currentStreak >= 3 { return .three }
        return .none
    }

    var wrongAnswers: [(question: GeneratedQuestion, userAnswer: String)] {
        return wrongQuestions
    }

    // MARK: - Setup

    func setup(
        topic: Topic,
        subtopics: Set<String>,
        initialQuestions: [GeneratedQuestion],
        reviewItems: [ReviewItem],
        timerEnabled: Bool,
        timerDuration: Int,
        initialLesson: LessonPayload? = nil,
        focusSubtopic: String? = nil,
        subtopicProgressItems: [SubtopicProgress] = [],
        questionFormat: QuestionFormat = .mixed
    ) {
        self.topic = topic
        self.selectedSubtopics = subtopics
        self.questionFormat = questionFormat
        self.questionQueue = filterQuestions(initialQuestions)
        self.timerEnabled = timerEnabled
        self.timerDuration = timerDuration
        self.allSubtopicsOrdered = topic.subtopics

        let dueReviews = SpacedRepetitionEngine.dueItems(from: reviewItems)
            .filter { $0.topicID == topic.id }
        self.reviewItemsQueue = dueReviews

        // Determine focus subtopic
        if let focus = focusSubtopic {
            self.focusSubtopic = focus
        } else if topic.subtopicsOrdered, let firstUnmastered = findFirstUnmasteredSubtopic(progressItems: subtopicProgressItems, topicID: topic.id) {
            self.focusSubtopic = firstUnmastered
        }

        // Show lesson if available
        if let lesson = initialLesson {
            self.currentLesson = lesson
            // Check if lesson has already been viewed
            let lessonSubtopic = lesson.subtopic
            let alreadyViewed = subtopicProgressItems.first { $0.topicID == topic.id && $0.subtopicName == lessonSubtopic }?.lessonViewed ?? false
            if !alreadyViewed {
                self.showingLesson = true
                return
            }
        }

        serveNextQuestion()
    }

    func setupReviewOnly(reviewItems: [ReviewItem], timerEnabled: Bool, timerDuration: Int) {
        self.timerEnabled = timerEnabled
        self.timerDuration = timerDuration
        self.reviewItemsQueue = SpacedRepetitionEngine.dueItems(from: reviewItems)
        serveNextQuestion()
    }

    // MARK: - Lesson Flow

    func dismissLesson(modelContext: ModelContext) {
        guard let lesson = currentLesson, let topic = topic else {
            showingLesson = false
            serveNextQuestion()
            return
        }

        // Mark lesson as viewed
        let topicID = topic.id
        let subtopicName = lesson.subtopic
        let descriptor = FetchDescriptor<SubtopicProgress>(
            predicate: #Predicate { $0.topicID == topicID && $0.subtopicName == subtopicName }
        )
        if let progress = try? modelContext.fetch(descriptor).first {
            progress.lessonViewed = true
            progress.lessonOverview = lesson.overview
            progress.lessonKeyFacts = lesson.keyFacts
            progress.lessonMisconceptions = lesson.misconceptions ?? []
            progress.lessonConnections = lesson.connections ?? []
            try? modelContext.save()
        }

        showingLesson = false
        currentLesson = nil
        serveNextQuestion()
    }

    // MARK: - Question Flow

    func serveNextQuestion() {
        stopTimer()
        userAnswer = ""
        isAnswerSubmitted = false
        isCorrect = false
        showExplanation = false
        currentReviewItem = nil
        isServingReview = false

        // Auto-end when max questions reached
        if questionsAnswered >= maxQuestions {
            endSession()
            return
        }

        // Serve review items first
        if !reviewItemsQueue.isEmpty {
            let review = reviewItemsQueue.removeFirst()
            currentReviewItem = review
            isServingReview = true
            currentQuestion = GeneratedQuestion(
                questionText: review.questionText,
                correctAnswer: review.correctAnswer,
                acceptableAnswers: review.acceptableAnswers,
                explanation: review.explanation,
                subtopic: review.subtopic,
                difficulty: 0,
                choices: nil
            )
            startTimer()
            return
        }

        // Serve from question queue
        if questionQueue.isEmpty && topic == nil {
            sessionEnded = true
            return
        }

        if questionQueue.isEmpty {
            isLoading = true
            Task { @MainActor in
                await fetchNextBatch()
                if let q = questionQueue.first {
                    questionQueue.removeFirst()
                    currentQuestion = q
                    askedQuestions.append(q.questionText)
                    updateSubtopicQuestionNumber(q)
                    isLoading = false
                    startTimer()
                } else {
                    sessionEnded = true
                    isLoading = false
                }
            }
            return
        }

        // Pre-fetch when running low, but only if we still need more questions
        let questionsRemaining = maxQuestions - questionsAnswered
        if questionQueue.count <= 5 && questionQueue.count < questionsRemaining && !isFetchingBatch && topic != nil {
            isFetchingBatch = true
            Task { @MainActor in
                await fetchNextBatch()
                isFetchingBatch = false
            }
        }

        let q = questionQueue.removeFirst()
        currentQuestion = q
        askedQuestions.append(q.questionText)
        updateSubtopicQuestionNumber(q)
        startTimer()
    }

    private func updateSubtopicQuestionNumber(_ question: GeneratedQuestion) {
        if let focus = focusSubtopic, question.subtopic == focus {
            subtopicQuestionNumber += 1
        } else if focusSubtopic == nil || question.subtopic != focusSubtopic {
            subtopicQuestionNumber = 0
        }
    }

    // MARK: - Submit Answer

    func submitAnswer(modelContext: ModelContext) async {
        guard let question = currentQuestion, !isAnswerSubmitted else { return }

        stopTimer()
        isAnswerSubmitted = true
        let answer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)

        if question.isMultipleChoice {
            // Multiple choice: exact match against correct answer
            isCorrect = answer == question.correctAnswer
        } else {
            // Free-response: fuzzy matching with API fallback
            let matchResult = ResponseMatcher.evaluate(
                userAnswer: answer,
                acceptableAnswers: question.acceptableAnswers,
                correctAnswer: question.correctAnswer
            )

            switch matchResult {
            case .correct:
                isCorrect = true
            case .incorrect:
                isCorrect = false
            case .uncertain:
                do {
                    isCorrect = try await APIClient.shared.evaluateUncertainResponse(
                        userAnswer: answer,
                        correctAnswer: question.correctAnswer,
                        questionContext: question.questionText
                    )
                } catch {
                    isCorrect = false
                }
            }
        }

        questionsAnswered += 1

        // Update per-subtopic stats
        let subtopic = question.subtopic
        var stats = subtopicSessionStats[subtopic] ?? (answered: 0, correct: 0)
        stats.answered += 1

        if isCorrect {
            correctAnswers += 1
            currentStreak += 1
            consecutiveCorrect += 1
            consecutiveWrong = 0
            stats.correct += 1
            HapticManager.success()

            if isServingReview, let reviewItem = currentReviewItem {
                SpacedRepetitionEngine.processCorrectReview(item: reviewItem)
            }

            if consecutiveCorrect >= 3 && currentDifficulty < 5 {
                currentDifficulty += 1
                consecutiveCorrect = 0
            }
        } else {
            currentStreak = 0
            consecutiveCorrect = 0
            consecutiveWrong += 1
            HapticManager.error()

            wrongQuestions.append((question: question, userAnswer: answer))

            if isServingReview, let reviewItem = currentReviewItem {
                SpacedRepetitionEngine.processIncorrectReview(item: reviewItem)
            } else if let topic = topic {
                let reviewItem = ReviewItem(
                    questionText: question.questionText,
                    correctAnswer: question.correctAnswer,
                    acceptableAnswers: question.acceptableAnswers,
                    explanation: question.explanation,
                    topicID: topic.id,
                    subtopic: question.subtopic
                )
                modelContext.insert(reviewItem)
            }

            if consecutiveWrong >= 2 && currentDifficulty > 1 {
                currentDifficulty -= 1
                consecutiveWrong = 0
            }
        }

        subtopicSessionStats[subtopic] = stats

        // Update SubtopicProgress in SwiftData
        if let topic = topic {
            updateSubtopicProgress(subtopic: subtopic, wasCorrect: isCorrect, modelContext: modelContext)

            let record = QuestionRecord(
                topicID: topic.id,
                subtopic: question.subtopic,
                difficulty: question.difficulty,
                questionText: question.questionText,
                userResponse: answer,
                correctAnswer: question.correctAnswer,
                wasCorrect: isCorrect,
                explanation: question.explanation
            )
            modelContext.insert(record)
            topic.lastPracticed = Date()
        }

        // Update daily streak
        updateDailyStreak(modelContext: modelContext)

        try? modelContext.save()
    }

    func submitTimedOut(modelContext: ModelContext) async {
        userAnswer = ""
        await submitAnswer(modelContext: modelContext)
    }

    // MARK: - Mastery Detection

    private func updateSubtopicProgress(subtopic: String, wasCorrect: Bool, modelContext: ModelContext) {
        guard let topic = topic else { return }
        let topicID = topic.id
        let descriptor = FetchDescriptor<SubtopicProgress>(
            predicate: #Predicate { $0.topicID == topicID && $0.subtopicName == subtopic }
        )

        guard let progress = try? modelContext.fetch(descriptor).first else { return }

        progress.questionsAnswered += 1
        if wasCorrect {
            progress.questionsCorrect += 1
        }

        // Check mastery
        if !progress.isMastered && progress.hasMasteryThreshold {
            progress.isMastered = true
            masteredThisSession.append(subtopic)

            // Award XP for subtopic mastery
            gamificationService?.onSubtopicMastered(subtopicName: subtopic, topicID: topic.id)

            // Trigger celebration
            masteredSubtopicName = subtopic
            nextSubtopicName = findNextSubtopic(after: subtopic)

            // If there's a pending lesson for the next subtopic, queue it
            if let pending = pendingLessonForNext, pending.subtopic == nextSubtopicName {
                currentLesson = pending
                pendingLessonForNext = nil
            }

            showMasteryCelebration = true
        }

        try? modelContext.save()
    }

    func dismissMasteryCelebration() {
        showMasteryCelebration = false

        // If we have a lesson for the next subtopic, show it
        if let lesson = currentLesson {
            focusSubtopic = lesson.subtopic
            subtopicQuestionNumber = 0
            showingLesson = true
        } else if let next = nextSubtopicName {
            focusSubtopic = next
            subtopicQuestionNumber = 0
        }
    }

    private func findNextSubtopic(after current: String) -> String? {
        guard let idx = allSubtopicsOrdered.firstIndex(of: current),
              idx + 1 < allSubtopicsOrdered.count else { return nil }
        return allSubtopicsOrdered[idx + 1]
    }

    private func findFirstUnmasteredSubtopic(progressItems: [SubtopicProgress], topicID: UUID) -> String? {
        let topicProgress = progressItems
            .filter { $0.topicID == topicID }
            .sorted { $0.sortOrder < $1.sortOrder }

        return topicProgress.first { !$0.isMastered }?.subtopicName
    }

    // MARK: - End Session

    func endSession() {
        stopTimer()
        gamificationService?.onSessionEnd(
            questionsAnswered: questionsAnswered,
            correctAnswers: correctAnswers,
            maxDifficulty: currentDifficulty
        )
        sessionEnded = true
    }

    // MARK: - Timer

    private func startTimer() {
        guard timerEnabled else { return }
        timerRemaining = timerDuration
        timerActive = true
        timerTask = Task { @MainActor in
            while timerRemaining > 0 && timerActive && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if timerActive && !Task.isCancelled {
                    timerRemaining -= 1
                }
            }
        }
    }

    private func stopTimer() {
        timerActive = false
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Fetch Batch

    private func fetchNextBatch() async {
        guard let topic = topic else { return }

        // Determine if we should request a lesson for the next subtopic
        let nextSub: String?
        if let focus = focusSubtopic {
            nextSub = findNextSubtopic(after: focus)
        } else {
            nextSub = nil
        }

        do {
            let subtopicsToSend: [String]
            if let focus = focusSubtopic {
                subtopicsToSend = [focus]
            } else {
                subtopicsToSend = Array(selectedSubtopics)
            }
            let (newQuestions, nextLesson) = try await APIClient.shared.generateQuestionBatch(
                topic: topic.name,
                subtopics: subtopicsToSend,
                difficulty: currentDifficulty,
                previousQuestions: askedQuestions,
                focusSubtopic: focusSubtopic,
                nextSubtopic: nextSub
            )
            questionQueue.append(contentsOf: filterQuestions(newQuestions))

            if let lesson = nextLesson {
                pendingLessonForNext = lesson
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func filterQuestions(_ questions: [GeneratedQuestion]) -> [GeneratedQuestion] {
        // First filter by subtopic if focused
        var result = questions
        if let focus = focusSubtopic {
            let subtopicFiltered = result.filter { $0.subtopic == focus }
            if !subtopicFiltered.isEmpty {
                result = subtopicFiltered
            }
        }

        // Then filter by format
        switch questionFormat {
        case .mixed:
            return result
        case .multipleChoice:
            let filtered = result.filter { $0.isMultipleChoice }
            return filtered.isEmpty ? result : filtered
        case .shortAnswer:
            let filtered = result.filter { !$0.isMultipleChoice }
            return filtered.isEmpty ? result : filtered
        }
    }

    // MARK: - Daily Streak

    private func updateDailyStreak(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<DailyStreak>(
            predicate: #Predicate { $0.date == today }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.questionsCompleted += 1
        } else {
            let streak = DailyStreak(date: today, questionsCompleted: 1)
            modelContext.insert(streak)
        }
    }
}
