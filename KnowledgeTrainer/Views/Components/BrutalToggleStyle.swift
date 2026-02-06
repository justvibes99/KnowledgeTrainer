import SwiftUI
import UIKit

enum ToggleAppearance {
    static func configure() {
        let offBackground = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1.0) // dark: #555555
                : UIColor(red: 0.82, green: 0.80, blue: 0.77, alpha: 1.0) // light: flatBorderStrong
        }
        UISwitch.appearance().onTintColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.42, green: 0.77, blue: 0.73, alpha: 1.0) // dark: #6BC4BA
                : UIColor(red: 0.36, green: 0.66, blue: 0.63, alpha: 1.0) // light: brutalTeal
        }
        UISwitch.appearance().backgroundColor = offBackground
        UISwitch.appearance().layer.cornerRadius = 16
        UISwitch.appearance().clipsToBounds = true
    }
}
