import Foundation

struct Transaction: Identifiable, Codable {
    let id: UUID
    var amount: Double
    var currency: String
    var date: Date
    var categoryId: UUID
    var accountId: UUID
    var merchant: String
    var paymentMethod: PaymentMethod
    var note: String
    var tags: [String]
    var isRecurring: Bool
    var recurringId: UUID?
    var invoiceId: UUID?
    var ownerUserId: UUID
    var createdByUserId: UUID
    var syncStatus: SyncStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        amount: Double,
        currency: String = "SAR",
        date: Date = Date(),
        categoryId: UUID,
        accountId: UUID,
        merchant: String = "",
        paymentMethod: PaymentMethod = .cash,
        note: String = "",
        tags: [String] = [],
        isRecurring: Bool = false,
        recurringId: UUID? = nil,
        invoiceId: UUID? = nil,
        ownerUserId: UUID,
        createdByUserId: UUID,
        syncStatus: SyncStatus = .localOnly,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.date = date
        self.categoryId = categoryId
        self.accountId = accountId
        self.merchant = merchant
        self.paymentMethod = paymentMethod
        self.note = note
        self.tags = tags
        self.isRecurring = isRecurring
        self.recurringId = recurringId
        self.invoiceId = invoiceId
        self.ownerUserId = ownerUserId
        self.createdByUserId = createdByUserId
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum PaymentMethod: String, Codable, CaseIterable {
    case applePay     = "apple_pay"
    case mada         = "mada"
    case creditCard   = "credit_card"
    case bankTransfer = "bank_transfer"
    case sadad        = "sadad"
    case cash         = "cash"
    case bnpl         = "bnpl"

    var displayName: String {
        switch self {
        case .applePay:     return "Apple Pay"
        case .mada:         return "مدى"
        case .creditCard:   return "بطاقة ائتمان"
        case .bankTransfer: return "تحويل بنكي"
        case .sadad:        return "سداد"
        case .cash:         return "نقد"
        case .bnpl:         return "تقسيط"
        }
    }

    var icon: String {
        switch self {
        case .applePay:     return "apple.logo"
        case .mada:         return "creditcard.fill"
        case .creditCard:   return "creditcard"
        case .bankTransfer: return "building.columns.fill"
        case .sadad:        return "qrcode"
        case .cash:         return "banknote.fill"
        case .bnpl:         return "calendar.badge.plus"
        }
    }
}
