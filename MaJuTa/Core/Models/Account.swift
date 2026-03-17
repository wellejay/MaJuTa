import Foundation

// MARK: - Account Group (COA hierarchy: Assets vs Liabilities)
enum AccountGroup: String, Codable {
    case asset     = "asset"
    case liability = "liability"
}

struct Account: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: AccountType
    var balance: Double
    var currency: String
    var institution: String
    var ownerUserId: UUID
    var householdId: UUID
    var isShared: Bool
    var syncStatus: SyncStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        balance: Double = 0,
        currency: String = "SAR",
        institution: String = "",
        ownerUserId: UUID,
        householdId: UUID,
        isShared: Bool = false,
        syncStatus: SyncStatus = .localOnly,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.currency = currency
        self.institution = institution
        self.ownerUserId = ownerUserId
        self.householdId = householdId
        self.isShared = isShared
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isLiquid: Bool {
        switch type {
        case .bank, .wallet, .cash: return true
        default: return false
        }
    }

    /// Whether this account represents a debt/obligation (liability in COA terms)
    var isLiability: Bool {
        switch type {
        case .creditCard, .loan: return true
        default: return false
        }
    }

    var accountGroup: AccountGroup { isLiability ? .liability : .asset }
}

enum AccountType: String, Codable, CaseIterable {
    // Assets
    case bank        = "bank"
    case wallet      = "wallet"
    case savings     = "savings"
    case investment  = "investment"
    case cash        = "cash"
    // Liabilities
    case creditCard  = "credit_card"
    case loan        = "loan"

    var displayName: String {
        let isEn = UserDefaults.standard.string(forKey: "appLanguage") == "en"
        switch self {
        case .bank:        return isEn ? "Bank Account"       : "حساب بنكي"
        case .wallet:      return isEn ? "Digital Wallet"     : "محفظة إلكترونية"
        case .savings:     return isEn ? "Savings Account"    : "حساب توفير"
        case .investment:  return isEn ? "Investment Account" : "حساب استثماري"
        case .cash:        return isEn ? "Cash"               : "نقد"
        case .creditCard:  return isEn ? "Credit Card"        : "بطاقة ائتمان"
        case .loan:        return isEn ? "Loan"               : "قرض"
        }
    }

    var icon: String {
        switch self {
        case .bank:        return "building.columns.fill"
        case .wallet:      return "wallet.pass.fill"
        case .savings:     return "banknote.fill"
        case .investment:  return "chart.line.uptrend.xyaxis"
        case .cash:        return "banknote"
        case .creditCard:  return "creditcard.fill"
        case .loan:        return "doc.plaintext.fill"
        }
    }
}

enum SyncStatus: String, Codable {
    case localOnly    = "LOCAL_ONLY"
    case syncPending  = "SYNC_PENDING"
    case synced       = "SYNCED"
    case conflict     = "CONFLICT"
}
