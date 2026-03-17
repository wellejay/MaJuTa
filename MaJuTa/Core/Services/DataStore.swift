import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class DataStore: ObservableObject {

    static let shared = DataStore()

    // MARK: - Published Data
    @Published var accounts: [Account] = []
    @Published var transactions: [Transaction] = []
    @Published var categories: [TransactionCategory] = TransactionCategory.defaultCategories
    @Published var savingsGoals: [SavingsGoal] = []
    @Published var bills: [Bill] = []
    @Published var investments: [InvestmentAsset] = []
    @Published var installmentPlans: [InstallmentPlan] = []
    @Published var installments: [Installment] = []
    @Published var activityLog: [ActivityEntry] = []
    @Published var budgets: [Budget] = []
    @Published var loans: [Loan] = []

    // MARK: - Guest Mode Flag
    @Published var isGuestMode: Bool = false

    // MARK: - Firestore Listeners
    private var listeners: [ListenerRegistration] = []

    // MARK: - Stable IDs (derived from UserService)
    var currentUserId: UUID {
        UserService.shared.currentUser?.id ?? UUID()
    }

    var currentHouseholdId: UUID {
        UserService.shared.currentUser?.householdId ?? UUID()
    }

    private init() {}

    // MARK: - Guest Mode

    // MARK: - Guest persistence file URL
    private static let guestDataURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("guest_data.json")
    }()

    func loadGuestMode() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        isGuestMode = true
        // Restore previously saved guest session if available
        if let data = try? Data(contentsOf: Self.guestDataURL),
           let snap = try? JSONDecoder().decode(GuestSnapshot.self, from: data) {
            accounts         = snap.accounts
            transactions     = snap.transactions
            savingsGoals     = snap.savingsGoals
            bills            = snap.bills
            investments      = snap.investments
            installmentPlans = snap.installmentPlans
            installments     = snap.installments
            budgets          = snap.budgets
            loans            = snap.loans
        } else {
            clearAll()
        }
    }

    /// Persists current in-memory guest data to a local JSON file.
    func saveGuestData() {
        guard isGuestMode else { return }
        let snap = GuestSnapshot(
            accounts: accounts, transactions: transactions, savingsGoals: savingsGoals,
            bills: bills, investments: investments, installmentPlans: installmentPlans,
            installments: installments, budgets: budgets, loans: loans
        )
        if let encoded = try? JSONEncoder().encode(snap) {
            try? encoded.write(to: Self.guestDataURL, options: [.atomic, .completeFileProtection])
        }
    }

    /// Deletes the guest data file (called when guest converts to full account).
    func deleteGuestData() {
        try? FileManager.default.removeItem(at: Self.guestDataURL)
    }

    func clearAll() {
        accounts = []; transactions = []; savingsGoals = []
        bills = []; investments = []; installmentPlans = []
        installments = []; activityLog = []; budgets = []; loans = []
    }

    // MARK: - Load / Subscribe

    func loadForCurrentUser() {
        // Remove old listeners
        listeners.forEach { $0.remove() }
        listeners.removeAll()

        // Clear local data
        accounts = []; transactions = []; savingsGoals = []
        bills = []; investments = []; installmentPlans = []
        installments = []; activityLog = []; budgets = []; loans = []

        guard let user = UserService.shared.currentUser else { return }
        let hid = user.householdId
        let fs = FirestoreService.shared

        listeners.append(fs.listen(collection: "accounts", householdId: hid) { [weak self] (items: [Account]) in
            self?.accounts = items.sorted { $0.createdAt < $1.createdAt }
        })
        listeners.append(fs.listen(collection: "transactions", householdId: hid) { [weak self] (items: [Transaction]) in
            self?.transactions = items.sorted { $0.date > $1.date }
        })
        listeners.append(fs.listen(collection: "savingsGoals", householdId: hid) { [weak self] (items: [SavingsGoal]) in
            self?.savingsGoals = items.sorted { $0.createdAt < $1.createdAt }
        })
        listeners.append(fs.listen(collection: "bills", householdId: hid) { [weak self] (items: [Bill]) in
            self?.bills = items.sorted { $0.dueDate < $1.dueDate }
        })
        listeners.append(fs.listen(collection: "investments", householdId: hid) { [weak self] (items: [InvestmentAsset]) in
            self?.investments = items.sorted { $0.createdAt < $1.createdAt }
        })
        listeners.append(fs.listen(collection: "installmentPlans", householdId: hid) { [weak self] (items: [InstallmentPlan]) in
            self?.installmentPlans = items.sorted { $0.createdAt < $1.createdAt }
        })
        listeners.append(fs.listen(collection: "installments", householdId: hid) { [weak self] (items: [Installment]) in
            self?.installments = items.sorted { $0.dueDate < $1.dueDate }
        })
        listeners.append(fs.listen(collection: "activityLog", householdId: hid) { [weak self] (items: [ActivityEntry]) in
            self?.activityLog = items.sorted { $0.timestamp > $1.timestamp }
            if (self?.activityLog.count ?? 0) > 100 {
                self?.activityLog = Array((self?.activityLog ?? []).prefix(100))
            }
        })
        listeners.append(fs.listen(collection: "budgets", householdId: hid) { [weak self] (items: [Budget]) in
            self?.budgets = items.sorted { $0.monthYear > $1.monthYear }
        })
        listeners.append(fs.listen(collection: "loans", householdId: hid) { [weak self] (items: [Loan]) in
            self?.loans = items.sorted { $0.nextPaymentDate < $1.nextPaymentDate }
        })
    }

    // MARK: - Activity Logging

    private func logActivity(_ action: ActivityActionType, objectType: String, description: String) {
        guard let user = UserService.shared.currentUser, !isGuestMode else { return }
        let entry = ActivityEntry(
            householdId: user.householdId,
            userId: user.id,
            userName: user.name,
            actionType: action,
            objectType: objectType,
            objectDescription: description
        )
        // Save to Firestore — listener will update local activityLog
        FirestoreService.shared.save(entry, to: "activityLog", householdId: user.householdId)
    }

    // MARK: - Visibility Rules

    var visibleAccounts: [Account] {
        guard let user = UserService.shared.currentUser else { return [] }
        return accounts.filter { $0.isShared || $0.ownerUserId == user.id }
    }

    var visibleTransactions: [Transaction] {
        let visibleIds = Set(visibleAccounts.map { $0.id })
        return transactions.filter { visibleIds.contains($0.accountId) }
    }

    var visibleGoals: [SavingsGoal] {
        guard let user = UserService.shared.currentUser else { return [] }
        return savingsGoals.filter { $0.isShared || $0.ownerUserId == user.id }
    }

    var visibleBills: [Bill] {
        guard let user = UserService.shared.currentUser else { return [] }
        let visibleAccountIds = Set(visibleAccounts.map { $0.id })
        return bills.filter { $0.ownerUserId == user.id || visibleAccountIds.contains($0.accountId) }
    }

    // MARK: - Permission Checks

    func canEdit(account: Account) -> Bool {
        guard let user = UserService.shared.currentUser else { return false }
        if account.isShared { return user.role.canEditSharedAccounts }
        return account.ownerUserId == user.id
    }

    func canAdd(transactionTo account: Account) -> Bool {
        guard let user = UserService.shared.currentUser else { return false }
        guard user.role.canAddTransactions else { return false }
        return account.isShared || account.ownerUserId == user.id
    }

    func canDelete(transaction t: Transaction) -> Bool {
        guard let user = UserService.shared.currentUser else { return false }
        if user.role == .owner { return true }
        let accountOwned = accounts.first(where: { $0.id == t.accountId })?.ownerUserId == user.id
        return t.createdByUserId == user.id || accountOwned
    }

    // MARK: - Computed: Monthly Summaries
    func monthlyIncome(for date: Date = Date()) -> Double {
        let monthly = CashFlowEngine.transactions(from: visibleTransactions, in: date)
        return CashFlowEngine.totalIncome(from: monthly)
    }

    /// Actual transaction income if available; falls back to the declared salary stored in Keychain.
    var effectiveMonthlyIncome: Double {
        let tx = monthlyIncome()
        if tx > 0 { return tx }
        return KeychainService.getDouble(for: "monthlyIncome") ?? 0
    }

    func monthlyExpenses(for date: Date = Date()) -> Double {
        let monthly = CashFlowEngine.transactions(from: visibleTransactions, in: date)
        return CashFlowEngine.totalExpenses(from: monthly)
    }

    func netCashFlow(for date: Date = Date()) -> Double {
        monthlyIncome(for: date) - monthlyExpenses(for: date)
    }

    var totalLiquidCash: Double {
        visibleAccounts.filter { $0.isLiquid }.reduce(0) { $0 + $1.balance }
    }

    // Only bills due within the next 30 days from visible/owned accounts
    var upcomingBillsTotal: Double {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return visibleBills.filter {
            $0.status == .upcoming && !$0.isOverdue && $0.dueDate <= thirtyDaysFromNow
        }.reduce(0) { $0 + $1.amount }
    }

    // Monthly BNPL installment obligations due within next 30 days
    var monthlyInstallmentPayments: Double {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return installments.filter {
            $0.status == .upcoming && $0.dueDate <= thirtyDaysFromNow
        }.reduce(0) { $0 + $1.amount }
    }

    // Total amount saved across all active goals (running balance)
    var totalGoalsSaved: Double {
        visibleGoals.reduce(0) { $0 + $1.currentAmount }
    }

    // Actual goal contributions made this month (excludes emergency fund deposits)
    var goalContributionsThisMonth: Double {
        let savingsCatIds = Set(categories.filter { $0.type == .savings }.map { $0.id })
        let monthly = CashFlowEngine.transactions(from: visibleTransactions, in: Date())
        return monthly.filter {
            savingsCatIds.contains($0.categoryId) && $0.amount < 0 &&
            $0.merchant != "صندوق الطوارئ"
        }.reduce(0) { $0 + abs($1.amount) }
    }

    // Actual emergency fund deposits this month — match by merchant name only (category ID may be a fallback UUID)
    var emergencyDepositsThisMonth: Double {
        let monthly = CashFlowEngine.transactions(from: visibleTransactions, in: Date())
        return monthly.filter { $0.amount < 0 && $0.merchant == "صندوق الطوارئ" }
                      .reduce(0) { $0 + abs($1.amount) }
    }

    /// Income-based available metric: income minus ALL outflows (expenses + savings + emergency + goals + bill payments).
    /// This is what the user expects — "what's left from my ﷼35K after everything I've done this month."
    var monthlyNetFromIncome: Double {
        let monthly = CashFlowEngine.transactions(from: visibleTransactions, in: Date())
        let allOutflows = monthly.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
        return effectiveMonthlyIncome - allOutflows
    }

    // Discretionary spending this month — all negative transactions EXCEPT savings/investment/income categories and emergency deposits.
    // Uses exclusion (not inclusion) so transactions with unrecognized category IDs are still counted as expenses.
    var discretionaryExpensesThisMonth: Double {
        let nonExpenseCatIds = Set(categories.filter { $0.type != .expense }.map { $0.id })
        let monthly = CashFlowEngine.transactions(from: visibleTransactions, in: Date())
        return monthly.filter { tx in
            tx.amount < 0 &&
            !nonExpenseCatIds.contains(tx.categoryId) &&
            tx.merchant != "صندوق الطوارئ"   // never count emergency deposits as expenses
        }.reduce(0) { $0 + abs($1.amount) }
    }

    var safeToSpend: Double {
        let remainingPlanned = max(0, plannedSavingsThisMonth - goalContributionsThisMonth)
        let remainingEmergency = max(0, emergencyMonthlyContribution - emergencyDepositsThisMonth)
        return CashFlowEngine.safeToSpend(
            liquidCash: totalLiquidCash,
            upcomingBills: upcomingBillsTotal + upcomingLoanPaymentsTotal,
            plannedSavings: remainingPlanned,
            emergencyContribution: remainingEmergency
        )
    }

    // Monthly savings needed per goal based on remaining amount and time until deadline
    var plannedSavingsThisMonth: Double {
        let now = Date()
        return visibleGoals.filter { !$0.isCompleted }.reduce(0) { sum, goal in
            let remaining = goal.remainingAmount
            guard remaining > 0 else { return sum }
            if let deadline = goal.deadline {
                let months = max(1, Calendar.current.dateComponents([.month], from: now, to: deadline).month ?? 12)
                return sum + (remaining / Double(months))
            }
            return sum + (remaining / 12)
        }
    }

    var emergencyMonthlyContribution: Double {
        // Only contribute if below 6-month target
        let remaining = max(0, (avgMonthlyEssentialExpenses * 6) - emergencyFundBalance)
        guard remaining > 0 else { return 0 }
        return min(effectiveMonthlyIncome * 0.10, remaining)
    }

    // Total monthly savings being set aside: goals + emergency fund
    var monthlySavingsAllocation: Double {
        plannedSavingsThisMonth + emergencyMonthlyContribution
    }

    // Actual savings rate based on planned allocations (not unspent income)
    var actualSavingsRate: Double {
        CashFlowEngine.savingsRate(
            savingsContributions: monthlySavingsAllocation,
            disposableIncome: effectiveMonthlyIncome
        )
    }

    var emergencyFundBalance: Double {
        let emergencyAccounts = visibleAccounts.filter {
            $0.type == .savings &&
            ($0.name.contains("طوارئ") || $0.name.lowercased().contains("emergency"))
        }
        let target = emergencyAccounts.isEmpty
            ? visibleAccounts.filter { $0.type == .savings }
            : emergencyAccounts
        return target.reduce(0) { $0 + $1.balance }
    }

    var monthlyEssentialExpenses: Double {
        let essentialIds = categories.filter { $0.parentCategory == .essential }.map { $0.id }
        let thisMonth = CashFlowEngine.transactions(from: visibleTransactions, in: Date())
        return thisMonth.filter { essentialIds.contains($0.categoryId) && $0.amount < 0 }
                        .reduce(0) { $0 + abs($1.amount) }
    }

    // 3-month rolling average of essential expenses (more stable than single-month)
    var avgMonthlyEssentialExpenses: Double {
        let essentialIds = Set(categories.filter { $0.parentCategory == .essential }.map { $0.id })
        let months = (0..<3).compactMap { offset -> Double? in
            guard let date = Calendar.current.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let monthly = CashFlowEngine.transactions(from: visibleTransactions, in: date)
            let expenses = monthly.filter { essentialIds.contains($0.categoryId) && $0.amount < 0 }
                                  .reduce(0) { $0 + abs($1.amount) }
            return expenses > 0 ? expenses : nil
        }
        guard !months.isEmpty else { return max(monthlyIncome() * 0.5, 1) }
        return months.reduce(0, +) / Double(months.count)
    }

    var emergencyMonths: Double {
        CashFlowEngine.emergencyMonths(
            emergencyBalance: emergencyFundBalance,
            monthlyEssentials: avgMonthlyEssentialExpenses
        )
    }

    var portfolioValue: Double {
        InvestmentEngine.portfolioValue(assets: investments)
    }

    // MARK: - Balance Sheet Aggregates (COA-based)

    /// Total of all asset accounts (bank, wallet, savings, investment, cash)
    var totalAssets: Double {
        visibleAccounts.filter { !$0.isLiability }.reduce(0) { $0 + $1.balance } + portfolioValue
    }

    // MARK: - Loans Computed

    var visibleLoans: [Loan] {
        guard let user = UserService.shared.currentUser else { return [] }
        return loans.filter { $0.isShared || $0.ownerUserId == user.id }
    }

    /// Total remaining balance across all active loans
    var totalLoanBalance: Double {
        visibleLoans.filter { !$0.isFullyPaid }.reduce(0) { $0 + $1.remainingBalance }
    }

    /// Sum of monthly payments for all active loans
    var monthlyLoanPayments: Double {
        visibleLoans.filter { !$0.isFullyPaid }.reduce(0) { $0 + $1.monthlyPayment }
    }

    /// Loan payments due within the next 30 days (used in safeToSpend deduction)
    var upcomingLoanPaymentsTotal: Double {
        let thirtyDays = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return visibleLoans.filter {
            !$0.isFullyPaid && $0.nextPaymentDate <= thirtyDays
        }.reduce(0) { $0 + $1.monthlyPayment }
    }

    /// Monthly loan payments / income (debt service ratio)
    var debtObligationRatio: Double {
        let income = effectiveMonthlyIncome
        guard income > 0 else { return 0 }
        return monthlyLoanPayments / income
    }

    /// Total of all liability accounts (credit card, loan) — what you owe
    var totalLiabilities: Double {
        visibleAccounts.filter { $0.isLiability }.reduce(0) { $0 + $1.balance } + totalLoanBalance
    }

    /// Net Worth = Assets − Liabilities (the correct accounting identity)
    var netWorth: Double {
        CashFlowEngine.netWorth(totalAssets: totalAssets, totalLiabilities: totalLiabilities)
    }

    // MARK: - Financial Statements (computed on demand)

    var currentMonthIncomeStatement: IncomeStatement {
        LedgerEngine.incomeStatement(
            transactions: visibleTransactions,
            categories: categories
        )
    }

    var currentBalanceSheet: BalanceSheet {
        LedgerEngine.balanceSheet(
            accounts: visibleAccounts,
            investments: investments,
            installments: installments
        )
    }

    var currentCashFlowStatement: CashFlowStatement {
        LedgerEngine.cashFlowStatement(
            transactions: visibleTransactions,
            categories: categories
        )
    }

    // MARK: - Zakat

    var zakatSummary: ZakatEngine.ZakatSummary {
        ZakatEngine.calculate(
            liquidCash: totalLiquidCash,
            savingsBalance: emergencyFundBalance,
            investmentPortfolio: portfolioValue,
            liabilities: totalLiabilities
        )
    }

    // MARK: - Budget

    /// Returns the budget for the current calendar month, if one exists.
    var currentMonthBudget: Budget? {
        budgets.first {
            Calendar.current.isDate($0.monthYear, equalTo: Date(), toGranularity: .month)
        }
    }

    /// Budget variances for the current month (planned vs actual per category).
    var currentMonthBudgetVariances: [BudgetVariance] {
        guard let budget = currentMonthBudget else { return [] }
        return LedgerEngine.budgetVariances(
            budget: budget,
            transactions: visibleTransactions,
            categories: categories
        )
    }

    func saveBudget(_ budget: Budget) {
        if let idx = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[idx] = budget
        } else {
            budgets.append(budget)
        }
        if !isGuestMode {
            FirestoreService.shared.save(budget, to: "budgets", householdId: currentHouseholdId)
            logActivity(.goalUpdated, objectType: "budget", description: "تحديث الميزانية")
        } else {
            saveGuestData()
        }
    }

    // Bills + BNPL installments + loans = total monthly fixed obligations
    var fixedObligationRatio: Double {
        let income = effectiveMonthlyIncome
        guard income > 0 else { return 0 }
        return CashFlowEngine.fixedObligationRatio(
            fixedExpenses: upcomingBillsTotal + monthlyInstallmentPayments + monthlyLoanPayments,
            monthlyIncome: income
        )
    }

    var spendingStability: Double {
        let months = (0..<3).compactMap { offset -> Double? in
            guard let date = Calendar.current.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let exp = monthlyExpenses(for: date)
            return exp > 0 ? exp : nil
        }
        guard months.count >= 2 else { return 0 }
        let avg = months.reduce(0, +) / Double(months.count)
        guard avg > 0 else { return 0 }
        let variance = months.map { pow($0 - avg, 2) }.reduce(0, +) / Double(months.count)
        let cv = sqrt(variance) / avg
        return max(0, min(100, (1.0 - min(1.0, cv)) * 100))
    }

    // MARK: - CRUD Operations

    func addAccount(_ account: Account) {
        logActivity(.accountCreated, objectType: "account", description: account.name)
        if isGuestMode {
            accounts.append(account)
            saveGuestData()
        } else {
            FirestoreService.shared.save(account, to: "accounts", householdId: currentHouseholdId)
        }
    }

    func withdrawFromEmergencyFund(amount: Double) {
        guard amount > 0 else { return }
        guard let savingsIdx = accounts.firstIndex(where: { $0.type == .savings }) else { return }

        let actualWithdrawal = min(amount, accounts[savingsIdx].balance)
        guard actualWithdrawal > 0 else { return }

        // 1. Decrease savings account
        accounts[savingsIdx].balance -= actualWithdrawal
        accounts[savingsIdx].updatedAt = Date()
        if !isGuestMode {
            FirestoreService.shared.save(accounts[savingsIdx], to: "accounts", householdId: currentHouseholdId)
        }

        // 2. Add back to liquid account
        if var liquid = accounts.first(where: { $0.isLiquid }) {
            liquid.balance += actualWithdrawal
            liquid.updatedAt = Date()
            if let lIdx = accounts.firstIndex(where: { $0.id == liquid.id }) { accounts[lIdx] = liquid }
            if !isGuestMode {
                FirestoreService.shared.save(liquid, to: "accounts", householdId: currentHouseholdId)
            }
        }

        logActivity(.transactionCreated, objectType: "account", description: "سحب من صندوق الطوارئ")
        if isGuestMode { saveGuestData() }
    }

    func depositToEmergencyFund(amount: Double) {
        guard amount > 0 else { return }
        // In guest mode allow deposit even without a liquid account (direct balance update only)
        let liquidAccount = accounts.first(where: { $0.isLiquid })
        guard liquidAccount != nil || isGuestMode else { return }

        // 1. Increase savings account balance
        if var savings = accounts.first(where: { $0.type == .savings }) {
            savings.balance += amount
            savings.updatedAt = Date()
            if let idx = accounts.firstIndex(where: { $0.id == savings.id }) { accounts[idx] = savings }
            if !isGuestMode {
                FirestoreService.shared.save(savings, to: "accounts", householdId: currentHouseholdId)
            }
        } else {
            // Create savings account automatically
            let savings = Account(
                name: "صندوق الطوارئ",
                type: .savings,
                balance: amount,
                ownerUserId: currentUserId,
                householdId: currentHouseholdId
            )
            accounts.append(savings)
            if !isGuestMode {
                FirestoreService.shared.save(savings, to: "accounts", householdId: currentHouseholdId)
            }
        }

        // 2. Create savings transaction — deducts liquid account in cashflow (only when liquid account exists)
        if let liquid = liquidAccount {
            let savingsCatId = categories.first(where: { $0.type == .savings })?.id ?? UUID()
            let tx = Transaction(
                amount: -amount,
                categoryId: savingsCatId,
                accountId: liquid.id,
                merchant: "صندوق الطوارئ",
                note: "إيداع في صندوق الطوارئ",
                ownerUserId: currentUserId,
                createdByUserId: currentUserId
            )
            addTransaction(tx)
        } else if isGuestMode {
            saveGuestData()
        }
    }

    func deleteTransaction(_ id: UUID) {
        guard let t = transactions.first(where: { $0.id == id }) else { return }
        // Reverse balance: update account
        if var account = accounts.first(where: { $0.id == t.accountId }) {
            account.balance -= t.amount
            account.updatedAt = Date()
            if isGuestMode {
                if let idx = accounts.firstIndex(where: { $0.id == account.id }) { accounts[idx] = account }
            } else {
                FirestoreService.shared.save(account, to: "accounts", householdId: currentHouseholdId)
            }
        }
        logActivity(.transactionDeleted, objectType: "transaction", description: t.merchant)
        if isGuestMode {
            transactions.removeAll { $0.id == id }
            saveGuestData()
        } else {
            FirestoreService.shared.delete(id: id, from: "transactions", householdId: currentHouseholdId)
        }
    }

    func addTransaction(_ transaction: Transaction) {
        // Update account balance
        if var account = accounts.first(where: { $0.id == transaction.accountId }) {
            account.balance += transaction.amount
            account.updatedAt = Date()
            if isGuestMode {
                if let idx = accounts.firstIndex(where: { $0.id == account.id }) { accounts[idx] = account }
            } else {
                FirestoreService.shared.save(account, to: "accounts", householdId: currentHouseholdId)
            }
        }
        logActivity(.transactionCreated, objectType: "transaction", description: transaction.merchant)
        if isGuestMode {
            transactions.insert(transaction, at: 0)
            saveGuestData()
        } else {
            FirestoreService.shared.save(transaction, to: "transactions", householdId: currentHouseholdId)
        }
    }

    func addBill(_ bill: Bill) {
        logActivity(.billCreated, objectType: "bill", description: bill.name)
        if isGuestMode {
            bills.append(bill)
            saveGuestData()
        } else {
            FirestoreService.shared.save(bill, to: "bills", householdId: currentHouseholdId)
        }
    }

    func payBill(_ bill: Bill) {
        guard var updated = bills.first(where: { $0.id == bill.id }) else { return }
        updated.status = .paid
        updated.updatedAt = Date()
        // Optimistic local update
        if let idx = bills.firstIndex(where: { $0.id == bill.id }) { bills[idx] = updated }
        if !isGuestMode {
            FirestoreService.shared.save(updated, to: "bills", householdId: currentHouseholdId)
        }
        // Guest: saveGuestData() will be called by addTransaction below
        // Create expense transaction for this bill payment
        guard let user = UserService.shared.currentUser else { return }
        let tx = Transaction(
            amount: -abs(bill.amount),
            categoryId: bill.categoryId,
            accountId: bill.accountId,
            merchant: bill.name,
            paymentMethod: bill.isAutoPay ? .bankTransfer : .mada,
            note: "دفع فاتورة",
            ownerUserId: user.id,
            createdByUserId: user.id
        )
        addTransaction(tx)
        logActivity(.billCreated, objectType: "bill", description: "\(bill.name) — مدفوعة")
        // If recurring, schedule next due date
        if !isGuestMode && bill.frequency != .custom {
            scheduleNextBill(from: updated)
        }
    }

    private func scheduleNextBill(from bill: Bill) {
        var next = bill
        next = Bill(
            name: bill.name, nameArabic: bill.nameArabic,
            amount: bill.amount, dueDate: nextDueDate(from: bill.dueDate, frequency: bill.frequency),
            categoryId: bill.categoryId, accountId: bill.accountId,
            frequency: bill.frequency, status: .upcoming,
            provider: bill.provider, isAutoPay: bill.isAutoPay,
            ownerUserId: bill.ownerUserId
        )
        FirestoreService.shared.save(next, to: "bills", householdId: currentHouseholdId)
    }

    private func nextDueDate(from date: Date, frequency: RecurringFrequency) -> Date {
        let cal = Calendar.current
        switch frequency {
        case .daily:   return cal.date(byAdding: .day,   value: 1,  to: date) ?? date
        case .weekly:  return cal.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly: return cal.date(byAdding: .month, value: 1,  to: date) ?? date
        case .yearly:  return cal.date(byAdding: .year,  value: 1,  to: date) ?? date
        case .custom:  return date
        }
    }

    func addSavingsGoal(_ goal: SavingsGoal) {
        logActivity(.goalCreated, objectType: "goal", description: goal.name)
        if isGuestMode {
            savingsGoals.append(goal)
            saveGuestData()
        } else {
            FirestoreService.shared.save(goal, to: "savingsGoals", householdId: currentHouseholdId)
        }
    }

    func contribute(to goal: SavingsGoal, amount: Double) {
        guard amount > 0, var updated = savingsGoals.first(where: { $0.id == goal.id }) else { return }

        // 1. Update goal balance
        updated.currentAmount += amount
        updated.updatedAt = Date()
        if let idx = savingsGoals.firstIndex(where: { $0.id == goal.id }) { savingsGoals[idx] = updated }
        if !isGuestMode {
            FirestoreService.shared.save(updated, to: "savingsGoals", householdId: currentHouseholdId)
        }

        // 2. Create a savings transaction so it shows in cashflow and deducts from account
        let savingsCatId = categories.first(where: { $0.type == .savings })?.id ?? UUID()
        let liquidAccountId = accounts.first(where: { $0.isLiquid })?.id
        if let accountId = liquidAccountId {
            let userId = currentUserId
            let tx = Transaction(
                amount: -amount,   // negative = money leaving spending pool
                categoryId: savingsCatId,
                accountId: accountId,
                merchant: goal.name,
                note: "تحويل لهدف: \(goal.name)",
                ownerUserId: userId,
                createdByUserId: userId
            )
            addTransaction(tx)
        } else if isGuestMode {
            saveGuestData()
        }

        logActivity(.goalUpdated, objectType: "goal", description: goal.name)
    }

    func addInvestment(_ asset: InvestmentAsset) {
        investments.append(asset)
        if !isGuestMode {
            FirestoreService.shared.save(asset, to: "investments", householdId: currentHouseholdId)
        } else {
            saveGuestData()
        }
    }

    func updateInvestmentPrice(assetId: UUID, newPrice: Double) {
        guard var asset = investments.first(where: { $0.id == assetId }) else { return }
        asset.lastPrice = newPrice
        asset.lastPriceUpdated = Date()
        asset.updatedAt = Date()
        if let idx = investments.firstIndex(where: { $0.id == assetId }) {
            investments[idx] = asset
        }
        if !isGuestMode {
            FirestoreService.shared.save(asset, to: "investments", householdId: currentHouseholdId)
        } else {
            saveGuestData()
        }
    }

    func addInstallmentPlan(_ plan: InstallmentPlan) {
        let amount = plan.installmentAmount
        if isGuestMode {
            installmentPlans.append(plan)
            for i in 0..<plan.installmentsCount {
                let dueDate = Calendar.current.date(byAdding: .month, value: i, to: plan.startDate) ?? plan.startDate
                installments.append(Installment(planId: plan.id, amount: amount, dueDate: dueDate))
            }
            saveGuestData()
        } else {
            FirestoreService.shared.save(plan, to: "installmentPlans", householdId: currentHouseholdId)
            for i in 0..<plan.installmentsCount {
                let dueDate = Calendar.current.date(byAdding: .month, value: i, to: plan.startDate) ?? plan.startDate
                let installment = Installment(planId: plan.id, amount: amount, dueDate: dueDate)
                FirestoreService.shared.save(installment, to: "installments", householdId: currentHouseholdId)
            }
        }
    }

    func category(for id: UUID) -> TransactionCategory? {
        categories.first { $0.id == id }
    }

    // MARK: - Loans CRUD

    func addLoan(_ loan: Loan) {
        logActivity(.accountCreated, objectType: "loan", description: loan.name)
        if isGuestMode {
            loans.append(loan)
            loans.sort { $0.nextPaymentDate < $1.nextPaymentDate }
            saveGuestData()
        } else {
            FirestoreService.shared.save(loan, to: "loans", householdId: currentHouseholdId)
        }
    }

    func updateLoan(_ loan: Loan) {
        if let idx = loans.firstIndex(where: { $0.id == loan.id }) { loans[idx] = loan }
        if !isGuestMode {
            FirestoreService.shared.save(loan, to: "loans", householdId: currentHouseholdId)
        } else {
            saveGuestData()
        }
    }

    func deleteLoan(id: UUID) {
        loans.removeAll { $0.id == id }
        if !isGuestMode {
            FirestoreService.shared.delete(id: id, from: "loans", householdId: currentHouseholdId)
        } else {
            saveGuestData()
        }
    }

    /// Records a loan payment: decreases remaining balance, creates an expense transaction.
    func makeLoanPayment(_ loan: Loan, amount: Double) {
        guard amount > 0 else { return }

        // 1. Reduce loan balance
        var updated = loan
        updated.remainingBalance = max(0, updated.remainingBalance - amount)
        updated.nextPaymentDate = Calendar.current.date(byAdding: .month, value: 1, to: loan.nextPaymentDate) ?? loan.nextPaymentDate
        updated.updatedAt = Date()
        updateLoan(updated)

        // 2. Create expense transaction to deduct from liquid account
        guard let liquidAccount = visibleAccounts.first(where: { $0.isLiquid }) else { return }
        let loanCatId = categories.first(where: {
            $0.parentCategory == .financial && $0.type == .expense
        })?.id ?? categories.first(where: { $0.type == .expense })?.id ?? UUID()

        let tx = Transaction(
            amount: -amount,
            categoryId: loanCatId,
            accountId: liquidAccount.id,
            merchant: loan.name,
            note: "سداد قرض: \(loan.loanType.displayNameArabic)",
            ownerUserId: currentUserId,
            createdByUserId: currentUserId
        )
        addTransaction(tx)
        logActivity(.transactionCreated, objectType: "loan", description: "سداد: \(loan.name)")
    }

    func reset() {
        if isGuestMode {
            clearAll()
            try? FileManager.default.removeItem(at: Self.guestDataURL)
            return
        }
        guard let user = UserService.shared.currentUser else { return }
        let hid = user.householdId
        let fs = FirestoreService.shared
        for collection in ["accounts", "transactions", "savingsGoals", "bills", "investments",
                           "installmentPlans", "installments", "activityLog", "budgets", "loans"] {
            fs.collection(collection, householdId: hid).getDocuments { snap, _ in
                snap?.documents.forEach { $0.reference.delete() }
            }
        }
    }
}

// MARK: - Guest Data Persistence

private struct GuestSnapshot: Codable {
    var accounts: [Account]
    var transactions: [Transaction]
    var savingsGoals: [SavingsGoal]
    var bills: [Bill]
    var investments: [InvestmentAsset]
    var installmentPlans: [InstallmentPlan]
    var installments: [Installment]
    var budgets: [Budget]
    var loans: [Loan]
}

// MARK: - Date Helper
private extension Date {
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
