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
        return "\(currentXP) XP — MAX RANK"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.brutalBackground)
                        .overlay(
                            Rectangle()
                                .stroke(Color.brutalBlack, lineWidth: 3)
                        )

                    Rectangle()
                        .fill(rank.color)
                        .frame(width: geo.size.width * progress)
                        .overlay(
                            Rectangle()
                                .stroke(Color.brutalBlack, lineWidth: 3)
                        )
                }
            }
            .frame(height: 24)
            .background(
                Rectangle()
                    .fill(Color.brutalBlack)
                    .offset(x: 4, y: 4)
            )

            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1)
                .foregroundStyle(Color.brutalBlack)
        }
    }
}
