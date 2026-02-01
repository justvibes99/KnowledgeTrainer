import Foundation
import SwiftData

@Model
final class Achievement {
    @Attribute(.unique) var id: String
    var unlockedDate: Date
    var xpAwarded: Int

    var definition: AchievementDefinition? {
        AchievementDefinition.find(id)
    }

    init(id: String, unlockedDate: Date = Date(), xpAwarded: Int = 0) {
        self.id = id
        self.unlockedDate = unlockedDate
        self.xpAwarded = xpAwarded
    }
}
