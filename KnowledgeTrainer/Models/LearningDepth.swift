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
        case .casual: return "Simple recall, straightforward questions about key facts"
        case .standard: return "Analysis, comparing concepts, moderate complexity"
        case .deep: return "Expert-level, nuanced understanding, edge cases, deep critical thinking"
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
}
