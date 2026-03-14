import Foundation

// MARK: - Income Statement
// Personal finance P&L: Revenue − Expenses = Net Income
// Savings / investments sit "below the line" — they are allocations of net income, not expenses.
struct IncomeStatement {
    let month: Date

    // Revenue
    let revenue: Double

    // Operating Expenses (by COA group)
    let essentialExpenses: Double     // rent, utilities, groceries, fuel, telecom …
    let lifestyleExpenses: Double     // restaurants, shopping, entertainment …
    let familyExpenses: Double        // kids, parents, gifts …
    let financialExpenses: Double     // debt repayment, fees …
    let totalExpenses: Double

    // Net Income = Revenue − Total Expenses
    let netIncome: Double

    // Below-the-line allocations
    let savingsAllocated: Double
    let investmentsAllocated: Double

    // Derived
    var discretionaryIncome: Double { revenue - essentialExpenses }

    var savingsRate: Double {
        guard revenue > 0 else { return 0 }
        return (savingsAllocated + investmentsAllocated) / revenue * 100
    }

    var expenseRatio: Double {
        guard revenue > 0 else { return 0 }
        return totalExpenses / revenue * 100
    }
}

// MARK: - Balance Sheet
// Accounting identity: Assets = Liabilities + Equity
struct BalanceSheet {
    // Assets
    let liquidCash: Double            // bank + wallet + cash accounts
    let savingsBalance: Double        // savings accounts (emergency fund etc.)
    let investmentPortfolio: Double   // market value of investment assets
    let totalAssets: Double

    // Liabilities
    let creditCardDebt: Double        // outstanding credit card balances
    let loanBalance: Double           // outstanding loan balances
    let bnplObligations: Double       // remaining BNPL installments (unpaid)
    let totalLiabilities: Double

    // Equity (Net Worth)
    var equity: Double { totalAssets - totalLiabilities }

    // Ratios
    var debtToAssetRatio: Double {
        guard totalAssets > 0 else { return 0 }
        return totalLiabilities / totalAssets
    }

    var liquidityRatio: Double {
        guard totalLiabilities > 0 else { return .infinity }
        return liquidCash / totalLiabilities
    }

    // Sanity check: Assets must equal Liabilities + Equity
    var isBalanced: Bool { abs(totalAssets - (totalLiabilities + equity)) < 0.01 }
}

// MARK: - Cash Flow Statement
// Classifies all money movement into three activity types
struct CashFlowStatement {
    let month: Date

    // Operating: day-to-day income & expenses
    let operatingCashFlow: Double

    // Investing: purchase/sale of investment assets
    let investingCashFlow: Double

    // Financing: savings allocations, loan payments
    let financingCashFlow: Double

    var netCashFlow: Double { operatingCashFlow + investingCashFlow + financingCashFlow }

    var isPositive: Bool { netCashFlow >= 0 }
}

// MARK: - Trial Balance (accounting integrity check)
// Sum of all debits must equal sum of all credits.
// Debit accounts: Assets & Expenses. Credit accounts: Liabilities, Equity & Revenue.
struct TrialBalance {
    let totalDebits: Double
    let totalCredits: Double
    var isBalanced: Bool { abs(totalDebits - totalCredits) < 0.01 }
    var discrepancy: Double { totalDebits - totalCredits }
}

// MARK: - Ledger Engine
final class LedgerEngine {

    // MARK: - Income Statement
    static func incomeStatement(
        transactions: [Transaction],
        categories: [TransactionCategory],
        for month: Date = Date()
    ) -> IncomeStatement {
        let monthly = CashFlowEngine.transactions(from: transactions, in: month)
        let catMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

        var revenue = 0.0
        var essential = 0.0
        var lifestyle = 0.0
        var family = 0.0
        var financial = 0.0
        var savingsAllocated = 0.0
        var investmentsAllocated = 0.0

        for tx in monthly {
            guard let cat = catMap[tx.categoryId] else { continue }
            switch cat.type {
            case .income:
                revenue += max(0, tx.amount)
            case .expense:
                let absAmt = abs(min(0, tx.amount))
                switch cat.parentCategory {
                case .essential: essential  += absAmt
                case .lifestyle: lifestyle  += absAmt
                case .family:    family     += absAmt
                case .financial: financial  += absAmt
                case .income:    break
                }
            case .savings:
                savingsAllocated += abs(min(0, tx.amount))
            case .investment:
                investmentsAllocated += abs(min(0, tx.amount))
            }
        }

        let totalExpenses = essential + lifestyle + family + financial
        return IncomeStatement(
            month: month,
            revenue: revenue,
            essentialExpenses: essential,
            lifestyleExpenses: lifestyle,
            familyExpenses: family,
            financialExpenses: financial,
            totalExpenses: totalExpenses,
            netIncome: revenue - totalExpenses,
            savingsAllocated: savingsAllocated,
            investmentsAllocated: investmentsAllocated
        )
    }

