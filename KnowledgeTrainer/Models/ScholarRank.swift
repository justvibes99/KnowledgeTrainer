import SwiftUI

enum ScholarRank: Int, CaseIterable {
    case novice = 1
    case apprentice = 2
    case scholar = 3
    case adept = 4
    case sage = 5
    case master = 6
    case grandmaster = 7

    var title: String {
        switch self {
        case .novice: "Novice"
        case .apprentice: "Apprentice"
        case .scholar: "Scholar"
        case .adept: "Adept"
        case .sage: "Sage"
        case .master: "Master"
        case .grandmaster: "Grandmaster"
        }
    }

    var xpThreshold: Int {
        switch self {
        case .novice: 0
        case .apprentice: 300
        case .scholar: 1_000
        case .adept: 2_500
        case .sage: 5_000
        case .master: 10_000
        case .grandmaster: 20_000
        }
    }

    var iconName: String {
        switch self {
        case .novice: "book.closed"
        case .apprentice: "book"
        case .scholar: "graduationcap"
        case .adept: "text.book.closed"
        case .sage: "brain.head.profile"
        case .master: "crown"
        case .grandmaster: "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .novice: .brutalMint
        case .apprentice: .brutalTeal
        case .scholar: .brutalYellow
        case .adept: .brutalLavender
        case .sage: .brutalCoral
        case .master: .brutalYellow
        case .grandmaster: .brutalCoral
        }
    }

    var nextRank: ScholarRank? {
        ScholarRank(rawValue: rawValue + 1)
    }

    var xpToNextRank: Int? {
        nextRank?.xpThreshold
    }

    static func forXP(_ xp: Int) -> ScholarRank {
        for rank in Self.allCases.reversed() {
            if xp >= rank.xpThreshold {
                return rank
            }
        }
        return .novice
    }

    func progressToNext(currentXP: Int) -> Double {
        guard let next = nextRank else { return 1.0 }
        let rangeTotal = next.xpThreshold - xpThreshold
        let rangeCurrent = currentXP - xpThreshold
        return Double(rangeCurrent) / Double(rangeTotal)
    }
}
