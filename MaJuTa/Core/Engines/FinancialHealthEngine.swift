import Foundation

struct FinancialHealthScore {
    let total: Double               // 0-100
    let savingsRateScore: Double    // weight: 30
    let emergencyCoverageScore: Double // weight: 25
    let debtRatioScore: Double      // weight: 25
    let spendingStabilityScore: Double // weight: 20

    var grade: HealthGrade {
        switch total {
        case 80...100: return .excellent
        case 60..<80:  return .good
        case 40..<60:  return .fair
        default:       return .poor
        }
    }
}

enum HealthGrade {
    case excellent, good, fair, poor

    var label: String {
        switch self {
        case .excellent: return "ممتاز"
        case .good:      return "جيد"
        case .fair:      return "مقبول"
        case .poor:      return "ضعيف"
        }
    }

    var colorHex: String {
        switch self {
        case .excellent: return "#22C55E"
        case .good:      return "#F2AE2E"
        case .fair:      return "#F27F1B"
        case .poor:      return "#EF4444"
        }
    }

    var description: String {
        switch self {
        case .excellent: return "وضعك المالي ممتاز، استمر هكذا!"
        case .good:      return "وضعك المالي جيد مع مجال للتحسين"
        case .fair:      return "وضعك المالي مقبول، ابدأ بتحسين مدخراتك"
        case .poor:      return "وضعك المالي يحتاج إلى اهتمام فوري"
        }
    }
}

final class FinancialHealthEngine {

    // MARK: - Main Score Calculator
    /// Pass `hasData: false` when no transactions exist — returns all zeros instead of
    /// misleading scores (e.g. debtRatio=0 would otherwise score 100 with no data).
    static func calculateScore(
        savingsRate: Double,          // percentage 0-100
        emergencyMonths: Double,      // months of coverage
        debtRatio: Double,            // ratio 0-1
        spendingStability: Double,    // percentage 0-100
        hasData: Bool = true
    ) -> FinancialHealthScore {
        guard hasData else {
            return FinancialHealthScore(total: 0, savingsRateScore: 0,
                emergencyCoverageScore: 0, debtRatioScore: 0, spendingStabilityScore: 0)
        }
        let savingsScore    = scoreSavingsRate(savingsRate)
        let emergencyScore  = scoreEmergencyCoverage(emergencyMonths)
        let debtScore       = scoreDebtRatio(debtRatio)
        let stabilityScore  = scoreSpendingStability(spendingStability)

        let total = (savingsScore * 0.30)
                  + (emergencyScore * 0.25)
                  + (debtScore * 0.25)
                  + (stabilityScore * 0.20)

        return FinancialHealthScore(
            total: min(total, 100),
            savingsRateScore: savingsScore,
            emergencyCoverageScore: emergencyScore,
            debtRatioScore: debtScore,
            spendingStabilityScore: stabilityScore
        )
    }

    // MARK: - Component Scorers (each returns 0-100)

    private static func scoreSavingsRate(_ rate: Double) -> Double {
        // 20%+ = 100, 15% = 75, 10% = 50, <5% = 0
        switch rate {
        case 20...:   return 100
        case 15..<20: return 75 + (rate - 15) * 5
        case 10..<15: return 50 + (rate - 10) * 5
        case 5..<10:  return 25 + (rate - 5) * 5
        default:      return max(0, rate * 5)
        }
    }

    private static func scoreEmergencyCoverage(_ months: Double) -> Double {
        // 6+ months = 100, 3-6 = proportional, <1 = 0
        switch months {
        case 6...:   return 100
        case 3..<6:  return 50 + (months - 3) * (50 / 3)
        case 1..<3:  return (months - 1) * 25
        default:     return 0
        }
    }

    private static func scoreDebtRatio(_ ratio: Double) -> Double {
        // <20% = 100, 20-40% = 75, 40-60% = 50, >60% = 0
        switch ratio {
        case ..<0.20: return 100
        case 0.20..<0.40: return 75 - ((ratio - 0.20) / 0.20) * 25
        case 0.40..<0.60: return 50 - ((ratio - 0.40) / 0.20) * 25
        default: return max(0, 25 - ((ratio - 0.60) / 0.40) * 25)
        }
    }

    private static func scoreSpendingStability(_ stability: Double) -> Double {
        return min(stability, 100)
    }

    // MARK: - Spending Stability
    static func spendingStability(
        monthlyExpenses: [Double],
        baselineExpense: Double
    ) -> Double {
        guard !monthlyExpenses.isEmpty, baselineExpense > 0 else { return 100 }
        let variances = monthlyExpenses.map { abs($0 - baselineExpense) / baselineExpense }
        let avgVariance = variances.reduce(0, +) / Double(variances.count)
        return max(0, 100 - (avgVariance * 100))
    }
}
