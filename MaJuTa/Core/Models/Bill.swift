import Foundation

struct Bill: Identifiable, Codable {
    let id: UUID
    var name: String
    var nameArabic: String
    var amount: Double
    var currency: String
    var dueDate: Date
    var categoryId: UUID
    var accountId: UUID
    var frequency: RecurringFrequency
    var status: BillStatus
    var provider: String
    var isAutoPay: Bool
    var ownerUserId: UUID
    var syncStatus: SyncStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        nameArabic: String = "",
        amount: Double,
        currency: String = "SAR",
        dueDate: Date,
        categoryId: UUID,
        accountId: UUID,
        frequency: RecurringFrequency = .monthly,
        status: BillStatus = .upcoming,
        provider: String = "",
        isAutoPay: Bool = false,
        ownerUserId: UUID,
        syncStatus: SyncStatus = .localOnly,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.nameArabic = nameArabic
        self.amount = amount
        self.currency = currency
        self.dueDate = dueDate
        self.categoryId = categoryId
        self.accountId = accountId
        self.frequency = frequency
        self.status = status
        self.provider = provider
        self.isAutoPay = isAutoPay
        self.ownerUserId = ownerUserId
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    var isOverdue: Bool { dueDate < Date() && status != .paid }
    var isDueSoon: Bool { daysUntilDue <= 3 && daysUntilDue >= 0 }
}

enum BillStatus: String, Codable {
    case upcoming = "upcoming"
    case paid     = "paid"
    case overdue  = "overdue"

    var displayName: String {
        switch self {
        case .upcoming: return "قادم"
        case .paid:     return "مدفوع"
        case .overdue:  return "متأخر"
        }
    }
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"
    case yearly  = "yearly"
    case custom  = "custom"

    var displayName: String {
        switch self {
        case .daily:   return "يومي"
        case .weekly:  return "أسبوعي"
        case .monthly: return "شهري"
        case .yearly:  return "سنوي"
        case .custom:  return "مخصص"
        }
    }
}

// MARK: - Recurring Transaction
struct RecurringTransaction: Identifiable, Codable {
    let id: UUID
    var frequency: RecurringFrequency
    var nextDueDate: Date
    var transactionTemplate: Transaction
    var isActive: Bool
    var createdAt: Date
}
