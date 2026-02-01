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
                        Text("STATS")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .tracking(1.5)
                            .foregroundColor(.brutalBlack)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Dashboard Cards
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                dashboardCard(
                                    label: "QUESTIONS",
                                    value: "\(StatsCalculator.totalQuestionsAnswered(records: records))",
                                    color: .brutalTeal
                                )
                                dashboardCard(
                                    label: "ACCURACY",
                                    value: "\(Int(StatsCalculator.overallAccuracy(records: records)))%",
                                    color: .brutalYellow
                                )
                            }

                            HStack(spacing: 12) {
                                dashboardCard(
                                    label: "STREAK",
                                    value: "\(StatsCalculator.currentStreak(dailyStreaks: dailyStreaks))d",
                                    color: .brutalMint
                                )
                                dashboardCard(
                                    label: "TOTAL DAYS",
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
                            navRow(title: "TOPIC MAP")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)

                        // Charts
                        NavigationLink {
                            ChartsView()
                        } label: {
                            navRow(title: "CHARTS")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)

                        // Saved Deep Dives
                        if !deepDives.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SAVED DEEP DIVES")
                                    .font(.system(.caption, design: .default, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundColor(.brutalBlack)

                                ForEach(deepDives) { deepDive in
                                    Button(action: { selectedDeepDive = deepDive }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(deepDive.topic.uppercased())
                                                    .font(.system(.caption, design: .default, weight: .bold))
                                                    .tracking(0.8)
                                                    .foregroundColor(.brutalBlack)
                                                    .lineLimit(1)
                                                Text(deepDive.dateCreated.relativeDisplay)
                                                    .font(.system(.caption2, design: .default))
                                                    .foregroundColor(.brutalBlack.opacity(0.6))
                                            }
                                            Spacer()
                                            Image(systemName: "arrow.right")
                                                .font(.caption)
                                                .foregroundColor(.brutalBlack)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .overlay(
                                            Rectangle()
                                                .stroke(Color.brutalBlack, lineWidth: 2)
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
                    Button(action: { dismiss() }) {
                        Text("DONE")
                            .font(.system(.body, design: .default, weight: .bold))
                            .foregroundColor(.brutalBlack)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(item: $selectedDeepDive) { deepDive in
                NavigationStack {
                    ScrollView {
                        DeepDiveView(deepDive: deepDive, onTopicTap: { _ in })
                            .padding(24)
                    }
                    .background(Color.brutalBackground)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { selectedDeepDive = nil }) {
                                Text("DONE")
                                    .font(.system(.body, design: .default, weight: .bold))
                                    .foregroundColor(.brutalBlack)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
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

    @ViewBuilder
    private func navRow(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .default, weight: .bold))
                .tracking(1.2)
                .foregroundColor(.brutalBlack)
            Spacer()
            Image(systemName: "arrow.right")
                .foregroundColor(.brutalBlack)
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
    }
}
