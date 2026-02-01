import Foundation
import SwiftData

@Observable
final class ProfileViewModel {
    var showDeleteConfirmation: Bool = false
    var topicToDelete: Topic?
    var showResetConfirmation: Bool = false

    // Settings
    var timerEnabled: Bool = UserDefaults.standard.bool(forKey: "timerEnabled")
    var timerDuration: Int = UserDefaults.standard.integer(forKey: "timerDuration") == 0 ? 15 : UserDefaults.standard.integer(forKey: "timerDuration")
    var reminderEnabled: Bool = UserDefaults.standard.bool(forKey: "reminderEnabled")
    var reminderTime: Date = {
        if let timeInterval = UserDefaults.standard.object(forKey: "reminderTime") as? TimeInterval {
            return Date(timeIntervalSince1970: timeInterval)
        }
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    func saveTimerSettings() {
        UserDefaults.standard.set(timerEnabled, forKey: "timerEnabled")
        UserDefaults.standard.set(timerDuration, forKey: "timerDuration")
    }

    func saveReminderSettings() {
        UserDefaults.standard.set(reminderEnabled, forKey: "reminderEnabled")
        UserDefaults.standard.set(reminderTime.timeIntervalSince1970, forKey: "reminderTime")

        if reminderEnabled {
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            NotificationManager.scheduleDailyReminder(
                hour: components.hour ?? 9,
                minute: components.minute ?? 0
            )
        } else {
            NotificationManager.cancelDailyReminder()
        }
    }

    func deleteTopic(_ topic: Topic, modelContext: ModelContext) {
        let topicID = topic.id
        let recordDescriptor = FetchDescriptor<QuestionRecord>(
            predicate: #Predicate { $0.topicID == topicID }
        )
        let reviewDescriptor = FetchDescriptor<ReviewItem>(
            predicate: #Predicate { $0.topicID == topicID }
        )

        if let records = try? modelContext.fetch(recordDescriptor) {
            for record in records { modelContext.delete(record) }
        }
        if let reviews = try? modelContext.fetch(reviewDescriptor) {
            for review in reviews { modelContext.delete(review) }
        }

        modelContext.delete(topic)
        try? modelContext.save()
    }

    func resetAllData(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: Topic.self)
            try modelContext.delete(model: QuestionRecord.self)
            try modelContext.delete(model: ReviewItem.self)
            try modelContext.delete(model: DeepDive.self)
            try modelContext.delete(model: DailyStreak.self)
            try modelContext.delete(model: SubtopicProgress.self)
            try modelContext.delete(model: WantToLearnItem.self)
            try? KeychainManager.delete()
            UserDefaults.standard.removeObject(forKey: "timerEnabled")
            UserDefaults.standard.removeObject(forKey: "timerDuration")
            UserDefaults.standard.removeObject(forKey: "reminderEnabled")
            UserDefaults.standard.removeObject(forKey: "reminderTime")
            NotificationManager.cancelDailyReminder()
        } catch {
            // Silently handle - data may already be cleared
        }
    }

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

    func accuracyColor(accuracy: Double) -> String {
        if accuracy < 40 { return "coral" }
        if accuracy < 70 { return "yellow" }
        return "green"
    }
}
