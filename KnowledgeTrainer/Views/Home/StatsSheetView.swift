import SwiftUI
import SwiftData

struct StatsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var records: [QuestionRecord]
    @Query private var dailyStreaks: [DailyStreak]
    @Query(sort: \DeepDive.dateCreated, order: .reverse) private var deepDives: [DeepDive]

    @State private var selectedDeepDive: DeepDive?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brutalBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text("Stats")
                            .font(.system(size: 28, weight: .semibold, design: .default))
                            .foregroundColor(.brutalBlack)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Dashboard Cards
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                dashboardCard(
                                    label: "Questions",
                                    value: "\(StatsCalculator.totalQuestionsAnswered(records: records))",
                                    color: .brutalTeal
                                )
                                dashboardCard(
                                    label: "Accuracy",
                                    value: "\(Int(StatsCalculator.overallAccuracy(records: records)))%",
                                    color: .brutalYellow
                                )
                            }

                            HStack(spacing: 12) {
                                dashboardCard(
                                    label: "Streak",
                                    value: "\(StatsCalculator.currentStreak(dailyStreaks: dailyStreaks))d",
                                    color: .brutalMint
                                )
                                dashboardCard(
                                    label: "Total Days",
                                    value: "\(dailyStreaks.filter { $0.questionsCompleted > 0 }.count)",
                                    color: .brutalLavender
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        // Streak Calendar
                        StreakCalendarView(dailyStreaks: dailyStreaks)
                            .padding(.horizontal, 24)

                        // Topic Map
                        NavigationLink {
                            TopicMapView()
                        } label: {
                            navRow(title: "Topic Map")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)

                        // Charts
                        NavigationLink {
                            ChartsView()
                        } label: {
                            navRow(title: "Charts")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)

                        // Saved Deep Dives
                        if !deepDives.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Saved Deep Dives")
                                    .font(.system(.caption, design: .default, weight: .medium))
                                    .foregroundColor(.brutalBlack)

                                ForEach(deepDives) { deepDive in
                                    Button(action: { selectedDeepDive = deepDive }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(deepDive.topic)
                                                    .font(.system(.caption, design: .default, weight: .medium))
                                                    .foregroundColor(.brutalBlack)
                                                    .lineLimit(1)
                                                Text(deepDive.dateCreated.relativeDisplay)
                                                    .font(.system(.caption2, design: .default))
                                                    .foregroundColor(.flatSecondaryText)
                                            }
                                            Spacer()
                                            Image(systemName: "arrow.right")
                                                .font(.caption)
                                                .foregroundColor(.brutalBlack)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.flatSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.flatBorder, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }            }
            .sheet(item: $selectedDeepDive) { deepDive in
                NavigationStack {
                    ScrollView {
                        DeepDiveView(deepDive: deepDive, onTopicTap: { _ in })
                            .padding(24)
                    }
                    .background(Color.brutalBackground)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { selectedDeepDive = nil }
                        }                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dashboardCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .medium, design: .monospaced))
                .foregroundColor(.flatSecondaryText)
            Text(label)
                .font(.system(.caption2, design: .default, weight: .medium))
                .foregroundColor(.flatTertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(hex: "EAE7E1"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }

    @ViewBuilder
    private func navRow(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .default, weight: .medium))
                .foregroundColor(.brutalBlack)
            Spacer()
            Image(systemName: "arrow.right")
                .foregroundColor(.brutalBlack)
        }
        .padding(16)
        .background(Color.flatSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.flatBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
