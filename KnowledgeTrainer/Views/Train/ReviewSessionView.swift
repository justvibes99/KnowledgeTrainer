import SwiftUI
import SwiftData

struct ReviewSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let reviewItems: [ReviewItem]
    @State private var viewModel = DrillSessionViewModel()

    var body: some View {
        ZStack {
            Color.brutalBackground.ignoresSafeArea()

            if viewModel.sessionEnded {
                SessionSummaryView(
                    questionsAnswered: viewModel.questionsAnswered,
                    correctAnswers: viewModel.correctAnswers,
                    accuracy: viewModel.sessionAccuracy,
                    difficultyReached: 0,
                    wrongAnswers: viewModel.wrongAnswers,
                    onDone: { dismiss() }
                )
            } else if let question = viewModel.currentQuestion {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Review Session")
                            .font(.system(.title3, design: .default, weight: .semibold))
                            .foregroundColor(.brutalBlack)
                            .padding(.top, 16)

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

                        QuestionCardView(
                            question: question,
                            userAnswer: $viewModel.userAnswer,
                            isSubmitted: viewModel.isAnswerSubmitted,
                            isCorrect: viewModel.isCorrect,
                            onSubmit: {
                                Task {
                                    await viewModel.submitAnswer(modelContext: modelContext)
                                }
                            }
                        )
                        .padding(.horizontal, 24)

                        if viewModel.isAnswerSubmitted {
                            VStack(spacing: 12) {
                                DisclosureGroup {
                                    Text(question.explanation)
                                        .font(.system(.body, design: .default))
                                        .foregroundColor(.brutalBlack)
                                        .padding(.top, 8)
                                } label: {
                                    Text("Why?")
                                        .font(.system(.caption, design: .default, weight: .medium))
                                        .foregroundColor(.brutalBlack)
                                }

                                BrutalButton(title: "Next", color: .brutalTeal, fullWidth: true) {
                                    viewModel.serveNextQuestion()
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        HStack(spacing: 20) {
                            VStack(spacing: 2) {
                                Text("\(viewModel.currentStreak)")
                                    .font(.system(.body, design: .monospaced, weight: .medium))
                                    .foregroundColor(.brutalBlack)
                                Text("Streak")
                                    .font(.system(.caption2, design: .default, weight: .medium))
                                    .foregroundColor(.flatSecondaryText)
                            }
                            VStack(spacing: 2) {
                                Text("\(Int(viewModel.sessionAccuracy))%")
                                    .font(.system(.body, design: .monospaced, weight: .medium))
                                    .foregroundColor(.brutalBlack)
                                Text("Accuracy")
                                    .font(.system(.caption2, design: .default, weight: .medium))
                                    .foregroundColor(.flatSecondaryText)
                            }
                        }
                        .padding(.vertical, 12)

                        Button(action: { viewModel.endSession() }) {
                            Text("End Review")
                                .font(.system(.caption, design: .default, weight: .medium))
                                .foregroundColor(.brutalCoral)
                        }

                        Spacer().frame(height: 60)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Text("No Reviews Due")
                        .font(.system(.title3, design: .default, weight: .semibold))
                        .foregroundColor(.brutalBlack)
                    BrutalButton(title: "Go Back", color: .brutalYellow) {
                        dismiss()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let timerOn = UserDefaults.standard.bool(forKey: "timerEnabled")
            let timerDur = UserDefaults.standard.integer(forKey: "timerDuration")
            viewModel.setupReviewOnly(
                reviewItems: reviewItems,
                timerEnabled: timerOn,
                timerDuration: timerDur > 0 ? timerDur : 15
            )
        }
    }
}
