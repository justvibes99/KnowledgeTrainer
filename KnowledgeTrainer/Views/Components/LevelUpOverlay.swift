import SwiftUI

struct LevelUpOverlay: View {
    let rank: ScholarRank
    let totalXP: Int
    var onDismiss: () -> Void

    @State private var showContent = false
    @State private var iconScale: CGFloat = 0.3

    var body: some View {
        ZStack {
            rank.color.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 24) {
                Spacer()

                if showContent {
                    Image(systemName: rank.iconName)
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(Color.brutalBlack)
                        .frame(width: 120, height: 120)
                        .background(Color.white)
                        .overlay(
                            Rectangle()
                                .stroke(Color.brutalBlack, lineWidth: 4)
                        )
                        .background(
                            Rectangle()
                                .fill(Color.brutalBlack)
                                .offset(x: 8, y: 8)
                        )
                        .scaleEffect(iconScale)

                    Text("RANK UP!")
                        .font(.system(size: 36, weight: .black))
                        .tracking(4)
                        .foregroundStyle(Color.brutalBlack)

                    Text(rank.title.uppercased())
                        .font(.system(size: 28, weight: .black))
                        .tracking(3)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.brutalBlack)

                    XPProgressBar(currentXP: totalXP, rank: rank)
                        .padding(.horizontal, 40)

                    Button(action: dismiss) {
                        Text("CONTINUE")
                            .font(.headline)
                            .fontWeight(.black)
                            .tracking(2)
                            .foregroundStyle(Color.brutalBlack)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
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
                    .padding(.top, 8)
                }

                Spacer()
            }
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
