import SwiftUI
import SwiftData

struct DrillSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let topic: Topic
    let selectedSubtopics: Set<String>
    let initialQuestions: [GeneratedQuestion]
    let reviewItems: [ReviewItem]
    var initialLesson: LessonPayload?
    var focusSubtopic: String?
    var subtopicProgressItems: [SubtopicProgress] = []

    @State private var viewModel = DrillSessionViewModel()
    @State private var showEndConfirmation = false
    @State private var gamificationService: GamificationService?

    var body: some View {
        ZStack {
            Color.brutalBackground.ignoresSafeArea()

            if viewModel.showingLesson, let lesson = viewModel.currentLesson {
                LessonCardView(lesson: lesson) {
                    viewModel.dismissLesson(modelContext: modelContext)
                }
            } else if viewModel.sessionEnded {
                SessionSummaryView(
                    questionsAnswered: viewModel.questionsAnswered,
                    correctAnswers: viewModel.correctAnswers,
                    accuracy: viewModel.sessionAccuracy,
                    depthLabel: viewModel.learningDepth.displayName,
                    wrongAnswers: viewModel.wrongAnswers,
                    subtopicStats: viewModel.subtopicSessionStats,
                    masteredThisSession: viewModel.masteredThisSession,
                    xpEvents: gamificationService?.pendingXPEvents ?? [],
                    onDone: { dismiss() }
                )
            } else if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.brutalBlack)
                    Text("Loading questions...")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
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
                            subtopicQuestionNumber: viewModel.focusSubtopic != nil ? viewModel.subtopicQuestionNumber : nil,
                            onSubmit: {
                                Task {
                                    await viewModel.submitAnswer(modelContext: modelContext)
                                }
                            }
                        )
                        .padding(.horizontal, 24)

                        // Explanation
                        if viewModel.isAnswerSubmitted {
                            VStack(spacing: 12) {
                                DisclosureGroup {
                                    Text(question.explanation)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.brutalBlack)
                                        .padding(.top, 8)
                                } label: {
                                    Text("Why?")
                                        .font(.system(.caption, design: .monospaced, weight: .medium))
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
                            statItem(label: "Streak", value: "\(viewModel.currentStreak)")
                            statItem(label: "Accuracy", value: "\(Int(viewModel.sessionAccuracy))%")
                            statItem(label: "Answered", value: "\(viewModel.questionsAnswered)")
                            statItem(label: "Depth", value: viewModel.learningDepth.displayName)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)

                        // Focus indicator
                        if let focus = viewModel.focusSubtopic {
                            Text("Focusing: \(focus)")
                                .font(.system(.caption2, design: .monospaced, weight: .medium))
                                .foregroundColor(.flatSecondaryText)
                        }

                        // End Session Button
                        Button(action: { showEndConfirmation = true }) {
                            Text("End Session")
                                .font(.system(.caption, design: .monospaced, weight: .medium))
                                .foregroundColor(.brutalCoral)
                        }
                        .padding(.bottom, 24)

                        Spacer().frame(height: 60)
                    }
                }
            }

            // Mastery Celebration Overlay
            if viewModel.showMasteryCelebration {
                masteryCelebrationOverlay
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    showEndConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .alert("End Session?", isPresented: $showEndConfirmation) {
            Button("End", role: .destructive) { viewModel.endSession() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .onAppear {
            let service = GamificationService(context: modelContext)
            gamificationService = service
            viewModel.gamificationService = service

            let timerOn = UserDefaults.standard.bool(forKey: "timerEnabled")
            let timerDur = UserDefaults.standard.integer(forKey: "timerDuration")
            viewModel.setup(
                topic: topic,
                subtopics: selectedSubtopics,
                initialQuestions: initialQuestions,
                reviewItems: reviewItems,
                timerEnabled: timerOn,
                timerDuration: timerDur > 0 ? timerDur : 15,
                initialLesson: initialLesson,
                focusSubtopic: focusSubtopic,
                subtopicProgressItems: subtopicProgressItems
            )
        }
    }

    @ViewBuilder
    private var masteryCelebrationOverlay: some View {
        ZStack {
            Color.brutalBlack.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Mastered")
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundColor(.brutalBlack)

                Text(viewModel.masteredSubtopicName)
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .foregroundColor(.brutalBlack)
                    .multilineTextAlignment(.center)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.brutalTeal)

                if let next = viewModel.nextSubtopicName {
                    Text("Next up: \(next)")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundColor(.brutalBlack.opacity(0.7))
                }

                BrutalButton(
                    title: viewModel.nextSubtopicName != nil ? "Continue" : "Keep Going",
                    color: .brutalYellow,
                    fullWidth: true
                ) {
                    viewModel.dismissMasteryCelebration()
                }
            }
            .padding(32)
            .background(Color.brutalYellow)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.flatBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 32)
        }
    }

    @ViewBuilder
    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.body, design: .monospaced, weight: .medium))
                .foregroundColor(.brutalBlack)
            Text(label)
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .foregroundColor(.flatSecondaryText)
        }
    }
}
