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
                Color.brutalBlack.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if secondaryButton != nil {
                            isPresented = false
                        }
                    }

                VStack(spacing: 20) {
                    Text(title)
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundColor(.brutalBlack)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(.flatSecondaryText)
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
                                color: .flatSurfaceSubtle,
                                fullWidth: true
                            ) {
                                secondary.action()
                                isPresented = false
                            }
                        }
                    }
                }
                .padding(24)
                .background(Color.flatSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.flatBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
                .padding(.horizontal, 32)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
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
