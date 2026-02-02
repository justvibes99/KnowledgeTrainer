import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarded: Bool

    var body: some View {
        ZStack {
            Color.brutalBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)

                    VStack(spacing: 8) {
                        Text("Snap")
                            .font(.system(size: 42, weight: .semibold, design: .monospaced))
                            .foregroundColor(.brutalBlack)
                        Text("Study")
                            .font(.system(size: 42, weight: .semibold, design: .monospaced))
                            .foregroundColor(.brutalYellow)
                    }

                    BrutalCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Welcome")
                                .font(.system(.title3, design: .monospaced, weight: .semibold))
                                .foregroundColor(.brutalBlack)

                            Text("Learn any topic through AI-generated quizzes and spaced repetition. Pick a subject and start studying.")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.brutalBlack)

                            BrutalButton(title: "Get Started", color: .brutalYellow, fullWidth: true) {
                                isOnboarded = true
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
        }
    }
}
