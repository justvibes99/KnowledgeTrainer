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
                .font(.system(.caption, design: .default, weight: .bold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundColor(.brutalBlack)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.brutalBlack, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}
