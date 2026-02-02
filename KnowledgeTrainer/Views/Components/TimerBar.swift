import SwiftUI

struct TimerBar: View {
    let remaining: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(remaining) / Double(total)
    }

    var barColor: Color {
        if progress > 0.5 { return .brutalTeal }
        if progress > 0.25 { return .brutalSalmon }
        return .brutalCoral
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.flatSurfaceSubtle)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geometry.size.width * progress)
                        .animation(.linear(duration: 1), value: remaining)
                }
            }
            .frame(height: 8)

            Text("\(remaining)s")
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .foregroundColor(.flatSecondaryText)
        }
    }
}
