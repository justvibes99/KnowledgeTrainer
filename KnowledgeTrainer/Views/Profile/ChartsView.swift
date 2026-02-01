import SwiftUI
import SwiftData
import Charts

struct ChartsView: View {
    @Query private var records: [QuestionRecord]
    @Query private var topics: [Topic]

    var body: some View {
        ZStack {
            Color.brutalBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("CHARTS")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .tracking(1.5)
                        .foregroundColor(.brutalBlack)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // Accuracy Over Time
                    chartSection(title: "ACCURACY OVER TIME") {
                        let data = StatsCalculator.accuracyOverTime(records: records)
                        if data.isEmpty {
                            emptyState
                        } else {
                            Chart {
                                ForEach(data, id: \.0) { entry in
                                    LineMark(
                                        x: .value("Date", entry.0),
                                        y: .value("Accuracy", entry.1)
                                    )
                                    .foregroundStyle(Color.brutalTeal)
                                    .lineStyle(StrokeStyle(lineWidth: 3))

                                    PointMark(
                                        x: .value("Date", entry.0),
                                        y: .value("Accuracy", entry.1)
                                    )
                                    .foregroundStyle(Color.brutalBlack)
                                }
                            }
                            .chartYScale(domain: 0...100)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 200)
                        }
                    }

                    // Topic Strength by Category
                    chartSection(title: "TOPIC STRENGTH") {
                        let categoryData = categoryStrengthData()

                        if categoryData.isEmpty {
                            emptyState
                        } else {
                            Chart {
                                ForEach(categoryData, id: \.category) { entry in
                                    BarMark(
                                        x: .value("Accuracy", entry.accuracy),
                                        y: .value("Category", entry.category)
                                    )
                                    .foregroundStyle(barColor(for: entry.accuracy))
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
                            .frame(height: CGFloat(categoryData.count * 44 + 20))
                        }
                    }

                    // Daily Activity
                    chartSection(title: "DAILY ACTIVITY") {
                        let activityData = StatsCalculator.dailyActivity(records: records)
                        let hasActivity = activityData.contains { $0.1 > 0 }

                        if !hasActivity {
                            emptyState
                        } else {
                            Chart {
                                ForEach(activityData, id: \.0) { entry in
                                    BarMark(
                                        x: .value("Date", entry.0),
                                        y: .value("Questions", entry.1)
                                    )
                                    .foregroundStyle(Color.brutalYellow)
                                }
                            }
                            .frame(height: 200)
                        }
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func chartSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.caption, design: .default, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.brutalBlack)

            content()
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
        .padding(.horizontal, 24)
    }

    private var emptyState: some View {
        Text("Not enough data yet")
            .font(.system(.caption, design: .default))
            .foregroundColor(.brutalBlack.opacity(0.6))
            .frame(maxWidth: .infinity, minHeight: 100)
    }

    private struct CategoryStrength: Identifiable {
        let category: String
        let accuracy: Double
        var id: String { category }
    }

    private func categoryStrengthData() -> [CategoryStrength] {
        // Group topics by category
        var categoryTopics: [String: [Topic]] = [:]
        for topic in topics {
            let cat = topic.category.isEmpty ? "Other" : topic.category
            categoryTopics[cat, default: []].append(topic)
        }

        // Calculate average accuracy per category
        return categoryTopics.compactMap { category, catTopics in
            let accuracies = catTopics.map { topic in
                StatsCalculator.topicAccuracy(records: records, topicID: topic.id)
            }
            let avg = accuracies.reduce(0, +) / Double(accuracies.count)
            return CategoryStrength(category: category, accuracy: avg)
        }
        .filter { $0.accuracy > 0 }
        .sorted { $0.accuracy > $1.accuracy }
    }

    private func barColor(for accuracy: Double) -> Color {
        if accuracy < 40 { return .brutalCoral }
        if accuracy < 70 { return .brutalYellow }
        return .brutalTeal
    }
}
