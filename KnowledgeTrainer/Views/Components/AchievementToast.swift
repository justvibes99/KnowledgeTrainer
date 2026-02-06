import SwiftUI

struct AchievementToast: View {
    let achievement: AchievementDefinition
    var onDismiss: () -> Void = {}

    @State private var isVisible = false

    var body: some View {
        VStack {
            if isVisible {
                HStack(spacing: 12) {
                    Image(systemName: achievement.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.brutalOnAccent)
                        .frame(width: 48, height: 48)
                        .background(Color.brutalYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Achievement Unlocked")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.flatSecondaryText)

                        Text(achievement.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.brutalBlack)

                        Text("+\(achievement.xpReward) XP")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.brutalTeal)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color.flatSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.flatBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
    }
}
