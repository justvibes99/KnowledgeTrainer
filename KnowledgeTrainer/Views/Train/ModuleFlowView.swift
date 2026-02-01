import SwiftUI
import SwiftData

struct ModuleFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var reviewItems: [ReviewItem]
    @Query private var allProgress: [SubtopicProgress]

    let topic: Topic
    let subtopicName: String
    var initialQuestions: [GeneratedQuestion] = []
    var initialLesson: LessonPayload?

    @State private var phase: ModulePhase = .loading
    @State private var viewModel = DrillSessionViewModel()
    @State private var showEndConfirmation = false
    @State private var lessonScrolled = false
    @State private var fetchedLesson: LessonPayload?
    @State private var fetchedQuestions: [GeneratedQuestion] = []

    // Gamification
    @State private var gamificationService: GamificationService?
    @State private var showAchievementToast = false
    @State private var unlockedAchievement: AchievementDefinition?
    @State private var showLevelUp = false
    @State private var levelUpRank: ScholarRank?

    // Related topic branching
    @State private var branchTopic: Topic?
    @State private var branchQuestions: [GeneratedQuestion] = []
    @State private var branchLesson: LessonPayload?
    @State private var navigateToBranch = false
    @State private var isCreatingBranch = false
    @State private var showQueueToast = false
    @State private var questionFormat: QuestionFormat = .mixed
    @State private var showFormatPicker = false

    private var subtopicProgressItem: SubtopicProgress? {
        allProgress.first { $0.topicID == topic.id && $0.subtopicName == subtopicName }
    }

    private var hasLesson: Bool {
        if let progress = subtopicProgressItem {
            return !progress.lessonOverview.isEmpty
        }
        return initialLesson != nil
    }

    enum ModulePhase {
        case loading
        case lesson
        case quiz
        case summary
    }

    var body: some View {
        ZStack {
            Color.brutalBackground.ignoresSafeArea()

            switch phase {
            case .loading:
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.brutalBlack)
                    Text("PREPARING LESSON...")
                        .font(.system(.caption, design: .default, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.brutalBlack)
                }
            case .lesson:
                lessonPhase
            case .quiz:
                quizPhase
            case .summary:
                summaryPhase
            }

            // Queue toast
            if showQueueToast {
                VStack {
                    Spacer()
                    Text("ADDED TO QUEUE")
                        .font(.system(.caption, design: .default, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.brutalBlack)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }

            // Achievement toast overlay
            if showAchievementToast, let achievement = unlockedAchievement {
                AchievementToast(achievement: achievement) {
                    showAchievementToast = false
                    unlockedAchievement = nil
                }
                .zIndex(20)
            }

            // Level-up overlay
            if showLevelUp, let rank = levelUpRank, let service = gamificationService, let profile = service.getProfile() {
                LevelUpOverlay(rank: rank, totalXP: profile.totalXP) {
                    showLevelUp = false
                    levelUpRank = nil
                }
                .zIndex(30)
            }

            // Mastery celebration overlay
            if viewModel.showMasteryCelebration {
                masteryCelebrationOverlay
            }

            // Format picker popup
            if showFormatPicker {
                Color.brutalBlack.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showFormatPicker = false }

                VStack(spacing: 16) {
                    Text("QUESTION FORMAT")
                        .font(.system(.body, design: .default, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.brutalBlack)

                    BrutalButton(title: "Multiple Choice", color: .brutalYellow, fullWidth: true) {
                        showFormatPicker = false
                        questionFormat = .multipleChoice
                        markLessonViewed()
                        startQuizPhase()
                    }

                    BrutalButton(title: "Short Answer", color: .brutalTeal, fullWidth: true) {
                        showFormatPicker = false
                        questionFormat = .shortAnswer
                        markLessonViewed()
                        startQuizPhase()
                    }

                    BrutalButton(title: "Mixed", color: .white, fullWidth: true) {
                        showFormatPicker = false
                        questionFormat = .mixed
                        markLessonViewed()
                        startQuizPhase()
                    }
                }
                .padding(24)
                .background(Color.brutalBackground)
                .overlay(Rectangle().stroke(Color.brutalBlack, lineWidth: 3))
                .background(Rectangle().fill(Color.brutalBlack).offset(x: 8, y: 8))
                .padding(.horizontal, 32)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: showFormatPicker)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                        .foregroundColor(.brutalBlack)
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if phase == .quiz && viewModel.questionsAnswered > 0 {
                        showEndConfirmation = true
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.body.bold())
                        .foregroundColor(.brutalBlack)
                }
                .buttonStyle(.plain)
            }
        }
        .brutalAlert(
            isPresented: $showEndConfirmation,
            title: "End Module?",
            message: "Your progress will be saved.",
            primaryButton: BrutalAlertButton(title: "End", isDestructive: true) {
                viewModel.endSession()
                phase = .summary
            },
            secondaryButton: BrutalAlertButton(title: "Cancel") {}
        )
        .brutalAlert(
            isPresented: $viewModel.showError,
            title: "Error",
            message: viewModel.errorMessage ?? "Unknown error",
            primaryButton: BrutalAlertButton(title: "OK") {}
        )
        .onAppear {
            let service = GamificationService(context: modelContext)
            gamificationService = service
            viewModel.gamificationService = service
            setupModule()
        }
        .onChange(of: viewModel.sessionEnded) { _, ended in
            if ended {
                checkGamificationResults()
            }
        }
        .navigationDestination(isPresented: $navigateToBranch) {
            if let branchTopic {
                LearningPathView(
                    topic: branchTopic,
                    initialQuestions: branchQuestions,
                    initialLesson: branchLesson
                )
            }
        }
    }

    // MARK: - Lesson Phase

    @ViewBuilder
    private var lessonPhase: some View {
        let progress = subtopicProgressItem

        if let progress, !progress.lessonOverview.isEmpty {
            GeometryReader { geo in
                ScrollView(.vertical) {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("LESSON")
                                .font(.system(.caption, design: .default, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.brutalBlack)

                            Text(subtopicName.uppercased())
                                .font(.system(size: 22, weight: .bold, design: .default))
                                .tracking(1)
                                .foregroundColor(.brutalBlack)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)

                        // Overview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("OVERVIEW")
                                .font(.system(.caption, design: .default, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(.brutalBlack)

                            Text(progress.lessonOverview)
                                .font(.system(.body, design: .default))
                                .foregroundColor(.brutalBlack)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.brutalMint)
                        .overlay(Rectangle().stroke(Color.brutalBlack, lineWidth: 3))
                        .padding(.horizontal, 20)

                        // Key Facts
                        VStack(alignment: .leading, spacing: 12) {
                            Text("KEY FACTS")
                                .font(.system(.caption, design: .default, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(.brutalBlack)

                            ForEach(Array(progress.lessonKeyFacts.enumerated()), id: \.offset) { index, fact in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1)")
                                        .font(.system(.caption, design: .monospaced, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.brutalBlack)

                                    Text(fact)
                                        .font(.system(.subheadline, design: .default))
                                        .foregroundColor(.brutalBlack)
                                        .lineSpacing(2)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Related Topic Chips
                        if !progress.lessonConnections.isEmpty {
                            relatedChipsSection(connections: progress.lessonConnections)
                        }

                        // Start Quiz Button
                        BrutalButton(title: "Start Quiz", color: .brutalYellow, fullWidth: true) {
                            showFormatPicker = true
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .frame(width: geo.size.width)
                }
            }
        } else if let lesson = initialLesson ?? fetchedLesson {
            LessonCardView(lesson: lesson) {
                showFormatPicker = true
            }
        } else {
            // No lesson content — show format picker
            Color.clear.onAppear { showFormatPicker = true }
        }
    }

    // MARK: - Quiz Phase

    @ViewBuilder
    private var quizPhase: some View {
        if viewModel.showingLesson, let lesson = viewModel.currentLesson {
            LessonCardView(lesson: lesson) {
                viewModel.dismissLesson(modelContext: modelContext)
            }
        } else if viewModel.isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.brutalBlack)
                Text("LOADING QUESTIONS...")
                    .font(.system(.caption, design: .default, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.brutalBlack)
            }
        } else if let question = viewModel.currentQuestion {
            ScrollView {
                VStack(spacing: 20) {
                    // Timer
                    if viewModel.timerEnabled && !viewModel.isAnswerSubmitted {
                        TimerBar(
                            remaining: viewModel.timerRemaining,
                            total: viewModel.timerDuration
                        )
                        .padding(.horizontal, 24)
                        .onChange(of: viewModel.timerRemaining) { _, newValue in
                            if newValue <= 0 && viewModel.timerActive {
                                Task {
                                    await viewModel.submitTimedOut(modelContext: modelContext)
                                }
                            }
                        }
                    }

                    // Question Card
                    QuestionCardView(
                        question: question,
                        userAnswer: $viewModel.userAnswer,
                        isSubmitted: viewModel.isAnswerSubmitted,
                        isCorrect: viewModel.isCorrect,
                        subtopicQuestionNumber: viewModel.subtopicQuestionNumber,
                        onSubmit: {
                            Task {
                                await viewModel.submitAnswer(modelContext: modelContext)
                                checkModuleMastery()
                            }
                        }
                    )
                    .padding(.horizontal, 24)

                    // Explanation
                    if viewModel.isAnswerSubmitted {
                        VStack(spacing: 12) {
                            DisclosureGroup {
                                Text(question.explanation)
                                    .font(.system(.body, design: .default))
                                    .foregroundColor(.brutalBlack)
                                    .padding(.top, 8)
                            } label: {
                                Text("REVIEW")
                                    .font(.system(.caption, design: .default, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundColor(.brutalBlack)
                            }

                            BrutalButton(title: "Next", color: .brutalTeal, fullWidth: true) {
                                viewModel.serveNextQuestion()
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Stats Bar
                    HStack(spacing: 20) {
                        VStack(spacing: 2) {
                            if viewModel.comboTier != .none {
                                Text(viewModel.comboTier.label)
                                    .font(.system(.caption, design: .monospaced, weight: .black))
                                    .tracking(1)
                                    .foregroundColor(viewModel.comboTier.color)
                                    .scaleEffect(viewModel.comboTier == .five ? 1.1 : viewModel.comboTier == .ten ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: viewModel.comboTier)
                            } else {
                                Text("\(viewModel.currentStreak)")
                                    .font(.system(.body, design: .monospaced, weight: .bold))
                                    .foregroundColor(.brutalBlack)
                            }
                            Text("STREAK")
                                .font(.system(.caption2, design: .default, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(.brutalBlack.opacity(0.6))
                        }
                        statItem(label: "ACCURACY", value: "\(Int(viewModel.sessionAccuracy))%")
                        statItem(label: "PROGRESS", value: "\(viewModel.questionsAnswered)/\(viewModel.maxQuestions)")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)

                    Spacer().frame(height: 60)
                }
            }
        } else {
            // Session ended naturally — move to summary
            Color.clear.onAppear {
                phase = .summary
            }
        }
    }

    // MARK: - Summary Phase

    @ViewBuilder
    private var summaryPhase: some View {
        SessionSummaryView(
            questionsAnswered: viewModel.questionsAnswered,
            correctAnswers: viewModel.correctAnswers,
            accuracy: viewModel.sessionAccuracy,
            difficultyReached: viewModel.currentDifficulty,
            wrongAnswers: viewModel.wrongAnswers,
            subtopicStats: viewModel.subtopicSessionStats,
            masteredThisSession: viewModel.masteredThisSession,
            xpEvents: gamificationService?.pendingXPEvents ?? [],
            onDone: { dismiss() }
        )
    }

    // MARK: - Mastery Celebration Overlay

    @ViewBuilder
    private var masteryCelebrationOverlay: some View {
        ZStack {
            Color.brutalBlack.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("MASTERED")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .tracking(3)
                    .foregroundColor(.brutalBlack)

                Text(viewModel.masteredSubtopicName.uppercased())
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .tracking(1.5)
                    .foregroundColor(.brutalBlack)
                    .multilineTextAlignment(.center)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.brutalTeal)

                if let next = viewModel.nextSubtopicName {
                    Text("NEXT UP: \(next.uppercased())")
                        .font(.system(.caption, design: .default, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.brutalBlack.opacity(0.7))
                }

                BrutalButton(
                    title: "Done",
                    color: .brutalYellow,
                    fullWidth: true
                ) {
                    viewModel.dismissMasteryCelebration()
                    phase = .summary
                }
            }
            .padding(32)
            .background(Color.brutalYellow)
            .overlay(
                Rectangle()
                    .stroke(Color.brutalBlack, lineWidth: 4)
            )
            .background(
                Rectangle()
                    .fill(Color.brutalBlack)
                    .offset(x: 8, y: 8)
            )
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Related Topic Chips

    @ViewBuilder
    private func relatedChipsSection(connections: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RELATED TOPICS")
                .font(.system(.caption, design: .default, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.brutalBlack)

            ForEach(connections, id: \.self) { connection in
                Text(connection.uppercased())
                    .font(.system(.caption2, design: .default, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.brutalBlack)
                    .lineLimit(2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.brutalMint)
                    .overlay(
                        Rectangle()
                            .stroke(Color.brutalBlack, lineWidth: 2)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        createBranchTopic(name: connection)
                    }
                    .onLongPressGesture {
                        queueRelatedTopic(name: connection)
                    }
            }

            if isCreatingBranch {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.brutalBlack)
                    Text("CREATING PATH...")
                        .font(.system(.caption2, design: .default, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.brutalBlack)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.body, design: .monospaced, weight: .bold))
                .foregroundColor(.brutalBlack)
            Text(label)
                .font(.system(.caption2, design: .default, weight: .bold))
                .tracking(0.8)
                .foregroundColor(.brutalBlack.opacity(0.6))
        }
    }

    private func setupModule() {
        if hasLesson {
            phase = .lesson
            prefetchNextSubtopicLesson()
        } else {
            phase = .loading
            fetchLessonContent()
        }
    }

    private func fetchLessonContent() {
        Task {
            do {
                let (questions, lesson) = try await APIClient.shared.generateQuestionBatch(
                    topic: topic.name,
                    subtopics: Array(topic.subtopics),
                    difficulty: 1,
                    previousQuestions: [],
                    focusSubtopic: subtopicName,
                    nextSubtopic: subtopicName
                )

                await MainActor.run {
                    fetchedQuestions = questions
                    if let lesson {
                        if let progress = subtopicProgressItem {
                            progress.lessonOverview = lesson.overview
                            progress.lessonKeyFacts = lesson.keyFacts
                            progress.lessonMisconceptions = lesson.misconceptions ?? []
                            progress.lessonConnections = lesson.connections ?? []
                            try? modelContext.save()
                        }
                        fetchedLesson = lesson
                        phase = .lesson
                        prefetchNextSubtopicLesson()
                    } else {
                        startQuizPhase()
                    }
                }
            } catch {
                await MainActor.run {
                    startQuizPhase()
                }
            }
        }
    }

    private func prefetchNextSubtopicLesson() {
        guard let nextName = nextSubtopicAfterCurrent() else { return }

        // Check if next subtopic already has lesson content
        if let nextProgress = allProgress.first(where: { $0.topicID == topic.id && $0.subtopicName == nextName }),
           !nextProgress.lessonOverview.isEmpty {
            return
        }

        Task {
            do {
                let (_, lesson) = try await APIClient.shared.generateQuestionBatch(
                    topic: topic.name,
                    subtopics: Array(topic.subtopics),
                    difficulty: 1,
                    previousQuestions: [],
                    focusSubtopic: nextName,
                    nextSubtopic: nextName
                )

                if let lesson {
                    await MainActor.run {
                        if let nextProgress = allProgress.first(where: { $0.topicID == topic.id && $0.subtopicName == nextName }),
                           nextProgress.lessonOverview.isEmpty {
                            nextProgress.lessonOverview = lesson.overview
                            nextProgress.lessonKeyFacts = lesson.keyFacts
                            nextProgress.lessonMisconceptions = lesson.misconceptions ?? []
                            nextProgress.lessonConnections = lesson.connections ?? []
                            try? modelContext.save()
                        }
                    }
                }
            } catch {
                // Prefetch failure is silent — user will fetch on demand
            }
        }
    }

    private func nextSubtopicAfterCurrent() -> String? {
        guard let idx = topic.subtopics.firstIndex(of: subtopicName),
              idx + 1 < topic.subtopics.count else { return nil }
        return topic.subtopics[idx + 1]
    }

    private func startQuizPhase() {
        phase = .quiz

        // Reset subtopic progress for a fresh quiz attempt
        if let progress = subtopicProgressItem, !progress.isMastered {
            progress.questionsAnswered = 0
            progress.questionsCorrect = 0
            try? modelContext.save()
        }

        let progressItems = allProgress.filter { $0.topicID == topic.id }
        let timerOn = UserDefaults.standard.bool(forKey: "timerEnabled")
        let timerDur = UserDefaults.standard.integer(forKey: "timerDuration")
        let questions = initialQuestions.isEmpty ? fetchedQuestions : initialQuestions

        viewModel.setup(
            topic: topic,
            subtopics: Set([subtopicName]),
            initialQuestions: questions,
            reviewItems: SpacedRepetitionEngine.dueItems(from: reviewItems).filter { $0.topicID == topic.id },
            timerEnabled: timerOn,
            timerDuration: timerDur > 0 ? timerDur : 15,
            initialLesson: nil,
            focusSubtopic: subtopicName,
            subtopicProgressItems: progressItems,
            questionFormat: questionFormat
        )
    }

    private func markLessonViewed() {
        guard let progress = subtopicProgressItem else { return }
        progress.lessonViewed = true
        if let lesson = initialLesson ?? fetchedLesson {
            progress.lessonOverview = lesson.overview
            progress.lessonKeyFacts = lesson.keyFacts
            progress.lessonMisconceptions = lesson.misconceptions ?? []
            progress.lessonConnections = lesson.connections ?? []
        }
        try? modelContext.save()
    }

    private func checkModuleMastery() {
        if let progress = subtopicProgressItem, progress.isMastered && !viewModel.showMasteryCelebration {
            // Mastery is handled by DrillSessionViewModel
        }
        checkGamificationResults()
    }

    private func checkGamificationResults() {
        guard let service = gamificationService else { return }
        if let achievement = service.unlockedAchievement {
            unlockedAchievement = achievement
            showAchievementToast = true
            HapticManager.success()
            service.unlockedAchievement = nil
        }
        if service.didRankUp, let rank = service.newRank {
            levelUpRank = rank
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showLevelUp = true
            }
            service.didRankUp = false
            service.newRank = nil
        }
    }

    private func createBranchTopic(name: String) {
        guard !isCreatingBranch else { return }
        isCreatingBranch = true
        Task {
            do {
                let (structure, questions, lesson, relatedTopics, category) = try await APIClient.shared.generateTopicAndFirstBatch(topic: name)

                let newTopic = Topic(
                    name: structure.name,
                    subtopics: structure.subtopics,
                    dateCreated: Date(),
                    lastPracticed: Date(),
                    subtopicsOrdered: true,
                    relatedTopics: relatedTopics,
                    category: category
                )
                modelContext.insert(newTopic)

                for (index, sub) in structure.subtopics.enumerated() {
                    let prog = SubtopicProgress(
                        topicID: newTopic.id,
                        subtopicName: sub,
                        sortOrder: index
                    )
                    if index == 0, let lesson {
                        prog.lessonOverview = lesson.overview
                        prog.lessonKeyFacts = lesson.keyFacts
                        prog.lessonMisconceptions = lesson.misconceptions ?? []
                        prog.lessonConnections = lesson.connections ?? []
                    }
                    modelContext.insert(prog)
                }
                try modelContext.save()

                await MainActor.run {
                    branchTopic = newTopic
                    branchQuestions = questions
                    branchLesson = lesson
                    isCreatingBranch = false
                    navigateToBranch = true
                }
            } catch {
                await MainActor.run {
                    isCreatingBranch = false
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showError = true
                }
            }
        }
    }

    private func queueRelatedTopic(name: String) {
        let item = WantToLearnItem(
            topicName: name,
            sourceTopicID: topic.id,
            sourceSubtopic: subtopicName
        )
        modelContext.insert(item)
        try? modelContext.save()
        HapticManager.success()

        withAnimation(.easeInOut(duration: 0.3)) {
            showQueueToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                showQueueToast = false
            }
        }
    }
}
