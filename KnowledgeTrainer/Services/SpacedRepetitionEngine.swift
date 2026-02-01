import Foundation
import SwiftData

struct SpacedRepetitionEngine {
    // SM-2 Algorithm implementation

    static func processCorrectReview(item: ReviewItem) {
        item.reviewCount += 1

        if item.reviewCount == 1 {
            item.intervalDays = 1
        } else if item.reviewCount == 2 {
            item.intervalDays = 3
        } else {
            item.intervalDays = item.intervalDays * item.easeFactor
        }

        item.easeFactor = min(2.5, item.easeFactor + 0.1)
        item.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: Int(item.intervalDays.rounded()),
            to: Date()
        ) ?? Date()
    }

    static func processIncorrectReview(item: ReviewItem) {
        item.intervalDays = 1
        item.easeFactor = max(1.3, item.easeFactor - 0.2)
        item.reviewCount = 0
        item.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Date()
        ) ?? Date()
    }

    static func isDue(_ item: ReviewItem) -> Bool {
        return item.nextReviewDate <= Date()
    }

    static func dueItems(from items: [ReviewItem]) -> [ReviewItem] {
        let now = Date()
        return items.filter { $0.nextReviewDate <= now }
    }
}
