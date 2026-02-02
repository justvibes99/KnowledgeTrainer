import Foundation

struct AchievementDefinition: Identifiable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let xpReward: Int
    let category: AchievementCategory

    enum AchievementCategory: String, CaseIterable {
        case learning = "Learning"
        case streak = "Streak"
        case mastery = "Mastery"
        case dedication = "Dedication"
    }

    static let all: [AchievementDefinition] = [
        // Learning
        AchievementDefinition(
            id: "first_subtopic", name: "First Steps",
            description: "Master your first subtopic",
            iconName: "star", xpReward: 25, category: .learning
        ),
        AchievementDefinition(
            id: "first_topic", name: "Completionist",
            description: "Master every subtopic in a topic",
            iconName: "trophy", xpReward: 100, category: .learning
        ),
        AchievementDefinition(
            id: "five_topics", name: "Knowledge Collector",
            description: "Master 5 complete topics",
            iconName: "books.vertical", xpReward: 250, category: .learning
        ),
        AchievementDefinition(
            id: "ten_topics", name: "Walking Encyclopedia",
            description: "Master 10 complete topics",
            iconName: "building.columns", xpReward: 500, category: .learning
        ),
        // Streak
        AchievementDefinition(
            id: "streak_7", name: "Weekly Regular",
            description: "Maintain a 7-day streak",
            iconName: "flame", xpReward: 75, category: .streak
        ),
        AchievementDefinition(
            id: "streak_14", name: "Two-Week Warrior",
            description: "Maintain a 14-day streak",
            iconName: "flame.fill", xpReward: 150, category: .streak
        ),
        AchievementDefinition(
            id: "streak_30", name: "Monthly Scholar",
            description: "Maintain a 30-day streak",
            iconName: "bolt.fill", xpReward: 300, category: .streak
        ),
        // Mastery
        AchievementDefinition(
            id: "perfect_session", name: "Flawless",
            description: "100% accuracy with 5+ questions",
            iconName: "sparkles", xpReward: 25, category: .mastery
        ),
        AchievementDefinition(
            id: "difficulty_max", name: "Pinnacle",
            description: "Answer correctly in Deep mode",
            iconName: "mountain.2", xpReward: 50, category: .mastery
        ),
        AchievementDefinition(
            id: "ninety_accuracy", name: "Sharp Mind",
            description: "90%+ accuracy across 100+ questions",
            iconName: "scope", xpReward: 100, category: .mastery
        ),
        AchievementDefinition(
            id: "three_subtopics_one_day", name: "Speed Scholar",
            description: "Master 3 subtopics in one day",
            iconName: "hare", xpReward: 75, category: .mastery
        ),
        // Dedication
        AchievementDefinition(
            id: "hundred_questions", name: "Century",
            description: "Answer 100 questions",
            iconName: "number", xpReward: 50, category: .dedication
        ),
        AchievementDefinition(
            id: "five_hundred_questions", name: "Dedicated Learner",
            description: "Answer 500 questions",
            iconName: "text.justify", xpReward: 150, category: .dedication
        ),
        AchievementDefinition(
            id: "review_clear", name: "Clean Slate",
            description: "Clear all due reviews in a session",
            iconName: "checkmark.circle", xpReward: 30, category: .dedication
        ),
    ]

    static func find(_ id: String) -> AchievementDefinition? {
        all.first { $0.id == id }
    }
}
