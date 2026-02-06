import SwiftUI

struct LevelUpOverlay: View {
    let rank: ScholarRank
    let totalXP: Int
    var onDismiss: () -> Void

    @State private var showContent = false
    @State private var iconScale: CGFloat = 0.3

    var body: some View {
        ZStack {
            Color.brutalBlack.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 24) {
                Spacer()

                if showContent {
                    Image(systemName: rank.iconName)
                        .font(.system(size: 72, weight: .medium))
                        .foregroundStyle(Color.brutalOnAccent)
                        .frame(width: 120, height: 120)
                        .background(rank.color)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .scaleEffect(iconScale)

                    Text("Rank Up!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color.brutalBlack)

                    Text(rank.title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.brutalOnAccent)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.brutalYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    XPProgressBar(currentXP: totalXP, rank: rank)
                        .padding(.horizontal, 40)

                    BrutalButton(title: "Continue", color: .brutalYellow) {
                        dismiss()
                    }
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding(32)
            .background(Color.flatSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 8)
            .padding(.horizontal, 32)
        }
        .onAppear {
            HapticManager.impact(style: .heavy)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showContent = true
                iconScale = 1.0
            }
        }
    }

    private func dismiss() {
        HapticManager.impact(style: .medium)
        onDismiss()
    }
}
