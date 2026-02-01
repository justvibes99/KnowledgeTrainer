import SwiftUI

enum TopicCategory: String, CaseIterable {
    case history = "History"
    case science = "Science"
    case geography = "Geography"
    case artsCulture = "Arts & Culture"
    case sports = "Sports"
    case entertainment = "Entertainment"
    case technology = "Technology"
    case nature = "Nature"
    case language = "Language"
    case other = "Other"

    var icon: String {
        switch self {
        case .history: return "clock.arrow.circlepath"
        case .science: return "atom"
        case .geography: return "globe.americas"
        case .artsCulture: return "paintpalette"
        case .sports: return "sportscourt"
        case .entertainment: return "film"
        case .technology: return "cpu"
        case .nature: return "leaf"
        case .language: return "character.book.closed"
        case .other: return "square.grid.2x2"
        }
    }

    var color: Color {
        switch self {
        case .history: return .brutalYellow
        case .science: return .brutalTeal
        case .geography: return .brutalMint
        case .artsCulture: return .brutalLavender
        case .sports: return .brutalCoral
        case .entertainment: return .brutalYellow
        case .technology: return .brutalTeal
        case .nature: return .brutalMint
        case .language: return .brutalLavender
        case .other: return .brutalCoral
        }
    }

    static func from(_ string: String) -> TopicCategory {
        allCases.first { $0.rawValue == string } ?? .other
    }
}
