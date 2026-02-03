import SwiftUI
import UIKit

enum ToggleAppearance {
    static func configure() {
        let offBackground = UIColor(red: 0.82, green: 0.80, blue: 0.77, alpha: 1.0) // flatBorderStrong
        UISwitch.appearance().subviews.forEach { view in
            view.clipsToBounds = true
        }
        UISwitch.appearance().onTintColor = UIColor(red: 0.36, green: 0.66, blue: 0.63, alpha: 1.0) // brutalTeal
        UISwitch.appearance().backgroundColor = offBackground
        UISwitch.appearance().layer.cornerRadius = 16
        UISwitch.appearance().clipsToBounds = true
    }
}
