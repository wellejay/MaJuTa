import XCTest
@testable import MaJuTa

final class MaJuTaTests: XCTestCase {

    func testNetCashFlow() {
        let uid = UUID(), aid = UUID(), cid = UUID()
        let income = Transaction(amount: 15000, categoryId: cid, accountId: aid, ownerUserId: uid, createdByUserId: uid)
        let expense = Transaction(amount: -4000, categoryId: cid, accountId: aid, ownerUserId: uid, createdByUserId: uid)
        XCTAssertEqual(CashFlowEngine.netCashFlow(income: [income], expenses: [expense]), 11000)
    }

    func testSafeToSpend() {
        let safe = CashFlowEngine.safeToSpend(liquidCash: 20000, upcomingBills: 5000, plannedSavings: 2000, emergencyContribution: 500)
        XCTAssertEqual(safe, 12500)
    }

    func testEmergencyMonths() {
        XCTAssertEqual(CashFlowEngine.emergencyMonths(emergencyBalance: 18000, monthlyEssentials: 6000), 3.0)
    }

    func testSavingsRate() {
        XCTAssertEqual(CashFlowEngine.savingsRate(savingsContributions: 2000, disposableIncome: 15000), 13.33, accuracy: 0.01)
    }

    func testInstallmentAmount() {
        let plan = InstallmentPlan(merchant: "Noon", provider: .tabby, totalAmount: 1200, installmentsCount: 4, ownerUserId: UUID())
        XCTAssertEqual(plan.installmentAmount, 300)
    }

    func testPortfolioValue() {
        let uid = UUID(), hid = UUID()
        let a1 = InvestmentAsset(symbol: "2222", name: "أرامكو", units: 100, costBasis: 32000, lastPrice: 28.5, ownerUserId: uid, householdId: hid)
        let a2 = InvestmentAsset(symbol: "1180", name: "الراجحي", units: 50, costBasis: 9800, lastPrice: 88.0, ownerUserId: uid, householdId: hid)
        XCTAssertEqual(InvestmentEngine.portfolioValue(assets: [a1, a2]), 100 * 28.5 + 50 * 88.0)
    }

    func testFinancialHealthScore() {
        let score = FinancialHealthEngine.calculateScore(savingsRate: 20, emergencyMonths: 6, debtRatio: 0.15, spendingStability: 90)
        XCTAssertGreaterThan(score.total, 80)
        XCTAssertEqual(score.grade, .excellent)
    }

    func testObligationRisk() {
        XCTAssertEqual(CashFlowEngine.obligationRiskLevel(ratio: 0.30), .healthy)
        XCTAssertEqual(CashFlowEngine.obligationRiskLevel(ratio: 0.50), .warning)
        XCTAssertEqual(CashFlowEngine.obligationRiskLevel(ratio: 0.70), .highRisk)
    }

    func testNetWorth() {
        XCTAssertEqual(CashFlowEngine.netWorth(totalAssets: 100000, totalLiabilities: 30000), 70000)
    }

    func testSARFormatting() {
        XCTAssertEqual(15000.0.sarFormatted, "﷼15,000")
    }
}
