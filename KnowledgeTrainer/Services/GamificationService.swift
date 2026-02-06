import Foundation
import SwiftData

struct XPEvent: Identifiable {
    let id = UUID()
    let amount: Int
    let reason: String
}

final class GamificationService: ObservableObject {
    @Published var pendingXPEvents: [XPEvent] = []
    @Published var unlockedAchievements: [AchievementDefinition] = []
    @Published var didRankUp = false
    @Published var newRank: ScholarRank?

    private var context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Profile Access

    func getProfile() -> ScholarProfile? {
        let descriptor = FetchDescriptor<ScholarProfile>()
        return try? context.fetch(descriptor).first
    }

    // MARK: - XP Awarding

    private func awardXP(_ amount: Int, reason: String, profile: ScholarProfile) {
        let oldRank = profile.rank
        profile.totalXP += amount
        let newRankValue = profile.rank
        pendingXPEvents.append(XPEvent(amount: amount, reason: reason))

        if newRankValue.rawValue > oldRank.rawValue {
            didRankUp = true
            newRank = newRankValue
        }
    }

    // MARK: - Subtopic Mastered

    func onSubtopicMastered(subtopicName: String, topicID: UUID) {
        guard let profile = getProfile() else { return }

        // +50 XP for mastering a subtopic
        awardXP(50, reason: "Mastered: \(subtopicName)", profile: profile)

        // Check if this is the first subtopic ever
        let allProgress = fetchAllSubtopicProgress()
        let totalMastered = allProgress.filter { $0.isMastered }.count
        if totalMastered == 1 {
            awardXP(100, reason: "First subtopic ever mastered!", profile: profile)
        }

        // Check if full topic is now mastered
        checkTopicMastery(topicID: topicID, profile: profile)

        // Daily goal
        if !profile.isDailyGoalCurrent() {
            profile.resetDailyGoalIfNeeded()
        }
        if !profile.dailyGoalCompleted {
            profile.dailyGoalCompleted = true
        }

        // Check achievements
        checkAchievements(profile: profile)

        try? context.save()
    }

    // MARK: - Topic Mastery

    private func checkTopicMastery(topicID: UUID, profile: ScholarProfile) {
        guard let topic = fetchTopic(id: topicID) else { return }
        let progress = fetchSubtopicProgress(for: topicID)

        let allMastered = topic.subtopics.allSatisfy { subtopicName in
            progress.contains { $0.subtopicName == subtopicName && $0.isMastered }
        }

        guard allMastered && !topic.subtopics.isEmpty else { return }

        awardXP(200, reason: "Mastered topic: \(topic.name)", profile: profile)

        // Check if first topic ever
        let allTopicsMastered = countFullyMasteredTopics()
        if allTopicsMastered == 1 {
            awardXP(100, reason: "First topic ever mastered!", profile: profile)
        }
    }

    // MARK: - Session End

    func onSessionEnd(questionsAnswered: Int, correctAnswers: Int, maxDifficulty: Int) {
        guard let profile = getProfile() else { return }

        // Perfect session: 5+ questions, 100% accuracy
        if questionsAnswered >= 5 && correctAnswers == questionsAnswered {
            awardXP(25, reason: "Perfect session!", profile: profile)
        }

        checkAchievements(
            profile: profile,
            sessionQuestions: questionsAnswered,
            sessionCorrect: correctAnswers,
            sessionMaxDifficulty: maxDifficulty
        )

        try? context.save()
    }

    // MARK: - Reviews Cleared

    func onAllReviewsCleared() {
        guard let profile = getProfile() else { return }
        awardXP(30, reason: "Cleared all due reviews", profile: profile)
        checkAchievements(profile: profile)
        try? context.save()
    }

    // MARK: - Streak XP

    func onStreakMilestone(days: Int) {
        guard let profile = getProfile() else { return }

        switch days {
        case 7:
            awardXP(75, reason: "7-day streak!", profile: profile)
        case 14:
            awardXP(150, reason: "14-day streak!", profile: profile)
        case 30:
            awardXP(300, reason: "30-day streak!", profile: profile)
        default:
            break
        }

        checkAchievements(profile: profile)
        try? context.save()
    }

    // MARK: - Achievement Checking

