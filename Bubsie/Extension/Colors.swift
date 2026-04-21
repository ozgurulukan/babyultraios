import SwiftUI
import UIKit

// Retained for backward compatibility with asset catalog colors
extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let textColor        = Color("Text")
    let backgroundColor  = Color("Background")
}

// UIColor bridge
extension Color {
    init(uiColor: UIColor) {
        self.init(uiColor)
    }
}
