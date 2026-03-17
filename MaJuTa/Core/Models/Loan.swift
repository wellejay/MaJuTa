import Foundation

struct Loan: Identifiable, Codable {
    let id: UUID
    var householdId: UUID
    var ownerUserId: UUID

    var name: String
    var loanType: LoanType

    var principalAmount: Double
    var remainingBalance: Double
    var monthlyPayment: Double
    var interestRate: Double        // Annual percentage

    var startDate: Date
    var nextPaymentDate: Date

    var isShared: Bool

    var syncStatus: SyncStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        householdId: UUID,
        ownerUserId: UUID,
        name: String,
        loanType: LoanType = .personal,
        principalAmount: Double,
        remainingBalance: Double,
        monthlyPayment: Double,
        interestRate: Double = 0,
        startDate: Date = Date(),
        nextPaymentDate: Date,
        isShared: Bool = false,
        syncStatus: SyncStatus = .localOnly,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.householdId = householdId
        self.ownerUserId = ownerUserId
        self.name = name
        self.loanType = loanType
        self.principalAmount = principalAmount
        self.remainingBalance = remainingBalance
        self.monthlyPayment = monthlyPayment
        self.interestRate = interestRate
        self.startDate = startDate
        self.nextPaymentDate = nextPaymentDate
        self.isShared = isShared
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed

    var percentagePaid: Double {
        guard principalAmount > 0 else { return 0 }
        let paid = principalAmount - remainingBalance
        return min(100, max(0, (paid / principalAmount) * 100))
    }

    var monthsRemaining: Int {
        guard monthlyPayment > 0, remainingBalance > 0 else { return 0 }
        return max(0, Int(ceil(remainingBalance / monthlyPayment)))
    }

    var estimatedPayoffDate: Date {
        Calendar.current.date(byAdding: .month, value: monthsRemaining, to: Date()) ?? Date()
    }

    var isPaymentDueSoon: Bool {
        let sevenDays = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return nextPaymentDate <= sevenDays && nextPaymentDate >= Calendar.current.startOfDay(for: Date())
    }

    var isPaymentOverdue: Bool {
        nextPaymentDate < Calendar.current.startOfDay(for: Date())
    }

    var isFullyPaid: Bool { remainingBalance <= 0 }
}

// MARK: - LoanType

enum LoanType: String, Codable, CaseIterable {
    case house    = "house"
    case car      = "car"
    case personal = "personal"
    case other    = "other"

    var displayNameArabic: String {
        let isEn = UserDefaults.standard.string(forKey: "appLanguage") == "en"
        switch self {
        case .house:    return isEn ? "Home Loan"     : "قرض مسكن"
        case .car:      return isEn ? "Car Loan"      : "قرض سيارة"
        case .personal: return isEn ? "Personal Loan" : "قرض شخصي"
        case .other:    return isEn ? "Other Loan"    : "قرض آخر"
        }
    }

    var icon: String {
        switch self {
        case .house:    return "house.fill"
        case .car:      return "car.fill"
        case .personal: return "person.fill"
        case .other:    return "doc.text.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .house:    return "#22C55E"
        case .car:      return "#06B6D4"
        case .personal: return "#F2AE2E"
        case .other:    return "#8B5CF6"
        }
    }
}