    private func checkAchievements(
        profile: ScholarProfile,
        sessionQuestions: Int = 0,
        sessionCorrect: Int = 0,
        sessionMaxDifficulty: Int = 0
    ) {
        let unlocked = fetchUnlockedAchievementIDs()

        // Early exit if all achievements are already unlocked
        if unlocked.count >= AchievementDefinition.all.count { return }

        // Session-dependent checks (no fetch needed)
        let sessionChecks: [(String, Bool)] = [
            ("perfect_session", sessionQuestions >= 5 && sessionCorrect == sessionQuestions && sessionQuestions > 0),
            ("difficulty_max", sessionMaxDifficulty >= 5 && sessionCorrect > 0),
        ]

        for (id, condition) in sessionChecks {
            if condition && !unlocked.contains(id) {
                unlockAchievement(id: id, profile: profile)
            }
        }

        // Progress-dependent checks
        let progressIDs: Set<String> = ["first_subtopic", "first_topic", "five_topics", "ten_topics", "three_subtopics_one_day"]
        if !progressIDs.isSubset(of: unlocked) {
            let allProgress = fetchAllSubtopicProgress()
            let totalMastered = allProgress.filter { $0.isMastered }.count
            let fullyMasteredTopics = countFullyMasteredTopics()

            let progressChecks: [(String, Bool)] = [
                ("first_subtopic", totalMastered >= 1),
                ("first_topic", fullyMasteredTopics >= 1),
                ("five_topics", fullyMasteredTopics >= 5),
                ("ten_topics", fullyMasteredTopics >= 10),
                ("three_subtopics_one_day", subtopicsMasteredToday() >= 3),
            ]

            for (id, condition) in progressChecks {
                if condition && !unlocked.contains(id) {
                    unlockAchievement(id: id, profile: profile)
                }
            }
        }

        // Record-dependent checks
        let recordIDs: Set<String> = ["hundred_questions", "five_hundred_questions", "ninety_accuracy"]
        if !recordIDs.isSubset(of: unlocked) {
            let allRecords = fetchAllQuestionRecords()
            let totalQuestions = allRecords.count
            let overallAccuracy = StatsCalculator.overallAccuracy(records: allRecords)

            let recordChecks: [(String, Bool)] = [
                ("hundred_questions", totalQuestions >= 100),
                ("five_hundred_questions", totalQuestions >= 500),
                ("ninety_accuracy", totalQuestions >= 100 && overallAccuracy >= 90),
            ]

            for (id, condition) in recordChecks {
                if condition && !unlocked.contains(id) {
                    unlockAchievement(id: id, profile: profile)
                }
            }
        }

        // Streak-dependent checks
        let streakIDs: Set<String> = ["streak_7", "streak_14", "streak_30"]
        if !streakIDs.isSubset(of: unlocked) {
            let streak = StatsCalculator.currentStreak(dailyStreaks: fetchDailyStreaks())

            let streakChecks: [(String, Bool)] = [
                ("streak_7", streak >= 7),
                ("streak_14", streak >= 14),
                ("streak_30", streak >= 30),
            ]

            for (id, condition) in streakChecks {
                if condition && !unlocked.contains(id) {
                    unlockAchievement(id: id, profile: profile)
                }
            }
        }

        // Review-dependent check
        if !unlocked.contains("review_clear") {
            if checkAllReviewsCleared() {
                unlockAchievement(id: "review_clear", profile: profile)
            }
        }
    }

    private func unlockAchievement(id: String, profile: ScholarProfile) {
        guard let definition = AchievementDefinition.find(id) else { return }

        let achievement = Achievement(id: id, unlockedDate: Date(), xpAwarded: definition.xpReward)
        context.insert(achievement)

        awardXP(definition.xpReward, reason: "Achievement: \(definition.name)", profile: profile)
        unlockedAchievements.append(definition)
        HapticManager.success()
    }

    // MARK: - Achievement Progress

    func achievementProgress() -> [String: (current: Int, target: Int)] {
        let allProgress = fetchAllSubtopicProgress()
        let totalMastered = allProgress.filter { $0.isMastered }.count
        let fullyMasteredTopics = countFullyMasteredTopics()
        let allRecords = fetchAllQuestionRecords()
        let totalQuestions = allRecords.count
        let streak = StatsCalculator.currentStreak(dailyStreaks: fetchDailyStreaks())

        return [
            "first_subtopic": (min(totalMastered, 1), 1),
            "first_topic": (min(fullyMasteredTopics, 1), 1),
            "five_topics": (min(fullyMasteredTopics, 5), 5),
            "ten_topics": (min(fullyMasteredTopics, 10), 10),
            "streak_7": (min(streak, 7), 7),
            "streak_14": (min(streak, 14), 14),
            "streak_30": (min(streak, 30), 30),
            "hundred_questions": (min(totalQuestions, 100), 100),
            "five_hundred_questions": (min(totalQuestions, 500), 500),
            "ninety_accuracy": (min(totalQuestions, 100), 100),
        ]
    }

