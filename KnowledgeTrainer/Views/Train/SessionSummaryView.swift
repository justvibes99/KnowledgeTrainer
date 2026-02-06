import SwiftUI

struct SessionSummaryView: View {
    let questionsAnswered: Int
    let correctAnswers: Int
    let accuracy: Double
    let depthLabel: String
    let wrongAnswers: [(question: GeneratedQuestion, userAnswer: String)]
    var subtopicStats: [String: (answered: Int, correct: Int)] = [:]
    var masteredThisSession: [String] = []
    var xpEvents: [XPEvent] = []
    var unlockedAchievements: [AchievementDefinition] = []
    var onContinueLearning: (() -> Void)? = nil
    var onRetryMistakes: (() -> Void)? = nil
    let onDone: () -> Void

    private var isPerfectSession: Bool {
        questionsAnswered >= 5 && correctAnswers == questionsAnswered
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Session Complete")
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .foregroundColor(.brutalBlack)
                    .padding(.top, 24)

                // Stats Cards
                HStack(spacing: 12) {
                    statCard(label: "Answered", value: "\(questionsAnswered)", color: .brutalTeal)
                    statCard(label: "Accuracy", value: "\(Int(accuracy))%", color: .brutalYellow)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    statCard(label: "Correct", value: "\(correctAnswers)", color: .brutalMint)
                    statCard(label: "Depth", value: depthLabel, color: .brutalLavender)
                }
                .padding(.horizontal, 24)

                // Mastered This Session
                if !masteredThisSession.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mastered This Session")
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundColor(.brutalBlack)

                        ForEach(masteredThisSession, id: \.self) { subtopic in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.brutalTeal)
                                Text(subtopic)
                                    .font(.system(.caption, design: .monospaced, weight: .medium))
                                    .foregroundColor(.brutalBlack)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.brutalTeal.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.brutalTeal, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Achievements Unlocked
                if !unlockedAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Achievements Unlocked")
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundColor(.brutalBlack)

                        ForEach(unlockedAchievements) { achievement in
                            HStack(spacing: 12) {
                                Image(systemName: achievement.iconName)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.brutalBlack)
                                    .frame(width: 40, height: 40)
                                    .background(Color.brutalYellow)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.brutalBlack, lineWidth: 1)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(achievement.name)
                                        .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                                        .foregroundColor(.brutalBlack)
                                    Text(achievement.description)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.flatSecondaryText)
                                }

                                Spacer()

                                Text("+\(achievement.xpReward) XP")
                                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                                    .foregroundColor(.brutalTeal)
                            }
                            .padding(12)
                            .background(Color.brutalYellow.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.brutalYellow, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // XP Summary
                if !xpEvents.isEmpty {
                    SessionXPSummaryView(
                        xpEvents: xpEvents,
                        isPerfectSession: isPerfectSession
                    )
                    .padding(.horizontal, 24)
                }

                // Subtopic Breakdown
                if !subtopicStats.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subtopics Practiced")
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundColor(.brutalBlack)

                        ForEach(Array(subtopicStats.keys.sorted()), id: \.self) { subtopic in
                            if let stats = subtopicStats[subtopic] {
                                let acc = stats.answered > 0 ? Int(Double(stats.correct) / Double(stats.answered) * 100) : 0
                                HStack {
                                    Text(subtopic)
                                        .font(.system(.caption2, design: .monospaced, weight: .medium))
                                        .foregroundColor(.brutalBlack)
                                        .lineLimit(1)

                                    Spacer()

                                    Text("\(stats.correct)/\(stats.answered)")
                                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                                        .foregroundColor(.brutalBlack)

                                    Text("\(acc)%")
                                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                                        .foregroundColor(acc >= 80 ? .brutalTeal : .brutalCoral)
                                        .frame(width: 40, alignment: .trailing)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.flatSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.flatBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Wrong Answers
                if !wrongAnswers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review These")
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundColor(.brutalBlack)

                        ForEach(Array(wrongAnswers.enumerated()), id: \.offset) { _, item in
                            BrutalCard(backgroundColor: .brutalSurface) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(item.question.questionText)
                                        .font(.system(.body, design: .monospaced, weight: .medium))
                                        .foregroundColor(.brutalBlack)

                                    HStack(spacing: 4) {
                                        Text("Your answer:")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.flatSecondaryText)
                                        Text(item.userAnswer.isEmpty ? "(no answer)" : item.userAnswer)
                                            .font(.system(.caption, design: .monospaced, weight: .medium))
                                            .foregroundColor(.brutalCoral)
                                    }

                                    HStack(spacing: 4) {
                                        Text("Correct:")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.flatSecondaryText)
                                        Text(item.question.correctAnswer)
                                            .font(.system(.caption, design: .monospaced, weight: .medium))
                                            .foregroundColor(.brutalTeal)
                                    }

                                    Text(item.question.explanation)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.brutalBlack.opacity(0.8))
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    if let onRetryMistakes, !wrongAnswers.isEmpty {
                        BrutalButton(title: "Retry \(wrongAnswers.count) Mistake\(wrongAnswers.count == 1 ? "" : "s")", color: .brutalCoral, fullWidth: true) {
                            onRetryMistakes()
                        }
                    }

                    if let onContinueLearning {
                        BrutalButton(title: "Continue Learning", color: .brutalTeal, fullWidth: true) {
                            onContinueLearning()
                        }
                    }

                    Button {
                        onDone()
                    } label: {
                        Text("Done")
                            .font(.system(.body, design: .monospaced, weight: .medium))
                            .foregroundColor(.flatSecondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    @ViewBuilder
    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 32, weight: .semibold, design: .monospaced))
                .foregroundColor(.brutalBlack)
            Text(label)
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .foregroundColor(.brutalBlack)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.flatBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
