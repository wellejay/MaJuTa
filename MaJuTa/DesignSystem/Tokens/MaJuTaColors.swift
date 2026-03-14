import SwiftUI
import UIKit

extension Color {
    // MARK: - Brand (fixed — used as accents, not backgrounds)
    static let maJuTaPrimary     = Color(hex: "#0C2031")
    static let maJuTaGold        = Color(hex: "#F2AE2E")
    static let maJuTaOrange      = Color(hex: "#F27F1B")

    // MARK: - Semantic (fixed)
    static let maJuTaPositive    = Color(hex: "#22C55E")
    static let maJuTaNegative    = Color(hex: "#EF4444")
    static let maJuTaWarning     = Color(hex: "#F59E0B")

    // MARK: - Adaptive Backgrounds
    /// Page background: light #F6F7F9 / dark #0A0F14
    static let maJuTaBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(hex: "#0A0F14")
            : UIColor(hex: "#F6F7F9")
    })

    /// Card surface: light #FFFFFF / dark #0F1C29
    static let maJuTaCard = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(hex: "#0F1C29")
            : UIColor(hex: "#FFFFFF")
    })

    /// Elevated surface (modals, sheets): light #F0F2F5 / dark #162233
    static let maJuTaSurface = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(hex: "#162233")
            : UIColor(hex: "#F0F2F5")
    })
    static let maJuTaSurfaceElevated = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(hex: "#1C2D40")
            : UIColor(hex: "#E8EBF0")
    })

    // MARK: - Adaptive Text
    /// Primary text: light #1A1A1A / dark #EFF2F5
    static let maJuTaTextPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(hex: "#EFF2F5")
            : UIColor(hex: "#1A1A1A")
    })
    /// Secondary text: light #6B7280 / dark #8B9BAD
    static let maJuTaTextSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(hex: "#8B9BAD")
            : UIColor(hex: "#6B7280")
    })

    // MARK: - Dark Mode Navy Gradient (fixed — header always navy)
    static let navyGradientStart  = Color(hex: "#0C2031")
    static let navyGradientEnd    = Color(hex: "#1A3A52")
}

// MARK: - UIColor hex initializer (for dynamic provider)
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8)  & 0xFF) / 255
        let b = CGFloat(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let navyGradient = LinearGradient(
        colors: [Color(hex: "#0C2031"), Color(hex: "#1A3A52")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [Color(hex: "#F2AE2E"), Color(hex: "#F27F1B")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let greenGradient = LinearGradient(
        colors: [Color(hex: "#22C55E"), Color(hex: "#16A34A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.95)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Hex Initializer
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
            (a, r, g, b) = (1, 1, 1, 0)
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
