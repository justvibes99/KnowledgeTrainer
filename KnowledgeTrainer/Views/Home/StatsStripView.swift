import SwiftUI

struct StatsStripView: View {
    let totalQuestions: Int
    let accuracy: Double
    let streak: Int
    let dueReviews: Int

    var body: some View {
        HStack(spacing: 0) {
            stripItem(value: "\(totalQuestions)", label: "QS")
            stripDivider
            stripItem(value: "\(Int(accuracy))%", label: "ACC")
            stripDivider
            stripItem(value: "\(streak)d", label: "STREAK")
            stripDivider
            stripItem(
                value: "\(dueReviews)",
                label: "REVIEW",
                highlight: dueReviews > 0
            )
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white)
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

    @ViewBuilder
    private func stripItem(value: String, label: String, highlight: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.body, design: .monospaced, weight: .bold))
                .foregroundColor(highlight ? .brutalCoral : .brutalBlack)
            Text(label)
                .font(.system(.caption2, design: .default, weight: .bold))
                .tracking(0.8)
                .foregroundColor(.brutalBlack.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var stripDivider: some View {
        Rectangle()
            .fill(Color.brutalBlack.opacity(0.15))
            .frame(width: 2, height: 28)
    }
}
