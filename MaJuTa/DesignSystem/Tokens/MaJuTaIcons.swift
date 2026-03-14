import SwiftUI

// MARK: - Category Icons
enum CategoryIcon {
    // Income
    static let salary        = "briefcase.fill"
    static let sideIncome    = "bolt.fill"
    static let rentalIncome  = "building.2.fill"
    static let dividends     = "chart.pie.fill"
    static let refunds       = "arrow.uturn.left.circle.fill"

    // Essential Expenses
    static let rent          = "house.fill"
    static let utilities     = "bolt.horizontal.fill"
    static let groceries     = "cart.fill"
    static let fuel          = "fuelpump.fill"
    static let telecom       = "phone.fill"
    static let healthcare    = "cross.fill"
    static let insurance     = "shield.fill"
    static let education     = "book.fill"
    static let domesticWorker = "person.fill"
    static let loans         = "banknote.fill"

    // Lifestyle
    static let restaurants   = "fork.knife"
    static let shopping      = "bag.fill"
    static let entertainment = "play.circle.fill"
    static let travel        = "airplane"
    static let fitness       = "figure.run"

    // Family
    static let kids          = "figure.and.child.holdinghands"
    static let parentsSupport = "heart.fill"
    static let gifts         = "gift.fill"

    // Financial
    static let savings       = "banknote"
    static let investments   = "chart.line.uptrend.xyaxis"
    static let emergencyFund = "exclamationmark.shield.fill"
    static let debtRepayment = "arrow.down.circle.fill"
}

// MARK: - Payment Method Icons
enum PaymentIcon {
    static let applePay      = "apple.logo"
    static let mada          = "creditcard.fill"
    static let creditCard    = "creditcard"
    static let bankTransfer  = "building.columns.fill"
    static let sadad         = "qrcode"
    static let cash          = "banknote.fill"
    static let bnpl          = "calendar.badge.plus"
}

// MARK: - Navigation Icons
enum NavIcon {
    static let dashboard     = "house.fill"
    static let transactions  = "arrow.left.arrow.right"
    static let goals         = "target"
    static let investments   = "chart.line.uptrend.xyaxis"
    static let profile       = "person.fill"
}

// MARK: - Action Icons
enum ActionIcon {
    static let add           = "plus"
    static let scan          = "camera.viewfinder"
    static let filter        = "line.3.horizontal.decrease.circle"
    static let search        = "magnifyingglass"
    static let notification  = "bell.fill"
    static let settings      = "gearshape.fill"
    static let share         = "square.and.arrow.up"
    static let edit          = "pencil"
    static let delete        = "trash"
    static let chevronRight  = "chevron.left" // RTL
    static let back          = "chevron.right" // RTL
}
