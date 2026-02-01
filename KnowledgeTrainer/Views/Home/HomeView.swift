import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Topic.lastPracticed, order: .reverse) private var topics: [Topic]
    @Query private var records: [QuestionRecord]
    @Query private var reviewItems: [ReviewItem]
    @Query private var subtopicProgress: [SubtopicProgress]
    @Query private var dailyStreaks: [DailyStreak]
    @Query(sort: \WantToLearnItem.dateAdded, order: .reverse) private var wantToLearn: [WantToLearnItem]

    @Query private var scholarProfiles: [ScholarProfile]

    @State private var viewModel = HomeViewModel()
    @State private var showSettings = false
    @State private var showStats = false
    @State private var topicToDelete: Topic?
    @State private var showDeleteConfirmation = false

    private var profile: ScholarProfile? { scholarProfiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brutalBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header row
                        HStack {
                            Text("SNAPSTUDY")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .tracking(2)
                                .foregroundColor(.brutalBlack)

                            if let profile {
                                NavigationLink {
                                    ProfileDashboardView()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: profile.rank.iconName)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.brutalBlack)
                                        Text(profile.rank.title.uppercased())
                                            .font(.system(.caption2, design: .default, weight: .black))
                                            .tracking(1)
                                            .foregroundColor(.brutalBlack)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(profile.rank.color)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.brutalBlack, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title3)
                                    .foregroundColor(.brutalBlack)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        // Stats Strip
                        let dueCount = viewModel.dueReviewCount(items: reviewItems)
                        Button(action: { showStats = true }) {
                            StatsStripView(
                                totalQuestions: viewModel.totalQuestions(records: records),
                                accuracy: viewModel.overallAccuracy(records: records),
                                streak: viewModel.currentStreak(streaks: dailyStreaks),
                                dueReviews: dueCount
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)

                        // Daily Goal Banner
                        if let profile {
                            let _ = profile.resetDailyGoalIfNeeded()
                            DailyGoalBanner(isCompleted: profile.isDailyGoalCurrent() && profile.dailyGoalCompleted)
                                .padding(.horizontal, 24)
                        }

                        // Review Due Banner
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

                        // Input Section
                        VStack(spacing: 12) {
                            BrutalTextField(
                                placeholder: "What do you want to learn?",
                                text: $viewModel.topicInput,
                                onSubmit: { Task { await viewModel.startNewTopic(modelContext: modelContext) } }
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
                                BrutalButton(title: "Start Learning", color: .brutalCoral, fullWidth: true) {
                                    Task { await viewModel.startNewTopic(modelContext: modelContext) }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Want to Learn Queue
                        WantToLearnSection(
                            items: wantToLearn,
                            onStart: { item in
                                Task { await viewModel.startFromQueue(item: item, modelContext: modelContext) }
                            },
                            onRemove: { item in
                                viewModel.removeFromQueue(item: item, modelContext: modelContext)
                            }
                        )
                        .padding(.horizontal, 24)

                        // Category Grid
                        if !topics.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("YOUR TOPICS")
                                    .font(.system(.caption, design: .default, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundColor(.brutalBlack)
                                    .padding(.horizontal, 24)

                                let columns = [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ]

                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(categoriesWithTopics, id: \.0) { category, categoryTopics in
                                        NavigationLink {
                                            CategoryDetailView(category: category)
                                        } label: {
                                            categoryTile(category: category, topics: categoryTopics)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.navigateToPath) {
                if let topic = viewModel.createdTopic {
                    LearningPathView(
                        topic: topic,
                        initialQuestions: viewModel.createdQuestions,
                        initialLesson: viewModel.createdLesson
                    )
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: ProfileViewModel())
            }
            .sheet(isPresented: $showStats) {
                StatsSheetView()
            }
            .brutalAlert(
                isPresented: $viewModel.showError,
                title: "Error",
                message: viewModel.errorMessage ?? "Unknown error",
                primaryButton: BrutalAlertButton(title: "OK") {}
            )
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

    private var categoriesWithTopics: [(TopicCategory, [Topic])] {
        var result: [(TopicCategory, [Topic])] = []
        for category in TopicCategory.allCases {
            let matching = topics.filter { $0.category == category.rawValue }
            if !matching.isEmpty {
                result.append((category, matching))
            }
        }
        return result
    }

    @ViewBuilder
    private func categoryTile(category: TopicCategory, topics categoryTopics: [Topic]) -> some View {
        let totalMastered = categoryTopics.reduce(0) { sum, topic in
            sum + viewModel.masteredCount(progressItems: subtopicProgress, topicID: topic.id)
        }
        let totalSubtopics = categoryTopics.reduce(0) { sum, topic in
            sum + viewModel.totalSubtopicCount(progressItems: subtopicProgress, topicID: topic.id)
        }

        BrutalCard(backgroundColor: category.color, shadowSize: 4) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(.brutalBlack)

                Text(category.rawValue.uppercased())
                    .font(.system(.caption, design: .default, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.brutalBlack)
                    .lineLimit(1)

                Text("\(categoryTopics.count) topic\(categoryTopics.count == 1 ? "" : "s")")
                    .font(.system(.caption2, design: .default))
                    .foregroundColor(.brutalBlack)

                if totalSubtopics > 0 {
                    Text("\(totalMastered)/\(totalSubtopics) MASTERED")
                        .font(.system(.caption2, design: .default, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(totalMastered == totalSubtopics ? .brutalTeal : .brutalBlack.opacity(0.6))
                }
            }
        }
    }
}
