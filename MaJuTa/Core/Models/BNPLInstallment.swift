import Foundation

struct InstallmentPlan: Identifiable, Codable {
    let id: UUID
    var merchant: String
    var provider: BNPLProvider
    var totalAmount: Double
    var installmentsCount: Int
    var startDate: Date
    var paymentMethod: PaymentMethod
    var ownerUserId: UUID
    var syncStatus: SyncStatus
    var createdAt: Date

    init(
        id: UUID = UUID(),
        merchant: String,
        provider: BNPLProvider,
        totalAmount: Double,
        installmentsCount: Int,
        startDate: Date = Date(),
        paymentMethod: PaymentMethod = .bnpl,
        ownerUserId: UUID,
        syncStatus: SyncStatus = .localOnly,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.merchant = merchant
        self.provider = provider
        self.totalAmount = totalAmount
        self.installmentsCount = installmentsCount
        self.startDate = startDate
        self.paymentMethod = paymentMethod
        self.ownerUserId = ownerUserId
        self.syncStatus = syncStatus
        self.createdAt = createdAt
    }

    var installmentAmount: Double {
        guard installmentsCount > 0 else { return 0 }
        return totalAmount / Double(installmentsCount)
    }
}

struct Installment: Identifiable, Codable {
    let id: UUID
    var planId: UUID
    var amount: Double
    var dueDate: Date
    var status: InstallmentStatus
    var paidDate: Date?

    init(
        id: UUID = UUID(),
        planId: UUID,
        amount: Double,
        dueDate: Date,
        status: InstallmentStatus = .upcoming
    ) {
        self.id = id
        self.planId = planId
        self.amount = amount
        self.dueDate = dueDate
        self.status = status
    }

    var isOverdue: Bool { dueDate < Date() && status == .upcoming }
}

enum InstallmentStatus: String, Codable {
    case upcoming = "upcoming"
    case paid     = "paid"
    case overdue  = "overdue"

    var displayName: String {
        let isEn = UserDefaults.standard.string(forKey: "appLanguage") == "en"
        switch self {
        case .upcoming: return isEn ? "Upcoming" : "قادم"
        case .paid:     return isEn ? "Paid"     : "مدفوع"
        case .overdue:  return isEn ? "Overdue"  : "متأخر"
        }
    }
}

enum BNPLProvider: String, Codable, CaseIterable {
    case tabby   = "tabby"
    case tamara  = "tamara"
    case postpay = "postpay"
    case other   = "other"

    var displayName: String {
        let isEn = UserDefaults.standard.string(forKey: "appLanguage") == "en"
        switch self {
        case .tabby:   return "Tabby"
        case .tamara:  return "Tamara"
        case .postpay: return "PostPay"
        case .other:   return isEn ? "Other" : "أخرى"
        }
    }

    var logoColor: String {
        switch self {
        case .tabby:   return "#3DBDB2"
        case .tamara:  return "#FF5FA0"
        case .postpay: return "#0052CC"
        case .other:   return "#6B7280"
        }
    }
}
