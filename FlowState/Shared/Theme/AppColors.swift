import SwiftUI

// MARK: - App Colors
// All colors reference Asset Catalog entries with dark/light variants.
// For now using static dark values since app forces dark mode.
enum AppColors {
    // Backgrounds
    static let night = Color(hex: "#0F0F1A")
    static let deep = Color(hex: "#1A1A2E")
    static let surface = Color(hex: "#22223A")
    static let surface2 = Color(hex: "#2D2D4A")

    // Border
    static let border = Color.white.opacity(0.08)

    // Accent
    static let amber = Color(hex: "#F4A261")
    static let amberLight = Color(hex: "#FFD4A8")
    static let sage = Color(hex: "#84A98C")
    static let sageLight = Color(hex: "#B7CEB9")
    static let indigo = Color(hex: "#6B7FD4")
    static let indigoLight = Color(hex: "#A8B4E8")
    static let rose = Color(hex: "#E07A7A")

    // Text
    static let text = Color(hex: "#F0EDE8")
    static let textMuted = Color(hex: "#F0EDE8").opacity(0.5)
    static let textDim = Color(hex: "#F0EDE8").opacity(0.28)
}

// MARK: - Color from Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
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
