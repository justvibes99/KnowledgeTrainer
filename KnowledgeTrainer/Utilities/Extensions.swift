import SwiftUI

// MARK: - Colors

extension Color {
    static let brutalBackground = Color(hex: "FFF8E7")
    static let brutalBlack = Color(hex: "000000")
    static let brutalCoral = Color(hex: "FF6B6B")
    static let brutalTeal = Color(hex: "4ECDC4")
    static let brutalYellow = Color(hex: "FFE66D")
    static let brutalLavender = Color(hex: "AA96DA")
    static let brutalMint = Color(hex: "95E1D3")
    static let brutalSalmon = Color(hex: "F38181")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Formatting

extension Date {
    var relativeDisplay: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: self)
        }
    }

    var shortDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}

// MARK: - View Modifiers

struct BrutalCardModifier: ViewModifier {
    var backgroundColor: Color = .white
    var shadowSize: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .overlay(
                Rectangle()
                    .stroke(Color.brutalBlack, lineWidth: 3)
            )
            .background(
                Rectangle()
                    .fill(Color.brutalBlack)
                    .offset(x: shadowSize, y: shadowSize)
            )
    }
}

extension View {
    func brutalCard(backgroundColor: Color = .white, shadowSize: CGFloat = 8) -> some View {
        modifier(BrutalCardModifier(backgroundColor: backgroundColor, shadowSize: shadowSize))
    }
}
