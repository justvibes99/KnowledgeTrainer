import SwiftUI
import SwiftData

struct TrainHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Topic.lastPracticed, order: .reverse) private var topics: [Topic]
    @Query private var records: [QuestionRecord]
    @Query private var reviewItems: [ReviewItem]
    @Query private var subtopicProgress: [SubtopicProgress]

    @State private var viewModel = TrainViewModel()
    @State private var showSubtopicPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brutalBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        Text("TRAIN")
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .tracking(2)
                            .foregroundColor(.brutalBlack)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Input Section
                        VStack(spacing: 12) {
                            BrutalTextField(
                                placeholder: "What do you want to learn?",
                                text: $viewModel.topicInput,
                                onSubmit: { Task { await startTopic() } }
                            )

                            if viewModel.isLoading {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.brutalBlack)
                                    Text("GENERATING...")
                                        .font(.system(.caption, design: .default, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(.brutalBlack)
                                }
                                .padding(.vertical, 8)
                            } else {
                                BrutalButton(title: "Start", color: .brutalCoral, fullWidth: true) {
                                    Task { await startTopic() }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Review Due Card
                        let dueCount = viewModel.dueReviewCount(reviewItems: reviewItems)
                        if dueCount > 0 {
                            NavigationLink {
                                ReviewSessionView(reviewItems: reviewItems)
                            } label: {
                                BrutalCard(backgroundColor: .brutalLavender) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("REVIEW DUE")
                                                .font(.system(.caption, design: .default, weight: .bold))
                                                .tracking(1.2)
                                                .foregroundColor(.brutalBlack)
                                            Text("\(dueCount) items to review")
                                                .font(.system(.body, design: .default))
                                                .foregroundColor(.brutalBlack)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .font(.title2)
                                            .foregroundColor(.brutalBlack)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                        }

                        // Your Topics
                        if !topics.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("YOUR TOPICS")
                                    .font(.system(.caption, design: .default, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundColor(.brutalBlack)
                                    .padding(.horizontal, 24)

                                ForEach(topics) { topic in
                                    NavigationLink {
                                        LearningPathView(topic: topic)
                                    } label: {
                                        topicCard(topic)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 24)
                                }
                            }
                        }

                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.navigateToDrill) {
                if let topic = viewModel.currentTopic {
                    LearningPathView(
                        topic: topic,
                        initialQuestions: viewModel.initialQuestions,
                        initialLesson: viewModel.initialLesson
                    )
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    @ViewBuilder
    private func topicCard(_ topic: Topic) -> some View {
        let accuracy = viewModel.topicAccuracy(records: records, topicID: topic.id)
        let count = viewModel.topicQuestionCount(records: records, topicID: topic.id)
        let mastered = viewModel.masteredCount(progressItems: subtopicProgress, topicID: topic.id)
        let total = viewModel.totalSubtopicCount(progressItems: subtopicProgress, topicID: topic.id)

        BrutalCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(topic.name.uppercased())
                        .font(.system(.body, design: .default, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(.brutalBlack)
                        .lineLimit(1)

                    HStack(spacing: 16) {
                        Label("\(count) Qs", systemImage: "questionmark.circle")
                            .font(.system(.caption2, design: .default))
                            .foregroundColor(.brutalBlack)

                        Text(topic.lastPracticed.relativeDisplay)
                            .font(.system(.caption2, design: .default))
                            .foregroundColor(.brutalBlack)
                    }

                    // Progress bar
                    if total > 0 {
                        HStack(spacing: 8) {
                            Text("\(mastered)/\(total)")
                                .font(.system(.caption2, design: .monospaced, weight: .bold))
                                .foregroundColor(.brutalBlack)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.brutalBlack.opacity(0.1))
                                        .frame(height: 6)

                                    Rectangle()
                                        .fill(Color.brutalTeal)
                                        .frame(width: geo.size.width * CGFloat(mastered) / CGFloat(max(total, 1)), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }

                Spacer()

                AccuracyRing(accuracy: accuracy, size: 50, lineWidth: 5)
            }
        }
    }

    private func startTopic() async {
        await viewModel.startNewTopic(modelContext: modelContext)
    }
}
