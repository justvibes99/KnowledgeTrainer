import SwiftUI
import SwiftData

struct TopicDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var records: [QuestionRecord]

    let topic: Topic
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            Color.brutalBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text(topic.name)
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .foregroundColor(.brutalBlack)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // Overall Stats
                    let topicRecords = records.filter { $0.topicID == topic.id }
                    let accuracy = StatsCalculator.topicAccuracy(records: records, topicID: topic.id)
                    let maxDiff = StatsCalculator.maxDifficultyReached(records: records, topicID: topic.id)

                    HStack(spacing: 12) {
                        statBox(label: "Questions", value: "\(topicRecords.count)", color: .brutalTeal)
                        statBox(label: "Accuracy", value: "\(Int(accuracy))%", color: .brutalYellow)
                        statBox(label: "Max Diff", value: "\(maxDiff)", color: .brutalLavender)
                    }
                    .padding(.horizontal, 24)

                    Text("Last practiced: \(topic.lastPracticed.relativeDisplay)")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.flatSecondaryText)
                        .padding(.horizontal, 24)

                    // Subtopic Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subtopics")
                            .font(.system(.caption, design: .default, weight: .medium))
                            .foregroundColor(.brutalBlack)
                            .padding(.horizontal, 24)

                        ForEach(topic.subtopics, id: \.self) { subtopic in
                            let subAccuracy = StatsCalculator.subtopicAccuracy(
                                records: records,
                                topicID: topic.id,
                                subtopic: subtopic
                            )
                            let subCount = records.filter { $0.topicID == topic.id && $0.subtopic == subtopic }.count

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(subtopic)
                                        .font(.system(.caption, design: .default, weight: .medium))
                                        .foregroundColor(.brutalBlack)
                                    Text("\(subCount) questions")
                                        .font(.system(.caption2, design: .default))
                                        .foregroundColor(.flatSecondaryText)
                                }
                                Spacer()
                                AccuracyRing(accuracy: subAccuracy, size: 40, lineWidth: 4)
                            }
                            .padding(16)
                            .background(Color.flatSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.brutalBlack, lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                        }
                    }

                    // Delete
                    Button(action: { showDeleteConfirmation = true }) {
                        Text("Delete Topic")
                            .font(.system(.caption, design: .default, weight: .medium))
                            .foregroundColor(.brutalCoral)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Topic?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                let vm = ProfileViewModel()
                vm.deleteTopic(topic, modelContext: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all data for \"\(topic.name)\" including question history and review items.")
        }
    }

    @ViewBuilder
    private func statBox(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .foregroundColor(.brutalBlack)
            Text(label)
                .font(.system(.caption2, design: .default, weight: .medium))
                .foregroundColor(.brutalBlack)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.brutalBlack, lineWidth: 1)
        )
    }
}
