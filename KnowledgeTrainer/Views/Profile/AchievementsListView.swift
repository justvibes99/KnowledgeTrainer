import SwiftUI
import SwiftData

struct AchievementsListView: View {
    @Query private var unlockedAchievements: [Achievement]

    private var unlockedIDs: Set<String> {
        Set(unlockedAchievements.map { $0.id })
    }

    private var grouped: [(AchievementDefinition.AchievementCategory, [AchievementDefinition])] {
        AchievementDefinition.AchievementCategory.allCases.map { category in
            (category, AchievementDefinition.all.filter { $0.category == category })
        }
    }

    var body: some View {
        ZStack {
            Color.brutalBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Text("ACHIEVEMENTS")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .tracking(2)
                            .foregroundColor(.brutalBlack)

                        Spacer()

                        Text("\(unlockedAchievements.count)/\(AchievementDefinition.all.count)")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .foregroundColor(.brutalBlack)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    ForEach(grouped, id: \.0) { category, definitions in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.rawValue.uppercased())
                                .font(.system(.caption, design: .default, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(.brutalBlack)
                                .padding(.horizontal, 24)

                            ForEach(definitions) { definition in
                                let isUnlocked = unlockedIDs.contains(definition.id)
                                let unlockDate = unlockedAchievements.first { $0.id == definition.id }?.unlockedDate

                                achievementRow(
                                    definition: definition,
                                    isUnlocked: isUnlocked,
                                    unlockDate: unlockDate
                                )
                                .padding(.horizontal, 24)
                            }
                        }
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func achievementRow(definition: AchievementDefinition, isUnlocked: Bool, unlockDate: Date?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: definition.iconName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(isUnlocked ? .brutalBlack : .brutalBlack.opacity(0.25))
                .frame(width: 48, height: 48)
                .background(isUnlocked ? Color.brutalYellow : Color.brutalBlack.opacity(0.08))
                .overlay(
                    Rectangle()
                        .stroke(isUnlocked ? Color.brutalBlack : Color.brutalBlack.opacity(0.2), lineWidth: 3)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(definition.name.uppercased())
                    .font(.system(.subheadline, design: .default, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(isUnlocked ? .brutalBlack : .brutalBlack.opacity(0.35))

                Text(definition.description)
                    .font(.system(.caption, design: .default))
                    .foregroundColor(isUnlocked ? .brutalBlack.opacity(0.7) : .brutalBlack.opacity(0.25))

                if isUnlocked, let date = unlockDate {
                    Text("Unlocked \(date.shortDisplay)")
                        .font(.system(.caption2, design: .default, weight: .bold))
                        .foregroundColor(.brutalTeal)
                }
            }

            Spacer()

            Text("+\(definition.xpReward) XP")
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundColor(isUnlocked ? .brutalTeal : .brutalBlack.opacity(0.2))
        }
        .padding(14)
        .background(isUnlocked ? Color.white : Color.brutalBackground)
        .overlay(
            Rectangle()
                .stroke(isUnlocked ? Color.brutalBlack : Color.brutalBlack.opacity(0.15), lineWidth: isUnlocked ? 3 : 2)
        )
        .background(
            isUnlocked ?
                AnyView(Rectangle().fill(Color.brutalBlack).offset(x: 4, y: 4)) :
                AnyView(EmptyView())
        )
    }
}
