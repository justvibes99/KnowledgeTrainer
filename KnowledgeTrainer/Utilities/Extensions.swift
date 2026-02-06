import SwiftUI

// MARK: - Colors

extension UIColor {
    convenience init(hex: String) {
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
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}

extension Color {
    init(lightHex: String, darkHex: String) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: darkHex) : UIColor(hex: lightHex)
        })
    }

    // Primary palette — adaptive
    static let brutalBackground = Color(lightHex: "F7F5F0", darkHex: "1A1A1A")
    static let brutalBlack = Color(lightHex: "1A1A1A", darkHex: "F0EDE6")
    static let brutalCoral = Color(lightHex: "E05A4E", darkHex: "F07066")
    static let brutalTeal = Color(lightHex: "5BA8A0", darkHex: "6BC4BA")
    static let brutalYellow = Color(lightHex: "6C5CE7", darkHex: "8B7FF0")
    static let brutalLavender = Color(lightHex: "5B7FA5", darkHex: "7094B8")
    static let brutalMint = Color(lightHex: "5A8A6C", darkHex: "6DA07E")
    static let brutalSalmon = Color(lightHex: "C9963A", darkHex: "D4A550")
    static let brutalIndigo = Color(lightHex: "4A5899", darkHex: "6070B0")
    static let brutalAmber = Color(lightHex: "D4915A", darkHex: "DCA06E")

    // Surface tokens — adaptive
    static let flatSurface = Color(lightHex: "FDFCF9", darkHex: "2A2A2A")
    static let flatSurfaceSubtle = Color(lightHex: "F0EDE6", darkHex: "333333")
    static let flatSecondaryText = Color(lightHex: "6B6560", darkHex: "A09890")
    static let flatTertiaryText = Color(lightHex: "9C9690", darkHex: "787070")
    static let flatBorder = Color(lightHex: "E8E4DE", darkHex: "444444")
    static let flatBorderStrong = Color(lightHex: "D1CCC4", darkHex: "555555")
    static let flatPrimaryHover = Color(lightHex: "5A4BD4", darkHex: "7060E0")
    static let flatPrimaryActive = Color(lightHex: "4A3DC0", darkHex: "6050D0")

    // Semantic tokens — adaptive
    static let brutalSurface = Color(lightHex: "FFFFFF", darkHex: "2A2A2A")
    static let brutalOnAccent = Color.white  // White text on accent backgrounds stays white
    static let flatDashboardCard = Color(lightHex: "EAE7E1", darkHex: "3A3A3A")

    // Legacy hex init (non-adaptive, for one-off colors)
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

// MARK: - Appearance Mode

func applyAppearanceMode() {
    let mode = UserDefaults.standard.string(forKey: "appearanceMode") ?? "System"
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = scene.windows.first else { return }

    switch mode {
    case "Light":
        window.overrideUserInterfaceStyle = .light
    case "Dark":
        window.overrideUserInterfaceStyle = .dark
    default:
        window.overrideUserInterfaceStyle = .unspecified
    }
}
