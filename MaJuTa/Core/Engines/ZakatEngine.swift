import Foundation

// MARK: - Zakat Engine
// Implements Islamic wealth tax (زكاة) calculation for Saudi households.
//
// Rules applied:
//   • Nisab threshold: equivalent of 85 grams of gold (conservative estimate ~20,400 SAR)
//   • Rate: 2.5% (25 per 1,000) of zakatable wealth
//   • Hawl: assets must have been held for a full Hijri year (enforced by caller — we compute the amount due)
//   • Zakatable assets: cash, bank balances, savings, investments at market value
//   • Deductions: current liabilities (credit card, loans, BNPL obligations due now)
//   • Non-zakatable: personal use items, primary residence, vehicles, clothing, food stock

final class ZakatEngine {

    // Nisab threshold in SAR (~85g gold × ~240 SAR/g — update annually via setting)
    // Saudi scholars use the gold nisab; silver nisab (~595g) would be lower but gold is standard.
    static let nisabSAR: Double = 20_400

    // Zakat rate: 2.5% = 25 per 1,000
    static let zakatRate: Double = 0.025

    // MARK: - Summary Types

    struct ZakatSummary {
        let zakatableWealth: Double
        let nisab: Double
        let isAboveNisab: Bool
        let zakatDue: Double
        let breakdown: ZakatBreakdown

        /// Progress toward nisab (0–1). Shows how close you are even if below nisab.
        var nisabProgress: Double { min(zakatableWealth / nisab, 1.0) }
    }

    struct ZakatBreakdown {
        let liquidCash: Double
        let savingsBalance: Double
        let investmentPortfolio: Double
        let totalLiabilities: Double
        let zakatableTotal: Double    // = liquidCash + savings + portfolio - liabilities (floored at 0)
    }

    // MARK: - Calculation

    /// Calculate Zakat due on net zakatable wealth.
    /// - Parameters:
    ///   - liquidCash: Sum of bank + wallet + cash account balances
    ///   - savingsBalance: Emergency fund + savings accounts
    ///   - investmentPortfolio: Market value of all investment assets (stocks, ETFs, REITs, Sukuk)
    ///   - liabilities: Credit card debt + loan balances + BNPL obligations = what you currently owe
    /// - Returns: Full ZakatSummary with breakdown and amount due
    static func calculate(
        liquidCash: Double,
        savingsBalance: Double,
        investmentPortfolio: Double,
        liabilities: Double
    ) -> ZakatSummary {
        let gross = liquidCash + savingsBalance + investmentPortfolio
        let zakatableWealth = max(0, gross - liabilities)
        let isAboveNisab = zakatableWealth >= nisabSAR
        let zakatDue = isAboveNisab ? zakatableWealth * zakatRate : 0

        return ZakatSummary(
            zakatableWealth: zakatableWealth,
            nisab: nisabSAR,
            isAboveNisab: isAboveNisab,
            zakatDue: zakatDue,
            breakdown: ZakatBreakdown(
                liquidCash: liquidCash,
                savingsBalance: savingsBalance,
                investmentPortfolio: investmentPortfolio,
                totalLiabilities: liabilities,
                zakatableTotal: zakatableWealth
            )
        )
    }

    // MARK: - Monthly Provision

    /// Monthly amount to set aside so you have full Zakat ready when the Hijri year completes.
    /// Based on current wealth — re-calculate each month as wealth changes.
    static func monthlyProvision(zakatDue: Double) -> Double {
        // Hijri year = 354 days ≈ 11.8 months; use 12 for simplicity
        zakatDue / 12
    }
}
