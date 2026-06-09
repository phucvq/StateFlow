import SwiftUI

// MARK: - App Typography
// Display: DM Serif Display (editorial warmth)
// Body: Plus Jakarta Sans (clean, legible)
enum AppTypography {

    // MARK: - Display (DM Serif Display)
    static let titleHero = Font.custom("DMSerifDisplay-Regular", size: 42)
    static let titleLarge = Font.custom("DMSerifDisplay-Regular", size: 32)
    static let titleMedium = Font.custom("DMSerifDisplay-Regular", size: 26)
    static let timerLarge = Font.custom("DMSerifDisplay-Regular", size: 56)
    static let statValue = Font.custom("DMSerifDisplay-Regular", size: 30)

    // MARK: - Body (Plus Jakarta Sans)
    static let bodyLarge = Font.custom("PlusJakartaSans-Medium", size: 19)
    static let body = Font.custom("PlusJakartaSans-Regular", size: 17)
    static let labelMedium = Font.custom("PlusJakartaSans-SemiBold", size: 16)
    static let labelSmall = Font.custom("PlusJakartaSans-SemiBold", size: 14)
    static let caption = Font.custom("PlusJakartaSans-Regular", size: 14)
    static let overline = Font.custom("PlusJakartaSans-Bold", size: 12)
}

// MARK: - Font Registration
// If custom fonts fail to load, we fall back to system fonts
extension Font {
    static func jakartaSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold: name = "PlusJakartaSans-Bold"
        case .semibold: name = "PlusJakartaSans-SemiBold"
        case .medium: name = "PlusJakartaSans-Medium"
        default: name = "PlusJakartaSans-Regular"
        }
        return .custom(name, size: size)
    }

    static func dmSerif(_ size: CGFloat, italic: Bool = false) -> Font {
        return .custom(italic ? "DMSerifDisplay-Italic" : "DMSerifDisplay-Regular", size: size)
    }
}
