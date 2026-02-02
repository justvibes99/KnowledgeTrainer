import SwiftUI

struct BrutalChip: View {
    let title: String
    var isSelected: Bool = false
    var color: Color = .brutalTeal
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            Text(title)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundColor(isSelected ? .white : .brutalBlack)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.flatSurfaceSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? color : Color.flatBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
