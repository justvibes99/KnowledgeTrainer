import SwiftUI

struct BrutalButton: View {
    let title: String
    var color: Color = .brutalYellow
    var fullWidth: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            action()
        }) {
            Text(title)
                .font(.system(.body, design: .default, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(.brutalBlack)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(color)
                .overlay(
                    Rectangle()
                        .stroke(Color.brutalBlack, lineWidth: 3)
                )
                .offset(x: isPressed ? 4 : 0, y: isPressed ? 4 : 0)
                .background(
                    Rectangle()
                        .fill(Color.brutalBlack)
                        .offset(x: 4, y: 4)
                )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct BrutalButtonAsync: View {
    let title: String
    var color: Color = .brutalYellow
    var fullWidth: Bool = false
    let action: () async -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            Task { await action() }
        }) {
            Text(title)
                .font(.system(.body, design: .default, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(.brutalBlack)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(color)
                .overlay(
                    Rectangle()
                        .stroke(Color.brutalBlack, lineWidth: 3)
                )
                .offset(x: isPressed ? 4 : 0, y: isPressed ? 4 : 0)
                .background(
                    Rectangle()
                        .fill(Color.brutalBlack)
                        .offset(x: 4, y: 4)
                )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
