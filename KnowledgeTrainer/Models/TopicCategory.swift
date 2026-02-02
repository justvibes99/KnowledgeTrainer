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
    case people = "People"
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
        case .people: return "person.2"
        case .other: return "square.grid.2x2"
        }
    }

    var color: Color {
        switch self {
        case .history: return .brutalAmber        // warm amber
        case .science: return .brutalTeal         // teal
        case .geography: return .brutalMint       // green
        case .artsCulture: return .brutalYellow   // purple
        case .sports: return .brutalIndigo        // indigo
        case .entertainment: return .brutalSalmon // gold
        case .technology: return .brutalLavender  // slate blue
        case .nature: return .brutalMint          // green
        case .language: return .brutalYellow      // purple
        case .people: return .brutalCoral         // coral
        case .other: return .brutalTeal           // teal
        }
    }

    static func from(_ string: String) -> TopicCategory {
        allCases.first { $0.rawValue == string } ?? .other
    }
}
