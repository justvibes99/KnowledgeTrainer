import SwiftUI

struct RankCardView: View {
    let profile: ScholarProfile
    let topicsMastered: Int
    let streak: Int
    var showShareButton: Bool = true

    private var rank: ScholarRank { profile.rank }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: rank.iconName)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Color.brutalOnAccent)
                    .frame(width: 56, height: 56)
                    .background(rank.color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(rank.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brutalBlack)

                    Text("Rank \(rank.rawValue)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.flatSecondaryText)
                }

                Spacer()

                if showShareButton {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.brutalBlack)
                            .frame(width: 44, height: 44)
                            .background(Color.flatSurfaceSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.flatBorder, lineWidth: 1)
                            )
                    }
                }
            }

            XPProgressBar(currentXP: profile.totalXP, rank: rank)

            HStack(spacing: 0) {
                statItem(value: "\(profile.totalXP)", label: "Total XP")
                Divider()
                    .frame(width: 1, height: 32)
                    .background(Color.flatBorder)
                statItem(value: "\(streak)", label: "Streak")
                Divider()
                    .frame(width: 1, height: 32)
                    .background(Color.flatBorder)
                statItem(value: "\(topicsMastered)", label: "Topics")
            }
        }
        .padding(24)
        .brutalCard(backgroundColor: .flatSurface)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Color.brutalBlack)
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color.flatSecondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var shareText: String {
        "I'm a \(rank.title) on SnapStudy! \(profile.totalXP) XP · \(streak) day streak · \(topicsMastered) topics mastered"
    }
}
