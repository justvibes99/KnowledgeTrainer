import SwiftUI
import UIKit

enum ToggleAppearance {
    static func configure() {
        UISwitch.appearance().onTintColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.42, green: 0.77, blue: 0.73, alpha: 1.0) // dark: #6BC4BA
                : UIColor(red: 0.36, green: 0.66, blue: 0.63, alpha: 1.0) // light: brutalTeal
        }
    }
}
