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
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.brutalBlack)
                        .frame(width: 48, height: 48)
                        .background(Color.brutalYellow)
                        .overlay(
                            Rectangle()
                                .stroke(Color.brutalBlack, lineWidth: 3)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ACHIEVEMENT UNLOCKED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(1.5)
                            .foregroundStyle(Color.brutalBlack.opacity(0.6))

                        Text(achievement.name.uppercased())
                            .font(.subheadline)
                            .fontWeight(.black)
                            .tracking(1)
                            .foregroundStyle(Color.brutalBlack)

                        Text("+\(achievement.xpReward) XP")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.brutalTeal)
                    }

                    Spacer()
                }
                .padding(16)
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
