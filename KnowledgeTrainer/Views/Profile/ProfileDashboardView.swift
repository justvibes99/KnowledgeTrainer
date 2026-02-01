import SwiftUI
import SwiftData
import Charts

struct ProfileDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var topics: [Topic]
    @Query private var records: [QuestionRecord]
    @Query private var reviewItems: [ReviewItem]
    @Query private var dailyStreaks: [DailyStreak]
    @Query private var scholarProfiles: [ScholarProfile]
    @Query private var achievements: [Achievement]
    @Query private var subtopicProgress: [SubtopicProgress]

    @State private var viewModel = ProfileViewModel()
    @State private var showSettings = false
    @State private var showFreezePurchaseConfirm = false

    private var profile: ScholarProfile? { scholarProfiles.first }

    private var fullyMasteredTopicCount: Int {
        topics.filter { topic in
            guard !topic.subtopics.isEmpty else { return false }
            return topic.subtopics.allSatisfy { sub in
                subtopicProgress.contains { $0.topicID == topic.id && $0.subtopicName == sub && $0.isMastered }
            }
        }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brutalBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text("PROFILE")
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .tracking(2)
                            .foregroundColor(.brutalBlack)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Rank Card
                        if let profile {
                            RankCardView(
                                profile: profile,
                                topicsMastered: fullyMasteredTopicCount,
                                streak: viewModel.currentStreak(streaks: dailyStreaks)
                            )
                            .padding(.horizontal, 24)
                        }

                        // Dashboard Stats
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                dashboardCard(
                                    label: "QUESTIONS",
                                    value: "\(viewModel.totalQuestions(records: records))",
                                    color: .brutalTeal
                                )
                                dashboardCard(
                                    label: "ACCURACY",
                                    value: "\(Int(viewModel.overallAccuracy(records: records)))%",
                                    color: .brutalYellow
                                )
                            }

                            HStack(spacing: 12) {
                                dashboardCard(
                                    label: "STREAK",
                                    value: "\(viewModel.currentStreak(streaks: dailyStreaks))d",
                                    color: .brutalMint
                                )
                                dashboardCard(
                                    label: "TOPICS",
                                    value: "\(topics.count)",
                                    color: .brutalLavender
                                )
                            }

                            let dueCount = viewModel.dueReviewCount(items: reviewItems)
                            if dueCount > 0 {
                                HStack {
                                    Text("REVIEW DUE: \(dueCount) items")
                                        .font(.system(.caption, design: .default, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(.brutalBlack)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.brutalCoral.opacity(0.2))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.brutalCoral, lineWidth: 2)
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        // Category Strength
                        categoryStrengthSection
                            .padding(.horizontal, 24)

                        // Streak Calendar
                        StreakCalendarView(dailyStreaks: dailyStreaks)
                            .padding(.horizontal, 24)

                        // Achievements
                        NavigationLink {
                            AchievementsListView()
                        } label: {
                            HStack {
                                Text("ACHIEVEMENTS")
                                    .font(.system(.body, design: .default, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundColor(.brutalBlack)
                                Spacer()
                                Text("\(achievements.count)/\(AchievementDefinition.all.count) UNLOCKED")
                                    .font(.system(.caption, design: .default, weight: .bold))
                                    .tracking(0.8)
                                    .foregroundColor(.brutalBlack.opacity(0.6))
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.brutalBlack)
                            }
                            .padding(16)
                            .background(Color.brutalYellow)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.brutalBlack, lineWidth: 3)
                            )
                            .background(
                                Rectangle()
                                    .fill(Color.brutalBlack)
                                    .offset(x: 4, y: 4)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)

                        // Streak Freezes
                        if let profile {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "snowflake")
                                        .font(.title3)
                                        .foregroundColor(.brutalBlack)
                                    Text("STREAK FREEZES")
                                        .font(.system(.body, design: .default, weight: .bold))
                                        .tracking(1.2)
                                        .foregroundColor(.brutalBlack)
                                    Spacer()
                                    Text("\(profile.streakFreezes)/3")
                                        .font(.system(.title3, design: .monospaced, weight: .bold))
                                        .foregroundColor(.brutalBlack)
                                }

                                if profile.canPurchaseStreakFreeze() {
                                    Button {
                                        showFreezePurchaseConfirm = true
                                    } label: {
                                        Text("BUY FREEZE — 200 XP")
                                            .font(.system(.caption, design: .default, weight: .black))
                                            .tracking(1.5)
                                            .foregroundColor(.brutalBlack)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.brutalMint)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.brutalBlack, lineWidth: 3)
                                            )
                                            .background(
                                                Rectangle()
                                                    .fill(Color.brutalBlack)
                                                    .offset(x: 4, y: 4)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                } else if profile.streakFreezes >= 3 {
                                    Text("MAX FREEZES HELD")
                                        .font(.system(.caption, design: .default, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(.brutalBlack.opacity(0.5))
                                } else {
                                    Text("NEED 200 XP TO PURCHASE")
                                        .font(.system(.caption, design: .default, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(.brutalBlack.opacity(0.5))
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.brutalBlack, lineWidth: 3)
                            )
                            .background(
                                Rectangle()
                                    .fill(Color.brutalBlack)
                                    .offset(x: 4, y: 4)
                            )
                            .padding(.horizontal, 24)
                        }

                        Spacer().frame(height: 100)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.brutalBlack)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            .alert("Buy Streak Freeze?", isPresented: $showFreezePurchaseConfirm) {
                Button("Buy for 200 XP") {
                    if let profile {
                        _ = profile.purchaseStreakFreeze()
                        HapticManager.success()
                        try? modelContext.save()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Spend 200 XP to buy a streak freeze. It will automatically be used if you miss a day.")
            }
        }
    }

    @ViewBuilder
    private var categoryStrengthSection: some View {
        let data = categoryStrengthData()

        if !data.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("TOPIC STRENGTH")
                    .font(.system(.caption, design: .default, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.brutalBlack)

                Chart {
                    ForEach(data, id: \.category) { entry in
                        BarMark(
                            x: .value("Accuracy", entry.accuracy),
                            y: .value("Category", entry.category)
                        )
                        .foregroundStyle(strengthBarColor(for: entry.accuracy))
                        .annotation(position: .trailing, spacing: 4) {
                            Text("\(Int(entry.accuracy))%")
                                .font(.system(.caption2, design: .monospaced, weight: .bold))
                                .foregroundColor(.brutalBlack)
                        }
                    }
                }
                .chartXScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100])
                }
                .frame(height: CGFloat(data.count * 44 + 20))
                .padding(16)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.brutalBlack, lineWidth: 3)
                )
                .background(
                    Rectangle()
                        .fill(Color.brutalBlack)
                        .offset(x: 4, y: 4)
                )
            }
        }
    }

    private func categoryStrengthData() -> [(category: String, accuracy: Double)] {
        var categoryTopics: [String: [Topic]] = [:]
        for topic in topics {
            let cat = topic.category.isEmpty ? "Other" : topic.category
            categoryTopics[cat, default: []].append(topic)
        }

        return categoryTopics.compactMap { category, catTopics in
            let accuracies = catTopics.map { topic in
                StatsCalculator.topicAccuracy(records: records, topicID: topic.id)
            }
            let avg = accuracies.reduce(0, +) / Double(accuracies.count)
            return (category: category, accuracy: avg)
        }
        .filter { $0.accuracy > 0 }
        .sorted { $0.accuracy > $1.accuracy }
    }

    private func strengthBarColor(for accuracy: Double) -> Color {
        if accuracy < 40 { return .brutalCoral }
        if accuracy < 70 { return .brutalYellow }
        return .brutalTeal
    }

    @ViewBuilder
    private func dashboardCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.brutalBlack)
            Text(label)
                .font(.system(.caption2, design: .default, weight: .bold))
                .tracking(1)
                .foregroundColor(.brutalBlack)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color)
        .overlay(
            Rectangle()
                .stroke(Color.brutalBlack, lineWidth: 3)
        )
        .background(
            Rectangle()
                .fill(Color.brutalBlack)
                .offset(x: 4, y: 4)
        )
    }
}
