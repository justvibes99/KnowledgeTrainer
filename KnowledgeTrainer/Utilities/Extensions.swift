import SwiftUI

// MARK: - Colors

extension Color {
    static let brutalBackground = Color(hex: "F7F5F0")
    static let brutalBlack = Color(hex: "1A1A1A")
    static let brutalCoral = Color(hex: "C25B4E")
    static let brutalTeal = Color(hex: "5BA8A0")
    static let brutalYellow = Color(hex: "6C5CE7")
    static let brutalLavender = Color(hex: "5B7FA5")
    static let brutalMint = Color(hex: "5A8A6C")
    static let brutalSalmon = Color(hex: "C9963A")

    // New design tokens
    static let flatSurface = Color(hex: "FDFCF9")
    static let flatSurfaceSubtle = Color(hex: "F0EDE6")
    static let flatSecondaryText = Color(hex: "6B6560")
    static let flatTertiaryText = Color(hex: "9C9690")
    static let flatBorder = Color(hex: "E8E4DE")
    static let flatBorderStrong = Color(hex: "D1CCC4")
    static let flatPrimaryHover = Color(hex: "5A4BD4")
    static let flatPrimaryActive = Color(hex: "4A3DC0")

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
    var backgroundColor: Color = .flatSurface
    var shadowSize: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.flatBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func brutalCard(backgroundColor: Color = .flatSurface, shadowSize: CGFloat = 8) -> some View {
        modifier(BrutalCardModifier(backgroundColor: backgroundColor, shadowSize: shadowSize))
    }
}
