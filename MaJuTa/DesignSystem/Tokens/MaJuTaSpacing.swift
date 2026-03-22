import SwiftUI

// MARK: - 8pt Spacing System
enum MaJuTaSpacing {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48

    // Micro spacing — named to avoid magic numbers in components
    static let hairline: CGFloat = 1   // hairline row separator (card bg shows through)
    static let tight: CGFloat    = 2   // tight label/sublabel pair spacing within cells

    // iOS Safe Area Margins
    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24

    // Component sizing
    static let iconBadge: CGFloat    = 40   // category/status icon badge in list rows
    static let iconBadgeLg: CGFloat  = 44   // larger icon badge (equals min touch target)
    static let pinButtonSize: CGFloat = 72  // PIN pad digit button size

    // Corner Radius
    static let radiusSm: CGFloat  = 8
    static let radiusMd: CGFloat  = 12
    static let radiusLg: CGFloat  = 16
    static let radiusXl: CGFloat  = 20
    static let radiusXxl: CGFloat = 24
    static let radiusFull: CGFloat = 999
}

// MARK: - Corner Radius Enum
enum MaJuTaRadius {
    static let card: CGFloat   = 20
    static let button: CGFloat = 14
    static let chip: CGFloat   = 10
    static let input: CGFloat  = 12
    static let small: CGFloat  = 8
}

// MARK: - Shadow Styles
extension View {
    func maJuTaCardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
    }

    func maJuTaSmallShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
