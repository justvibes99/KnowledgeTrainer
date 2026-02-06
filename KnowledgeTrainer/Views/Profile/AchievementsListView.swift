import SwiftUI
import SwiftData

struct AchievementsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var unlockedAchievements: [Achievement]
    @State private var progress: [String: (current: Int, target: Int)] = [:]

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
                            .font(.system(size: 28, weight: .semibold, design: .monospaced))
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
                            HStack {
                                Text(category.rawValue)
                                    .font(.system(.caption, design: .monospaced, weight: .medium))
                                    .foregroundColor(.brutalBlack)

                                Spacer()

                                let unlockedInCategory = definitions.filter { unlockedIDs.contains($0.id) }.count
                                Text("\(unlockedInCategory)/\(definitions.count)")
                                    .font(.system(.caption, design: .monospaced, weight: .medium))
                                    .foregroundColor(.flatSecondaryText)
                            }
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
        .onAppear {
            let service = GamificationService(context: modelContext)
            progress = service.achievementProgress()
        }
    }

    private func tierIconColor(_ tier: AchievementDefinition.AchievementTier) -> Color {
        switch tier {
        case .standard: return .brutalYellow
        case .notable: return .brutalTeal
        case .epic: return .brutalCoral
        }
    }

    @ViewBuilder
    private func achievementRow(definition: AchievementDefinition, isUnlocked: Bool, unlockDate: Date?) -> some View {
        let isEpic = isUnlocked && definition.tier == .epic

        HStack(spacing: 14) {
            Image(systemName: definition.iconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isUnlocked ? .brutalBlack : .flatTertiaryText)
                .frame(width: 48, height: 48)
                .background(isUnlocked ? tierIconColor(definition.tier) : Color.flatSurfaceSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isUnlocked ? Color.brutalBlack : Color.flatSurfaceSubtle, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(definition.name)
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundColor(isUnlocked ? .brutalBlack : .flatTertiaryText)

                Text(definition.description)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(isUnlocked ? .flatSecondaryText : .flatTertiaryText)

                if isUnlocked, let date = unlockDate {
                    Text("Unlocked \(date.shortDisplay)")
                        .font(.system(.caption2, design: .monospaced, weight: .medium))
                        .foregroundColor(.brutalTeal)
                } else if let prog = progress[definition.id], prog.target > 0 && prog.current > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.flatSurfaceSubtle)
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.brutalTeal)
                                .frame(width: geo.size.width * CGFloat(prog.current) / CGFloat(prog.target), height: 4)
                        }
                    }
                    .frame(height: 4)
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
                .stroke(isUnlocked ? Color.brutalBlack : Color.flatSurfaceSubtle, lineWidth: isEpic ? 2 : 1)
        )
        .shadow(color: isUnlocked ? .black.opacity(0.06) : .clear, radius: 4, x: 0, y: 2)
    }
}
