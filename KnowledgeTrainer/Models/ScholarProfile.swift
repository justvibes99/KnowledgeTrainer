import Foundation
import SwiftData

@Model
final class ScholarProfile {
    @Attribute(.unique) var id: UUID
    var totalXP: Int
    var streakFreezes: Int
    var streakFreezeDatesUsed: [Date]
    var dailyGoalCompleted: Bool
    var dailyGoalDate: Date

    var rank: ScholarRank {
        ScholarRank.forXP(totalXP)
    }

    init(
        id: UUID = UUID(),
        totalXP: Int = 0,
        streakFreezes: Int = 0,
        streakFreezeDatesUsed: [Date] = [],
        dailyGoalCompleted: Bool = false,
        dailyGoalDate: Date = Calendar.current.startOfDay(for: Date())
    ) {
        self.id = id
        self.totalXP = totalXP
        self.streakFreezes = streakFreezes
        self.streakFreezeDatesUsed = streakFreezeDatesUsed
        self.dailyGoalCompleted = dailyGoalCompleted
        self.dailyGoalDate = dailyGoalDate
    }

    func isDailyGoalCurrent() -> Bool {
        Calendar.current.isDateInToday(dailyGoalDate)
    }

    func resetDailyGoalIfNeeded() {
        if !isDailyGoalCurrent() {
            dailyGoalCompleted = false
            dailyGoalDate = Calendar.current.startOfDay(for: Date())
        }
    }

    func canPurchaseStreakFreeze() -> Bool {
        totalXP >= 200 && streakFreezes < 3
    }

    func purchaseStreakFreeze() -> Bool {
        guard canPurchaseStreakFreeze() else { return false }
        totalXP -= 200
        streakFreezes += 1
        return true
    }

    func useStreakFreeze(for date: Date) -> Bool {
        guard streakFreezes > 0 else { return false }
        streakFreezes -= 1
        streakFreezeDatesUsed.append(Calendar.current.startOfDay(for: date))
        return true
    }
}
