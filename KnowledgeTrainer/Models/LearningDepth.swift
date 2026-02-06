import Foundation

enum LearningDepth: String, CaseIterable {
    case casual
    case standard
    case deep

    static var current: LearningDepth {
        guard let raw = UserDefaults.standard.string(forKey: "learningDepth"),
              let depth = LearningDepth(rawValue: raw) else {
            return .standard
        }
        return depth
    }

    var displayName: String {
        switch self {
        case .casual: return "Casual"
        case .standard: return "Standard"
        case .deep: return "Deep"
        }
    }

    var difficultyInt: Int {
        switch self {
        case .casual: return 2
        case .standard: return 3
        case .deep: return 5
        }
    }

    var difficultyDescription: String {
        switch self {
        case .casual: return "Recall and identification — ask what, who, when, where. Test recognition of key facts, names, dates, definitions."
        case .standard: return "Understanding and application — ask why, how, compare, contrast. Require explaining relationships or applying concepts."
        case .deep: return "Analysis and evaluation — edge cases, exceptions, cause-effect chains, synthesis. Require reasoning, not memorization."
        }
    }

    var difficultyRange: String {
        switch self {
        case .casual: return "1-3, averaging 2"
        case .standard: return "2-4, averaging 3"
        case .deep: return "4-5, averaging 5"
        }
    }

    var overviewSentences: String {
        switch self {
        case .casual: return "2-3"
        case .standard: return "3-5"
        case .deep: return "5-7"
        }
    }

    var keyFactsCount: String {
        switch self {
        case .casual: return "4-5"
        case .standard: return "6-8"
        case .deep: return "8-10"
        }
    }

    /// Bloom's taxonomy allocation for question generation — how many of each cognitive level per 10-question batch
    var bloomsAllocation: String {
        switch self {
        case .casual:
            return "6 Remember, 3 Understand, 1 Apply"
        case .standard:
            return "2 Remember, 3 Understand, 3 Apply, 2 Analyze"
        case .deep:
            return "1 Understand, 2 Apply, 4 Analyze, 2 Evaluate, 1 Create"
        }
    }
}