    // MARK: - Closest Achievement

    func closestAchievement() -> (definition: AchievementDefinition, current: Int, target: Int)? {
        let unlocked = fetchUnlockedAchievementIDs()
        let progress = achievementProgress()

        return progress
            .filter { !unlocked.contains($0.key) }
            .compactMap { id, prog -> (AchievementDefinition, Int, Int)? in
                guard let def = AchievementDefinition.find(id), prog.current > 0 else { return nil }
                return (def, prog.current, prog.target)
            }
            .max { Double($0.1) / Double($0.2) < Double($1.1) / Double($1.2) }
    }

    // MARK: - Helpers

    func clearPendingEvents() {
        pendingXPEvents.removeAll()
        unlockedAchievements.removeAll()
        didRankUp = false
        newRank = nil
    }

    func resetPendingXPEvents() {
        pendingXPEvents.removeAll()
    }

    private func fetchAllSubtopicProgress() -> [SubtopicProgress] {
        let descriptor = FetchDescriptor<SubtopicProgress>()
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetchSubtopicProgress(for topicID: UUID) -> [SubtopicProgress] {
        let descriptor = FetchDescriptor<SubtopicProgress>(
            predicate: #Predicate { $0.topicID == topicID }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetchTopic(id: UUID) -> Topic? {
        let descriptor = FetchDescriptor<Topic>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    private func fetchAllQuestionRecords() -> [QuestionRecord] {
        let descriptor = FetchDescriptor<QuestionRecord>()
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetchDailyStreaks() -> [DailyStreak] {
        let descriptor = FetchDescriptor<DailyStreak>()
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetchUnlockedAchievementIDs() -> Set<String> {
        let descriptor = FetchDescriptor<Achievement>()
        let achievements = (try? context.fetch(descriptor)) ?? []
        return Set(achievements.map { $0.id })
    }

    private func countFullyMasteredTopics() -> Int {
        let topics = (try? context.fetch(FetchDescriptor<Topic>())) ?? []
        let allProgress = fetchAllSubtopicProgress()

        return topics.filter { topic in
            guard !topic.subtopics.isEmpty else { return false }
            return topic.subtopics.allSatisfy { subtopicName in
                allProgress.contains { $0.topicID == topic.id && $0.subtopicName == subtopicName && $0.isMastered }
            }
        }.count
    }

    private func subtopicsMasteredToday() -> Int {
        let allProgress = fetchAllSubtopicProgress()
        let allRecords = fetchAllQuestionRecords()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Find subtopics that were mastered today by checking records from today
        // for subtopics that are currently mastered
        let masteredSubtopics = allProgress.filter { $0.isMastered }
        var count = 0

        for sp in masteredSubtopics {
            let todayRecords = allRecords.filter {
                $0.topicID == sp.topicID &&
                $0.subtopic == sp.subtopicName &&
                calendar.startOfDay(for: $0.date) == today
            }
            if !todayRecords.isEmpty {
                // If there are records today and it's mastered, it likely was mastered today
                // More precisely: check if the mastery threshold was crossed with today's records
                let totalForSubtopic = allRecords.filter {
                    $0.topicID == sp.topicID && $0.subtopic == sp.subtopicName
                }
                let beforeToday = totalForSubtopic.filter {
                    calendar.startOfDay(for: $0.date) < today
                }
                let beforeCorrect = beforeToday.filter { $0.wasCorrect }.count
                let beforeAccuracy = beforeToday.isEmpty ? 0.0 : Double(beforeCorrect) / Double(beforeToday.count) * 100
                let wasMasteredBefore = beforeToday.count >= 5 && beforeAccuracy >= 80

                if !wasMasteredBefore {
                    count += 1
                }
            }
        }

        return count
    }

    private func checkAllReviewsCleared() -> Bool {
        let now = Date()
        let descriptor = FetchDescriptor<ReviewItem>(
            predicate: #Predicate { $0.nextReviewDate <= now }
        )
        let dueCount = (try? context.fetchCount(descriptor)) ?? 1
        return dueCount == 0
    }
}
