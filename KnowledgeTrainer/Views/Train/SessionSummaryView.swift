import SwiftUI

struct SessionSummaryView: View {
    let questionsAnswered: Int
    let correctAnswers: Int
    let accuracy: Double
    let difficultyReached: Int
    let wrongAnswers: [(question: GeneratedQuestion, userAnswer: String)]
    var subtopicStats: [String: (answered: Int, correct: Int)] = [:]
    var masteredThisSession: [String] = []
    var xpEvents: [XPEvent] = []
    let onDone: () -> Void

    private var isPerfectSession: Bool {
        questionsAnswered >= 5 && correctAnswers == questionsAnswered
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("SESSION COMPLETE")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .tracking(2)
                    .foregroundColor(.brutalBlack)
                    .padding(.top, 24)

                // Stats Cards
                HStack(spacing: 12) {
                    statCard(label: "ANSWERED", value: "\(questionsAnswered)", color: .brutalTeal)
                    statCard(label: "ACCURACY", value: "\(Int(accuracy))%", color: .brutalYellow)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    statCard(label: "CORRECT", value: "\(correctAnswers)", color: .brutalMint)
                    statCard(label: "DIFFICULTY", value: "\(difficultyReached)", color: .brutalLavender)
                }
                .padding(.horizontal, 24)

                // Mastered This Session
                if !masteredThisSession.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MASTERED THIS SESSION")
                            .font(.system(.caption, design: .default, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.brutalBlack)

                        ForEach(masteredThisSession, id: \.self) { subtopic in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.brutalTeal)
                                Text(subtopic.uppercased())
                                    .font(.system(.caption, design: .default, weight: .bold))
                                    .tracking(0.8)
                                    .foregroundColor(.brutalBlack)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.brutalTeal.opacity(0.15))
                            .overlay(
                                Rectangle()
                                    .stroke(Color.brutalTeal, lineWidth: 2)
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
                        Text("SUBTOPICS PRACTICED")
                            .font(.system(.caption, design: .default, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.brutalBlack)

                        ForEach(Array(subtopicStats.keys.sorted()), id: \.self) { subtopic in
                            if let stats = subtopicStats[subtopic] {
                                let acc = stats.answered > 0 ? Int(Double(stats.correct) / Double(stats.answered) * 100) : 0
                                HStack {
                                    Text(subtopic.uppercased())
                                        .font(.system(.caption2, design: .default, weight: .bold))
                                        .tracking(0.8)
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
                                .background(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.brutalBlack, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Wrong Answers
                if !wrongAnswers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("REVIEW THESE")
                            .font(.system(.caption, design: .default, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.brutalBlack)

                        ForEach(Array(wrongAnswers.enumerated()), id: \.offset) { _, item in
                            BrutalCard(backgroundColor: .white) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(item.question.questionText)
                                        .font(.system(.body, design: .default, weight: .bold))
                                        .foregroundColor(.brutalBlack)

                                    HStack(spacing: 4) {
                                        Text("Your answer:")
                                            .font(.system(.caption, design: .default))
                                            .foregroundColor(.brutalBlack.opacity(0.6))
                                        Text(item.userAnswer.isEmpty ? "(no answer)" : item.userAnswer)
                                            .font(.system(.caption, design: .default, weight: .bold))
                                            .foregroundColor(.brutalCoral)
                                    }

                                    HStack(spacing: 4) {
                                        Text("Correct:")
                                            .font(.system(.caption, design: .default))
                                            .foregroundColor(.brutalBlack.opacity(0.6))
                                        Text(item.question.correctAnswer)
                                            .font(.system(.caption, design: .default, weight: .bold))
                                            .foregroundColor(.brutalTeal)
                                    }

                                    Text(item.question.explanation)
                                        .font(.system(.caption, design: .default))
                                        .foregroundColor(.brutalBlack.opacity(0.8))
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                BrutalButton(title: "Done", color: .brutalYellow, fullWidth: true) {
                    onDone()
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
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.brutalBlack)
            Text(label)
                .font(.system(.caption2, design: .default, weight: .bold))
                .tracking(1)
                .foregroundColor(.brutalBlack)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color)
        .overlay(
            Rectangle()
                .stroke(Color.brutalBlack, lineWidth: 3)
        )
        .background(
            Rectangle()
                .fill(Color.brutalBlack)
                .offset(x: 4, y: 4)
        )
    }
}
