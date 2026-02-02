import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Topic.lastPracticed, order: .reverse) private var allTopics: [Topic]
    @Query private var records: [QuestionRecord]
    @Query private var subtopicProgress: [SubtopicProgress]

    let category: TopicCategory

    @State private var topicToDelete: Topic?
    @State private var showDeleteConfirmation = false
    @State private var viewModel = HomeViewModel()
    @State private var selectedTopic: Topic?

    private var topics: [Topic] {
        allTopics.filter { $0.category == category.rawValue }
    }

    var body: some View {
        ZStack {
            Color.brutalBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.title)
                            .foregroundColor(category.color)

                        Text(category.rawValue)
                            .font(.system(size: 28, weight: .semibold, design: .default))
                            .foregroundColor(.brutalBlack)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Topic list
                    if topics.isEmpty {
                        VStack(spacing: 8) {
                            Text("No topics yet")
                                .font(.system(.caption, design: .default, weight: .medium))
                                .foregroundColor(.flatTertiaryText)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(topics) { topic in
                            topicCard(topic)
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        topicToDelete = topic
                                        showDeleteConfirmation = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption2.bold())
                                            .foregroundColor(.flatTertiaryText)
                                            .padding(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTopic = topic
                                }
                                .padding(.horizontal, 24)
                        }
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedTopic) { topic in
            LearningPathView(topic: topic)
        }
        .brutalAlert(
            isPresented: $showDeleteConfirmation,
            title: "Delete Topic?",
            message: "This will delete all questions, progress, and review items for this topic.",
            primaryButton: BrutalAlertButton(title: "Delete", isDestructive: true) {
                if let topic = topicToDelete {
                    deleteTopic(topic)
                    topicToDelete = nil
                }
            },
            secondaryButton: BrutalAlertButton(title: "Cancel") {
                topicToDelete = nil
            }
        )
    }

    private func deleteTopic(_ topic: Topic) {
        let topicID = topic.id

        let recordDescriptor = FetchDescriptor<QuestionRecord>(
            predicate: #Predicate { $0.topicID == topicID }
        )
        let reviewDescriptor = FetchDescriptor<ReviewItem>(
            predicate: #Predicate { $0.topicID == topicID }
        )
        let progressDescriptor = FetchDescriptor<SubtopicProgress>(
            predicate: #Predicate { $0.topicID == topicID }
        )

        if let records = try? modelContext.fetch(recordDescriptor) {
            for record in records { modelContext.delete(record) }
        }
        if let reviews = try? modelContext.fetch(reviewDescriptor) {
            for review in reviews { modelContext.delete(review) }
        }
        if let progress = try? modelContext.fetch(progressDescriptor) {
            for p in progress { modelContext.delete(p) }
        }

        modelContext.delete(topic)
        try? modelContext.save()
    }

    @ViewBuilder
    private func topicCard(_ topic: Topic) -> some View {
        let count = viewModel.topicQuestionCount(records: records, topicID: topic.id)
        let mastered = viewModel.masteredCount(progressItems: subtopicProgress, topicID: topic.id)
        let total = viewModel.totalSubtopicCount(progressItems: subtopicProgress, topicID: topic.id)

        BrutalCard(borderColor: category.color) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(topic.name)
                        .font(.system(.body, design: .default, weight: .medium))
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

                    if total > 0 {
                        Text("\(mastered)/\(total) mastered")
                            .font(.system(.caption2, design: .default, weight: .medium))
                            .foregroundColor(mastered == total ? .brutalTeal : .flatSecondaryText)
                    }
                }

                Spacer()

                CompletionRing(completed: mastered, total: total, size: 50, lineWidth: 5)
            }
        }
    }
}
