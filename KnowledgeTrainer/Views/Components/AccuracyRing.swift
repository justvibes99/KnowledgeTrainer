import SwiftUI

struct AccuracyRing: View {
    let accuracy: Double
    var size: CGFloat = 80
    var lineWidth: CGFloat = 8

    var ringColor: Color {
        if accuracy < 40 { return .brutalCoral }
        if accuracy < 70 { return .brutalYellow }
        return .brutalTeal
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.brutalBlack.opacity(0.1), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: accuracy / 100)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            Text("\(Int(accuracy))%")
                .font(.system(.caption, design: .default, weight: .bold))
                .foregroundColor(.brutalBlack)
        }
    }
}

struct CompletionRing: View {
    let completed: Int
    let total: Int
    var size: CGFloat = 50
    var lineWidth: CGFloat = 5

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    private var ringColor: Color {
        if fraction >= 1.0 { return .brutalTeal }
        if fraction > 0 { return .brutalYellow }
        return .brutalBlack.opacity(0.3)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.brutalBlack.opacity(0.1), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            Text("\(completed)/\(total)")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundColor(.brutalBlack)
        }
    }
}
