import Foundation
import SwiftData

@Model
final class DailyStreak {
    @Attribute(.unique) var id: UUID
    var date: Date
    var questionsCompleted: Int

    init(id: UUID = UUID(), date: Date = Date(), questionsCompleted: Int = 0) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.questionsCompleted = questionsCompleted
    }
}
