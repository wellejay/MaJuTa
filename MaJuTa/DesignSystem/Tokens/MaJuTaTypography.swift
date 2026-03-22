import SwiftUI

// MARK: - Font Extensions
extension Font {
    // Large Financial Numbers
    static let maJuTaHero        = Font.system(size: 40, weight: .bold, design: .rounded)
    static let maJuTaLargeNumber = Font.system(size: 34, weight: .bold, design: .rounded)
    static let maJuTaMediumNumber = Font.system(size: 28, weight: .semibold, design: .rounded)

    // Headers
    static let maJuTaTitle1      = Font.system(size: 28, weight: .bold, design: .default)
    static let maJuTaTitle2      = Font.system(size: 22, weight: .bold, design: .default)
    static let maJuTaSectionTitle = Font.system(size: 20, weight: .semibold, design: .default)

    // Body
    static let maJuTaBody        = Font.system(size: 16, weight: .regular, design: .default)
    static let maJuTaBodyMedium  = Font.system(size: 16, weight: .medium, design: .default)
    static let maJuTaBodyBold    = Font.system(size: 16, weight: .semibold, design: .default)

    // CTA / primary button label
    static let maJuTaButton      = Font.system(size: 16, weight: .semibold, design: .default)

    // Supporting
    static let maJuTaSubheadline = Font.system(size: 15, weight: .medium, design: .default)
    static let maJuTaCaption     = Font.system(size: 13, weight: .regular, design: .default)
    static let maJuTaCaptionMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let maJuTaFootnote    = Font.system(size: 12, weight: .regular, design: .default)
    static let maJuTaLabel       = Font.system(size: 11, weight: .medium, design: .default)
}

// MARK: - Text Style Modifier
struct MaJuTaTextStyle: ViewModifier {
    let font: Font
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
    }
}
