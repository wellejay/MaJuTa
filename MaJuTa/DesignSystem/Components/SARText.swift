import SwiftUI

// MARK: - Saudi Riyal Symbol Font
// Font family: "saudi_riyal", PostScript name: "saudi_riyalregular"
// U+E900 = private-use riyal glyph (works on all iOS versions)
private let riyalFontName = "saudi_riyalregular"
private let riyalChar = "\u{E900}"

// MARK: - SARText View
/// Renders a Saudi Riyal amount using the official Saudi Riyal symbol font.
/// The ﷼ symbol uses saudi_riyalregular; the number inherits the system font.
struct SARText: View {
    let amount: Double
    let size: CGFloat
    let weight: Font.Weight
    let color: Color
    var compact: Bool = false

    init(
        _ amount: Double,
        size: CGFloat = 16,
        weight: Font.Weight = .regular,
        color: Color = .maJuTaTextPrimary,
        compact: Bool = false
    ) {
        self.amount = amount
        self.size = size
        self.weight = weight
        self.color = color
        self.compact = compact
    }

    var body: some View {
        (Text(riyalChar)
            .font(.custom(riyalFontName, size: size))
         + Text(compact ? amount.sarCompactNumber : amount.sarNumber)
            .font(.system(size: size, weight: weight, design: .rounded)))
        .foregroundColor(color)
    }
}

// MARK: - Convenience Presets
extension SARText {
    static func hero(_ amount: Double, color: Color = .maJuTaTextPrimary) -> SARText {
        SARText(amount, size: 40, weight: .bold, color: color)
    }
    static func largeNumber(_ amount: Double, color: Color = .maJuTaTextPrimary) -> SARText {
        SARText(amount, size: 34, weight: .bold, color: color)
    }
    static func mediumNumber(_ amount: Double, color: Color = .maJuTaTextPrimary) -> SARText {
        SARText(amount, size: 28, weight: .semibold, color: color)
    }
    static func title(_ amount: Double, color: Color = .maJuTaTextPrimary) -> SARText {
        SARText(amount, size: 22, weight: .bold, color: color)
    }
    static func body(_ amount: Double, color: Color = .maJuTaTextPrimary) -> SARText {
        SARText(amount, size: 16, weight: .regular, color: color)
    }
    static func bodyBold(_ amount: Double, color: Color = .maJuTaTextPrimary) -> SARText {
        SARText(amount, size: 16, weight: .semibold, color: color)
    }
    static func caption(_ amount: Double, color: Color = .maJuTaTextPrimary) -> SARText {
        SARText(amount, size: 13, weight: .regular, color: color)
    }
    static func compact(_ amount: Double, size: CGFloat = 14, color: Color = .maJuTaTextPrimary) -> SARText {
        SARText(amount, size: size, weight: .semibold, color: color, compact: true)
    }

    // Auto-color: green if positive/zero, red if negative
    static func signed(_ amount: Double, size: CGFloat = 16, weight: Font.Weight = .semibold) -> SARText {
        SARText(amount, size: size, weight: weight, color: amount >= 0 ? .maJuTaPositive : .maJuTaNegative)
    }
    static func signedHero(_ amount: Double) -> SARText {
        SARText(amount, size: 40, weight: .bold, color: amount >= 0 ? .maJuTaPositive : .maJuTaNegative)
    }
    static func signedMedium(_ amount: Double) -> SARText {
        SARText(amount, size: 28, weight: .semibold, color: amount >= 0 ? .maJuTaPositive : .maJuTaNegative)
    }
    static func signedCompact(_ amount: Double) -> SARText {
        SARText(amount, size: 14, weight: .semibold, color: amount >= 0 ? .maJuTaPositive : .maJuTaNegative, compact: true)
    }
}
