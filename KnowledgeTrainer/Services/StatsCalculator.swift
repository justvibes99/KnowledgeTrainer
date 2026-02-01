import Foundation
import SwiftData

struct StatsCalculator {
    static func totalQuestionsAnswered(records: [QuestionRecord]) -> Int {
        return records.count
    }

    static func overallAccuracy(records: [QuestionRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        let correct = records.filter { $0.wasCorrect }.count
        return Double(correct) / Double(records.count) * 100
    }

    static func topicAccuracy(records: [QuestionRecord], topicID: UUID) -> Double {
        let topicRecords = records.filter { $0.topicID == topicID }
        guard !topicRecords.isEmpty else { return 0 }
        let correct = topicRecords.filter { $0.wasCorrect }.count
        return Double(correct) / Double(topicRecords.count) * 100
    }

    static func subtopicAccuracy(records: [QuestionRecord], topicID: UUID, subtopic: String) -> Double {
        let filtered = records.filter { $0.topicID == topicID && $0.subtopic == subtopic }
        guard !filtered.isEmpty else { return 0 }
        let correct = filtered.filter { $0.wasCorrect }.count
        return Double(correct) / Double(filtered.count) * 100
    }

    static func questionsForTopic(records: [QuestionRecord], topicID: UUID) -> Int {
        return records.filter { $0.topicID == topicID }.count
    }

    static func currentStreak(dailyStreaks: [DailyStreak]) -> Int {
        let calendar = Calendar.current
        let sorted = dailyStreaks
            .filter { $0.questionsCompleted > 0 }
            .sorted { $0.date > $1.date }

        guard !sorted.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        guard let mostRecent = sorted.first,
              mostRecent.date >= yesterday else {
            return 0
        }

        var streak = 1
        var checkDate = calendar.date(byAdding: .day, value: -1, to: mostRecent.date)!

        for entry in sorted.dropFirst() {
            let entryDay = calendar.startOfDay(for: entry.date)
            if entryDay == checkDate {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if entryDay < checkDate {
                break
            }
        }

        return streak
    }

    static func currentStreakWithFreezes(dailyStreaks: [DailyStreak], profile: ScholarProfile) -> Int {
        let calendar = Calendar.current
        let sorted = dailyStreaks
            .filter { $0.questionsCompleted > 0 }
            .sorted { $0.date > $1.date }

        guard !sorted.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        guard let mostRecent = sorted.first,
              mostRecent.date >= yesterday else {
            return 0
        }

        let activeDates = Set(sorted.map { calendar.startOfDay(for: $0.date) })
        let freezeDates = Set(profile.streakFreezeDatesUsed.map { calendar.startOfDay(for: $0) })

        var streak = 1
        var checkDate = calendar.date(byAdding: .day, value: -1, to: mostRecent.date)!

        while true {
            if activeDates.contains(checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if freezeDates.contains(checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        return streak
    }

    static func accuracyOverTime(records: [QuestionRecord], days: Int = 30) -> [(Date, Double)] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!

        let filtered = records.filter { $0.date >= startDate }
        var grouped: [Date: [QuestionRecord]] = [:]

        for record in filtered {
            let day = calendar.startOfDay(for: record.date)
            grouped[day, default: []].append(record)
        }

        return grouped.map { (date, records) in
            let correct = records.filter { $0.wasCorrect }.count
            let accuracy = Double(correct) / Double(records.count) * 100
            return (date, accuracy)
        }.sorted { $0.0 < $1.0 }
    }

    static func dailyActivity(records: [QuestionRecord], days: Int = 14) -> [(Date, Int)] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!

        var result: [(Date, Int)] = []
        for dayOffset in 0..<days {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let count = records.filter { $0.date >= dayStart && $0.date < dayEnd }.count
            result.append((dayStart, count))
        }

        return result
    }

    static func maxDifficultyReached(records: [QuestionRecord], topicID: UUID) -> Int {
        let topicRecords = records.filter { $0.topicID == topicID }
        return topicRecords.map { $0.difficulty }.max() ?? 1
    }
}
