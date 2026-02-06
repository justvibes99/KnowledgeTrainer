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

    @Binding var selectedTab: Int

    @State private var viewModel = HomeViewModel()
    @State private var showStats = false
    @State private var topicToDelete: Topic?
    @State private var showDeleteConfirmation = false
    @State private var quickContinueTopic: Topic?
    @State private var quickContinueSubtopic: String?
    @State private var navigateToQuickContinue = false

    private var profile: ScholarProfile? { scholarProfiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brutalBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header row
                        HStack {
                            Text("SnapStudy")
                                .font(.system(size: 32, weight: .semibold, design: .monospaced))
                                .foregroundColor(.brutalBlack)

                            Spacer()

                            if let profile {
                                Button {
                                    selectedTab = 1
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: profile.rank.iconName)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.brutalBlack)
                                        Text(profile.rank.title)
                                            .font(.system(.caption2, design: .monospaced, weight: .semibold))
                                            .foregroundColor(.brutalBlack)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.brutalTeal.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.brutalTeal, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        // Quick Continue Card
                        if let data = viewModel.quickContinueData(topics: topics, progressItems: subtopicProgress) {
                            Button {
                                quickContinueTopic = data.topic
                                quickContinueSubtopic = data.subtopic
                                navigateToQuickContinue = true
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(spacing: 4) {
                                        Text("\(data.masteredCount)/\(data.totalCount)")
                                            .font(.system(.body, design: .monospaced, weight: .semibold))
                                            .foregroundColor(.brutalBlack)
                                        Text("Mastered")
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundColor(.flatSecondaryText)
                                    }
                                    .frame(width: 56)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(data.topic.name)
                                            .font(.system(.caption, design: .monospaced, weight: .medium))
                                            .foregroundColor(.brutalBlack)
                                            .lineLimit(1)
                                        Text(data.subtopic)
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundColor(.flatSecondaryText)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text("Continue")
                                        .font(.system(.caption, design: .monospaced, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.brutalYellow)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
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
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                        }

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
                            let todayQuestionCount = records.filter { Calendar.current.isDateInToday($0.date) }.count
                            Button { showStats = true } label: {
                                DailyGoalBanner(
                                    isCompleted: profile.isDailyGoalCurrent() && profile.dailyGoalCompleted,
                                    questionsToday: todayQuestionCount
                                )
                            }
                            .buttonStyle(.plain)
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
                                    Text("Generating...")
                                        .font(.system(.caption, design: .monospaced, weight: .medium))
                                        .foregroundColor(.brutalBlack)
                                }
                                .padding(.vertical, 8)
                            } else {
                                BrutalButton(title: "Start Learning", gradient: LinearGradient(colors: [.brutalYellow, .brutalTeal], startPoint: .leading, endPoint: .trailing), fullWidth: true) {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                                Text("Your Topics")
                                    .font(.system(.caption, design: .monospaced, weight: .medium))
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
            .navigationDestination(isPresented: $navigateToQuickContinue) {
                if let topic = quickContinueTopic, let subtopic = quickContinueSubtopic {
                    ModuleFlowView(
                        topic: topic,
                        subtopicName: subtopic
                    )
                }
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

        BrutalCard(backgroundColor: .flatSurface, borderColor: category.color, shadowSize: 4) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.color)

                Text(category.rawValue)
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                    .foregroundColor(.brutalBlack)
                    .lineLimit(1)

                Text("\(categoryTopics.count) topic\(categoryTopics.count == 1 ? "" : "s")")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.flatSecondaryText)

                if totalSubtopics > 0 {
                    Text("\(totalMastered)/\(totalSubtopics) mastered")
                        .font(.system(.caption2, design: .monospaced, weight: .medium))
                        .foregroundColor(totalMastered == totalSubtopics ? .brutalTeal : .flatSecondaryText)
                }
            }
        }
    }
}
