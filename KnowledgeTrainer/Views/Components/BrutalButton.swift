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
                .font(.system(.body, design: .default, weight: .medium))
                .foregroundColor(color == .brutalYellow ? .white : .brutalBlack)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .opacity(isPressed ? 0.8 : 1.0)
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
                .font(.system(.body, design: .default, weight: .medium))
                .foregroundColor(color == .brutalYellow ? .white : .brutalBlack)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .opacity(isPressed ? 0.8 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
