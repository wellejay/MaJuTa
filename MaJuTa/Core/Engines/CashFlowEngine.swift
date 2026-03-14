import Foundation

final class CashFlowEngine {

    // MARK: - Net Cash Flow
    static func netCashFlow(income: [Transaction], expenses: [Transaction]) -> Double {
        totalIncome(from: income) - totalExpenses(from: expenses)
    }

    static func totalIncome(from transactions: [Transaction]) -> Double {
        transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }

    static func totalExpenses(from transactions: [Transaction]) -> Double {
        transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
    }

    // MARK: - Safe To Spend
    static func safeToSpend(
        liquidCash: Double,
        upcomingBills: Double,
        plannedSavings: Double,
        emergencyContribution: Double
    ) -> Double {
        liquidCash - upcomingBills - plannedSavings - emergencyContribution
    }

    // MARK: - Savings Rate
    static func savingsRate(savingsContributions: Double, disposableIncome: Double) -> Double {
        guard disposableIncome > 0 else { return 0 }
        return (savingsContributions / disposableIncome) * 100
    }

    // MARK: - Emergency Fund Coverage
    static func emergencyMonths(emergencyBalance: Double, monthlyEssentials: Double) -> Double {
        guard monthlyEssentials > 0 else { return 0 }
        return emergencyBalance / monthlyEssentials
    }

    // MARK: - Fixed Obligation Ratio
    static func fixedObligationRatio(fixedExpenses: Double, monthlyIncome: Double) -> Double {
        guard monthlyIncome > 0 else { return 0 }
        return fixedExpenses / monthlyIncome
    }

    static func obligationRiskLevel(ratio: Double) -> ObligationRisk {
        if ratio < 0.40 { return .healthy }
        if ratio < 0.60 { return .warning }
        return .highRisk
    }

    // MARK: - Housing Burden
    static func housingRatio(housingCosts: Double, monthlyIncome: Double) -> Double {
        guard monthlyIncome > 0 else { return 0 }
        return housingCosts / monthlyIncome
    }

    // MARK: - Net Worth
    static func netWorth(totalAssets: Double, totalLiabilities: Double) -> Double {
        totalAssets - totalLiabilities
    }

    // MARK: - Budget Variance
    static func budgetVariance(actual: Double, planned: Double) -> Double {
        actual - planned
    }

    static func budgetVariancePercentage(actual: Double, planned: Double) -> Double {
        guard planned > 0 else { return 0 }
        return (actual - planned) / planned * 100
    }

    // MARK: - Sinking Fund (annual payment breakdown)
    static func monthlyContribution(targetAmount: Double, monthsUntilDue: Int) -> Double {
        guard monthsUntilDue > 0 else { return targetAmount }
        return targetAmount / Double(monthsUntilDue)
    }

    // MARK: - Monthly Transactions Filter
    static func transactions(
        from all: [Transaction],
        in month: Date,
        calendar: Calendar = .current
    ) -> [Transaction] {
        all.filter {
            calendar.isDate($0.date, equalTo: month, toGranularity: .month)
        }
    }

    // MARK: - Spending Anomaly Detection
    static func isAnomaly(todaySpend: Double, thirtyDayAverage: Double) -> Bool {
        todaySpend > 2 * thirtyDayAverage
    }

    static func thirtyDayAverage(transactions: [Transaction], referenceDate: Date = Date()) -> Double {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: referenceDate) ?? referenceDate
        let recent = transactions.filter { $0.date >= thirtyDaysAgo && $0.amount < 0 }
        guard !recent.isEmpty else { return 0 }
        let total = recent.reduce(0) { $0 + abs($1.amount) }
        return total / 30
    }
}

enum ObligationRisk {
    case healthy
    case warning
    case highRisk

    var label: String {
        switch self {
        case .healthy:  return "ممتاز"
        case .warning:  return "تحذير"
        case .highRisk: return "خطر"
        }
    }

    var colorHex: String {
        switch self {
        case .healthy:  return "#22C55E"
        case .warning:  return "#F59E0B"
        case .highRisk: return "#EF4444"
        }
    }
}
