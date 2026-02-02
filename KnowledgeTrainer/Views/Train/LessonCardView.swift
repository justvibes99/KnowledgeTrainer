import SwiftUI

struct LessonCardView: View {
    let lesson: LessonPayload
    let onStartDrilling: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Lesson")
                        .font(.system(.caption, design: .default, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.brutalBlack)

                    Text(lesson.subtopic)
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .foregroundColor(.brutalBlack)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Overview
                BrutalCard(backgroundColor: .brutalMint) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.system(.caption, design: .default, weight: .medium))
                            .foregroundColor(.brutalBlack)

                        Text(lesson.overview)
                            .font(.system(.body, design: .default))
                            .foregroundColor(.brutalBlack)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 24)

                // Key Facts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Facts")
                        .font(.system(.caption, design: .default, weight: .medium))
                        .foregroundColor(.brutalBlack)
                        .padding(.horizontal, 24)

                    ForEach(Array(lesson.keyFacts.enumerated()), id: \.offset) { index, fact in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(.body, design: .monospaced, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.brutalBlack)

                            Text(fact)
                                .font(.system(.body, design: .default))
                                .foregroundColor(.brutalBlack)
                                .lineSpacing(2)
                        }
                        .padding(.horizontal, 24)
                    }
                }

                // Connections
                if let connections = lesson.connections, !connections.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connections")
                            .font(.system(.caption, design: .default, weight: .medium))
                            .foregroundColor(.brutalBlack)
                            .padding(.horizontal, 24)

                        FlowLayout(spacing: 8) {
                            ForEach(connections, id: \.self) { connection in
                                BrutalChip(title: connection, color: .brutalMint) {}
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Spacer().frame(height: 8)

                // Start Drilling Button
                BrutalButton(title: "Start Quiz", color: .brutalYellow, fullWidth: true) {
                    onStartDrilling()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
