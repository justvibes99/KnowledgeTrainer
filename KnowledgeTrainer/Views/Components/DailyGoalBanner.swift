import SwiftUI

struct DailyGoalBanner: View {
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.seal.fill" : "target")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.brutalBlack)

            VStack(alignment: .leading, spacing: 2) {
                Text("DAILY GOAL")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1.5)
                    .foregroundStyle(Color.brutalBlack)

                Text(isCompleted ? "Subtopic mastered today!" : "Master 1 subtopic today")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brutalBlack)
            }

            Spacer()

            if isCompleted {
                Text("DONE")
                    .font(.caption)
                    .fontWeight(.black)
                    .tracking(1.5)
                    .foregroundStyle(Color.brutalBlack)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.4))
                    .overlay(
                        Rectangle()
                            .stroke(Color.brutalBlack, lineWidth: 2)
                    )
            }
        }
        .padding(16)
        .background(isCompleted ? Color.brutalTeal : Color.brutalCoral)
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
