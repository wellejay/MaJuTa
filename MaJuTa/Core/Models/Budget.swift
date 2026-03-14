import Foundation

// MARK: - Budget
// Monthly spending plan per category — the "planned" side of budget variance analysis.
// Each household can have one Budget per calendar month.
struct Budget: Identifiable, Codable {
    let id: UUID
    var monthYear: Date             // normalized to first day of the month at midnight
    var allocations: [BudgetAllocation]
    var householdId: UUID
    var ownerUserId: UUID
    var syncStatus: SyncStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        monthYear: Date = Date().startOfMonth,
        allocations: [BudgetAllocation] = [],
        householdId: UUID,
        ownerUserId: UUID,
        syncStatus: SyncStatus = .localOnly,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.monthYear = monthYear
        self.allocations = allocations
        self.householdId = householdId
        self.ownerUserId = ownerUserId
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var totalPlanned: Double {
        allocations.reduce(0) { $0 + $1.planned }
    }
}

// MARK: - Budget Allocation
// A single category's monthly spending plan.
struct BudgetAllocation: Codable, Identifiable {
    let id: UUID
    var categoryId: UUID
    var categoryName: String        // denormalized for display without join
    var categoryIcon: String
    var planned: Double             // SAR planned for this category this month

    init(
        id: UUID = UUID(),
        categoryId: UUID,
        categoryName: String,
        categoryIcon: String = "questionmark.circle",
        planned: Double
    ) {
        self.id = id
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.categoryIcon = categoryIcon
        self.planned = planned
    }
}

// MARK: - Budget Variance
// Planned vs actual for one category — computed on-the-fly, never persisted.
struct BudgetVariance: Identifiable {
    let id = UUID()
    let categoryId: UUID
    let categoryName: String
    let categoryIcon: String
    let planned: Double
    let actual: Double

    var variance: Double            { actual - planned }   // positive = over budget
    var remaining: Double           { max(0, planned - actual) }
    var utilizationPct: Double      { planned > 0 ? min(actual / planned * 100, 200) : 0 }
    var isOverBudget: Bool          { actual > planned }
    var isNearLimit: Bool           { utilizationPct >= 80 && !isOverBudget }
}

// MARK: - Date Helper
private extension Date {
    /// First moment of the current month (used to normalize monthYear)
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
}

extension Date {
    /// First moment of the month containing self — used for Budget monthYear normalization
    var normalizedToMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
}
