import SwiftUI
import SwiftData

struct TopicMapView: View {
    @Query private var topics: [Topic]
    @Query private var records: [QuestionRecord]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color.brutalBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("TOPIC MAP")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .tracking(1.5)
                        .foregroundColor(.brutalBlack)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    if topics.isEmpty {
                        VStack(spacing: 12) {
                            Text("NO TOPICS YET")
                                .font(.system(.body, design: .default, weight: .bold))
                                .foregroundColor(.brutalBlack)
                            Text("Start training to see your topic map.")
                                .font(.system(.caption, design: .default))
                                .foregroundColor(.brutalBlack.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(topics) { topic in
                                NavigationLink {
                                    TopicDetailView(topic: topic)
                                } label: {
                                    topicMapCard(topic)
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
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func topicMapCard(_ topic: Topic) -> some View {
        let accuracy = StatsCalculator.topicAccuracy(records: records, topicID: topic.id)
        let cardColor = accuracyCardColor(accuracy)

        VStack(spacing: 8) {
            Text(topic.name.uppercased())
                .font(.system(.caption, design: .default, weight: .bold))
                .tracking(0.8)
                .foregroundColor(.brutalBlack)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            AccuracyRing(accuracy: accuracy, size: 50, lineWidth: 5)

            Text("\(StatsCalculator.questionsForTopic(records: records, topicID: topic.id)) Qs")
                .font(.system(.caption2, design: .default))
                .foregroundColor(.brutalBlack)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(cardColor)
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

    private func accuracyCardColor(_ accuracy: Double) -> Color {
        if accuracy < 40 { return .brutalCoral.opacity(0.3) }
        if accuracy < 70 { return .brutalYellow.opacity(0.3) }
        return .brutalTeal.opacity(0.3)
    }
}
