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
                        Text("Train")
                            .font(.system(size: 36, weight: .semibold, design: .monospaced))
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
                                    Text("Generating...")
                                        .font(.system(.caption, design: .monospaced, weight: .medium))
                                        .foregroundColor(.brutalBlack)
                                }
                                .padding(.vertical, 8)
                            } else {
                                BrutalButton(title: "Start", gradient: LinearGradient(colors: [.brutalYellow, .brutalTeal], startPoint: .leading, endPoint: .trailing), fullWidth: true) {
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
                                            Text("Review Due")
                                                .font(.system(.caption, design: .monospaced, weight: .medium))
                                                .foregroundColor(.brutalBlack)
                                            Text("\(dueCount) items to review")
                                                .font(.system(.body, design: .monospaced))
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
                                Text("Your Topics")
                                    .font(.system(.caption, design: .monospaced, weight: .medium))
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
                    Text(topic.name)
                        .font(.system(.body, design: .monospaced, weight: .medium))
                        .foregroundColor(.brutalBlack)
                        .lineLimit(1)

                    HStack(spacing: 16) {
                        Label("\(count) Qs", systemImage: "questionmark.circle")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.brutalBlack)

                        Text(topic.lastPracticed.relativeDisplay)
                            .font(.system(.caption2, design: .monospaced))
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
                                        .fill(Color.flatSurfaceSubtle)
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