    // MARK: - Balance Sheet
    static func balanceSheet(
        accounts: [Account],
        investments: [InvestmentAsset],
        installments: [Installment]
    ) -> BalanceSheet {
        let liquidCash  = accounts.filter { $0.isLiquid }.reduce(0) { $0 + $1.balance }
        let savings     = accounts.filter { $0.type == .savings }.reduce(0) { $0 + $1.balance }
        let portfolio   = InvestmentEngine.portfolioValue(assets: investments)

        // Liabilities — balance stored as positive (amount owed)
        let ccDebt      = accounts.filter { $0.type == .creditCard }.reduce(0) { $0 + $1.balance }
        let loanBal     = accounts.filter { $0.type == .loan }.reduce(0) { $0 + $1.balance }
        // All unpaid BNPL installments (upcoming + overdue) = total remaining obligation
        let bnpl        = installments.filter { $0.status != .paid }.reduce(0) { $0 + $1.amount }

        let totalAssets      = liquidCash + savings + portfolio
        let totalLiabilities = ccDebt + loanBal + bnpl

        return BalanceSheet(
            liquidCash: liquidCash,
            savingsBalance: savings,
            investmentPortfolio: portfolio,
            totalAssets: totalAssets,
            creditCardDebt: ccDebt,
            loanBalance: loanBal,
            bnplObligations: bnpl,
            totalLiabilities: totalLiabilities
        )
    }

    // MARK: - Cash Flow Statement
    static func cashFlowStatement(
        transactions: [Transaction],
        categories: [TransactionCategory],
        for month: Date = Date()
    ) -> CashFlowStatement {
        let monthly = CashFlowEngine.transactions(from: transactions, in: month)
        let catMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

        var operating = 0.0
        var investing  = 0.0
        var financing  = 0.0

        for tx in monthly {
            guard let cat = catMap[tx.categoryId] else { continue }
            switch cat.type {
            case .income:
                operating += tx.amount            // positive: cash inflow from income
            case .expense:
                operating += tx.amount            // negative: cash outflow for expenses
            case .savings:
                financing += tx.amount            // negative: allocation to savings/emergency
            case .investment:
                investing += tx.amount            // negative: investment purchase outflow
            }
        }

        return CashFlowStatement(
            month: month,
            operatingCashFlow: operating,
            investingCashFlow: investing,
            financingCashFlow: financing
        )
    }

    // MARK: - Trial Balance
    static func trialBalance(
        accounts: [Account],
        investments: [InvestmentAsset]
    ) -> TrialBalance {
        // In personal finance terms:
        // Debits (what you own)  = Asset account balances + Investment portfolio
        // Credits (claims on assets) = Liability balances + Equity (net worth)
        let assets      = accounts.filter { !$0.isLiability }.reduce(0) { $0 + $1.balance }
                        + InvestmentEngine.portfolioValue(assets: investments)
        let liabilities = accounts.filter { $0.isLiability }.reduce(0) { $0 + $1.balance }
        let equity      = assets - liabilities   // by definition always balanced

        return TrialBalance(
            totalDebits:  assets,
            totalCredits: liabilities + equity
        )
    }

    // MARK: - Budget Variance per Category
    static func budgetVariances(
        budget: Budget,
        transactions: [Transaction],
        categories: [TransactionCategory]
    ) -> [BudgetVariance] {
        let monthly = CashFlowEngine.transactions(from: transactions, in: budget.monthYear)
        return budget.allocations.map { alloc in
            let actual = monthly
                .filter { $0.categoryId == alloc.categoryId && $0.amount < 0 }
                .reduce(0) { $0 + abs($1.amount) }
            return BudgetVariance(
                categoryId: alloc.categoryId,
                categoryName: alloc.categoryName,
                categoryIcon: alloc.categoryIcon,
                planned: alloc.planned,
                actual: actual
            )
        }
    }
}
