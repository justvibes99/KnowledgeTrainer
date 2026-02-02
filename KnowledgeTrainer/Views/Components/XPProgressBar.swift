import SwiftUI

struct XPProgressBar: View {
    let currentXP: Int
    let rank: ScholarRank

    private var progress: Double {
        rank.progressToNext(currentXP: currentXP)
    }

    private var label: String {
        if let next = rank.xpToNextRank {
            return "\(currentXP) / \(next) XP"
        }
        return "\(currentXP) XP — Max Rank"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.flatSurfaceSubtle)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(rank.color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.flatSecondaryText)
        }
    }
}
