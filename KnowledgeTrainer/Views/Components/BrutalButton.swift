import SwiftUI

struct BrutalButton: View {
    let title: String
    var color: Color = .brutalYellow
    var gradient: LinearGradient? = nil
    var fullWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            action()
        }) {
            Text(title)
                .font(.system(.body, design: .monospaced, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background {
                    if let gradient {
                        gradient
                    } else {
                        color
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct BrutalButtonAsync: View {
    let title: String
    var color: Color = .brutalYellow
    var gradient: LinearGradient? = nil
    var fullWidth: Bool = false
    let action: () async -> Void

    var body: some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            Task { await action() }
        }) {
            Text(title)
                .font(.system(.body, design: .monospaced, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background {
                    if let gradient {
                        gradient
                    } else {
                        color
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
