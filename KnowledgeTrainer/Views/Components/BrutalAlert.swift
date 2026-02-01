import SwiftUI

struct BrutalAlert: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    var primaryButton: BrutalAlertButton
    var secondaryButton: BrutalAlertButton?

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                Color.brutalBlack.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if secondaryButton != nil {
                            isPresented = false
                        }
                    }

                VStack(spacing: 20) {
                    Text(title.uppercased())
                        .font(.system(.body, design: .default, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.brutalBlack)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(.brutalBlack)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
                        BrutalButton(
                            title: primaryButton.title,
                            color: primaryButton.isDestructive ? .brutalCoral : .brutalYellow,
                            fullWidth: true
                        ) {
                            primaryButton.action()
                            isPresented = false
                        }

                        if let secondary = secondaryButton {
                            BrutalButton(
                                title: secondary.title,
                                color: .white,
                                fullWidth: true
                            ) {
                                secondary.action()
                                isPresented = false
                            }
                        }
                    }
                }
                .padding(24)
                .background(Color.brutalBackground)
                .overlay(
                    Rectangle()
                        .stroke(Color.brutalBlack, lineWidth: 3)
                )
                .background(
                    Rectangle()
                        .fill(Color.brutalBlack)
                        .offset(x: 8, y: 8)
                )
                .padding(.horizontal, 32)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isPresented)
    }
}

struct BrutalAlertButton {
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void
}

extension View {
    func brutalAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        primaryButton: BrutalAlertButton,
        secondaryButton: BrutalAlertButton? = nil
    ) -> some View {
        self.modifier(BrutalAlert(
            isPresented: isPresented,
            title: title,
            message: message,
            primaryButton: primaryButton,
            secondaryButton: secondaryButton
        ))
    }
}
