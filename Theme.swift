import UIKit
import SwiftUI

// MARK: - Hex helper

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

/// Palet: "kreatin tozu + su". Tebeşirimsi soğuk beyaz zemin, grafit metin,
/// hidrasyonu temsil eden doygun kobalt vurgu, loading fazı için kum sarısı.
enum CT {
    static let bg        = Color.adaptive(light: 0xEDEFF1, dark: 0x14171B)
    static let surface   = Color.adaptive(light: 0xFFFFFF, dark: 0x1E2228)
    static let ink       = Color.adaptive(light: 0x1B1F24, dark: 0xF2F4F6)
    static let inkSoft   = Color.adaptive(light: 0x6B747E, dark: 0x939CA6)
    static let hairline  = Color.adaptive(light: 0xD7DCE1, dark: 0x2C323A)

    static let accent    = Color.adaptive(light: 0x2F5BEA, dark: 0x5C86FF)
    static let accentSoft = Color.adaptive(light: 0xDCE4FD, dark: 0x22304F)

    static let loading   = Color.adaptive(light: 0xC98A2B, dark: 0xE0A44A)
    static let loadingSoft = Color.adaptive(light: 0xF6E7CC, dark: 0x3A2E1B)

    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Double {
    /// 5.0 -> "5", 2.5 -> "2.5"
    var gramString: String {
        self == rounded() ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
