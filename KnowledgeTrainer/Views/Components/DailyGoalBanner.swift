import SwiftUI

struct DailyGoalBanner: View {
    let isCompleted: Bool
    var questionsToday: Int = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.seal.fill" : "target")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isCompleted ? Color.brutalOnAccent : Color.brutalBlack)

            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Goal")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isCompleted ? Color.brutalOnAccent.opacity(0.8) : Color.flatSecondaryText)

                Text(isCompleted ? "Subtopic mastered today!" : "Master 1 subtopic today")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isCompleted ? Color.brutalOnAccent : Color.brutalBlack)

                if questionsToday > 0 {
                    Text("\(questionsToday) question\(questionsToday == 1 ? "" : "s") today")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(isCompleted ? Color.brutalOnAccent.opacity(0.7) : Color.flatTertiaryText)
                }
            }

            Spacer()

            if isCompleted {
                Text("Done")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brutalOnAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.brutalOnAccent.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(16)
        .background(isCompleted ? Color.brutalTeal : Color.flatSurfaceSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCompleted ? Color.brutalTeal : Color.flatBorder, lineWidth: 1)
        )
    }
}
