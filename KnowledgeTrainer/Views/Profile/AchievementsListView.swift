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
                        Text("Achievements")
                            .font(.system(size: 28, weight: .semibold, design: .default))
                            .foregroundColor(.brutalBlack)

                        Spacer()

                        Text("\(unlockedAchievements.count)/\(AchievementDefinition.all.count)")
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .foregroundColor(.brutalBlack)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    ForEach(grouped, id: \.0) { category, definitions in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.rawValue)
                                .font(.system(.caption, design: .default, weight: .medium))
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
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isUnlocked ? .brutalBlack : .flatTertiaryText)
                .frame(width: 48, height: 48)
                .background(isUnlocked ? Color.brutalYellow : Color.flatSurfaceSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isUnlocked ? Color.brutalBlack : Color.flatSurfaceSubtle, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(definition.name)
                    .font(.system(.subheadline, design: .default, weight: .semibold))
                    .foregroundColor(isUnlocked ? .brutalBlack : .flatTertiaryText)

                Text(definition.description)
                    .font(.system(.caption, design: .default))
                    .foregroundColor(isUnlocked ? .flatSecondaryText : .flatTertiaryText)

                if isUnlocked, let date = unlockDate {
                    Text("Unlocked \(date.shortDisplay)")
                        .font(.system(.caption2, design: .default, weight: .medium))
                        .foregroundColor(.brutalTeal)
                }
            }

            Spacer()

            Text("+\(definition.xpReward) XP")
                .font(.system(.caption, design: .monospaced, weight: .semibold))
                .foregroundColor(isUnlocked ? .brutalTeal : .flatSurfaceSubtle)
        }
        .padding(14)
        .background(isUnlocked ? Color.flatSurface : Color.brutalBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isUnlocked ? Color.brutalBlack : Color.flatSurfaceSubtle, lineWidth: 1)
        )
        .background(
            isUnlocked ?
                AnyView(EmptyView()) :
                AnyView(EmptyView())
        )
        .shadow(color: isUnlocked ? .black.opacity(0.06) : .clear, radius: 4, x: 0, y: 2)
    }
}
