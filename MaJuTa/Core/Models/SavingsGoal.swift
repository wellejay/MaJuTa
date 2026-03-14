import Foundation

struct SavingsGoal: Identifiable, Codable {
    let id: UUID
    var name: String
    var nameArabic: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var ownerUserId: UUID
    var householdId: UUID
    var isShared: Bool
    var icon: String
    var colorHex: String
    var syncStatus: SyncStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        nameArabic: String = "",
        targetAmount: Double,
        currentAmount: Double = 0,
        deadline: Date? = nil,
        ownerUserId: UUID,
        householdId: UUID,
        isShared: Bool = false,
        icon: String = "target",
        colorHex: String = "#F2AE2E",
        syncStatus: SyncStatus = .localOnly,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.nameArabic = nameArabic
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.ownerUserId = ownerUserId
        self.householdId = householdId
        self.isShared = isShared
        self.icon = icon
        self.colorHex = colorHex
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var remainingAmount: Double {
        max(targetAmount - currentAmount, 0)
    }

    var isCompleted: Bool {
        currentAmount >= targetAmount
    }
}

// MARK: - Emergency Fund
struct EmergencyFund: Codable {
    var currentBalance: Double
    var monthlyContribution: Double
    var targetMonths: Int

    var coverageMonths: Double {
        return 0 // Calculated by engine using essential expenses
    }
}
