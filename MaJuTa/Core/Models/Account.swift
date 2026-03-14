import Foundation

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
}

enum AccountType: String, Codable, CaseIterable {
    case bank       = "bank"
    case wallet     = "wallet"
    case savings    = "savings"
    case investment = "investment"
    case cash       = "cash"

    var displayName: String {
        switch self {
        case .bank:       return "حساب بنكي"
        case .wallet:     return "محفظة إلكترونية"
        case .savings:    return "حساب توفير"
        case .investment: return "حساب استثماري"
        case .cash:       return "نقد"
        }
    }

    var icon: String {
        switch self {
        case .bank:       return "building.columns.fill"
        case .wallet:     return "wallet.pass.fill"
        case .savings:    return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .cash:       return "banknote"
        }
    }
}

enum SyncStatus: String, Codable {
    case localOnly    = "LOCAL_ONLY"
    case syncPending  = "SYNC_PENDING"
    case synced       = "SYNCED"
    case conflict     = "CONFLICT"
}
