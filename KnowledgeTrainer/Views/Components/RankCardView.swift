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
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.brutalBlack)
                    .frame(width: 56, height: 56)
                    .background(rank.color)
                    .overlay(
                        Rectangle()
                            .stroke(Color.brutalBlack, lineWidth: 3)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(rank.title.uppercased())
                        .font(.title2)
                        .fontWeight(.black)
                        .tracking(2)
                        .foregroundStyle(Color.brutalBlack)

                    Text("RANK \(rank.rawValue)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(1.5)
                        .foregroundStyle(Color.brutalBlack.opacity(0.6))
                }

                Spacer()

                if showShareButton {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.brutalBlack)
                            .frame(width: 44, height: 44)
                            .background(Color.brutalYellow)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.brutalBlack, lineWidth: 3)
                            )
                            .background(
                                Rectangle()
                                    .fill(Color.brutalBlack)
                                    .offset(x: 3, y: 3)
                            )
                    }
                }
            }

            XPProgressBar(currentXP: profile.totalXP, rank: rank)

            HStack(spacing: 0) {
                statItem(value: "\(profile.totalXP)", label: "TOTAL XP")
                Divider()
                    .frame(width: 3, height: 32)
                    .background(Color.brutalBlack)
                statItem(value: "\(streak)", label: "STREAK")
                Divider()
                    .frame(width: 3, height: 32)
                    .background(Color.brutalBlack)
                statItem(value: "\(topicsMastered)", label: "TOPICS")
            }
        }
        .padding(24)
        .brutalCard(backgroundColor: .white)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.black)
                .monospacedDigit()
                .foregroundStyle(Color.brutalBlack)
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .tracking(1.2)
                .foregroundStyle(Color.brutalBlack.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private var shareText: String {
        "I'm a \(rank.title) on SnapStudy! \(profile.totalXP) XP · \(streak) day streak · \(topicsMastered) topics mastered"
    }
}
