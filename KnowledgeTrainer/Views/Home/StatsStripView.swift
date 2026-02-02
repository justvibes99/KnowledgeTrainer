import SwiftUI

struct StatsStripView: View {
    let totalQuestions: Int
    let accuracy: Double
    let streak: Int
    let dueReviews: Int

    var body: some View {
        HStack(spacing: 0) {
            stripItem(value: "\(totalQuestions)", label: "Qs")
            stripDivider
            stripItem(value: "\(Int(accuracy))%", label: "Acc")
            stripDivider
            stripItem(value: "\(streak)d", label: "Streak")
            stripDivider
            stripItem(
                value: "\(dueReviews)",
                label: "Review",
                highlight: dueReviews > 0
            )
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.flatSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.flatBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func stripItem(value: String, label: String, highlight: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.body, design: .monospaced, weight: .medium))
                .foregroundColor(highlight ? .brutalCoral : .brutalBlack)
            Text(label)
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .foregroundColor(.flatSecondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var stripDivider: some View {
        Rectangle()
            .fill(Color.flatBorder)
            .frame(width: 1, height: 28)
    }
}
