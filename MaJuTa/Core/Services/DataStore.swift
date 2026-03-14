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

    // MARK: - Load / Subscribe

    func loadForCurrentUser() {
        // Remove old listeners
        listeners.forEach { $0.remove() }
        listeners.removeAll()

        // Clear local data
        accounts = []; transactions = []; savingsGoals = []
        bills = []; investments = []; installmentPlans = []
        installments = []; activityLog = []

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
    }

    // MARK: - Activity Logging

    private func logActivity(_ action: ActivityActionType, objectType: String, description: String) {
        guard let user = UserService.shared.currentUser else { return }
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

    // Actual goal contributions made this month (creates transactions, so tracked in cashflow)
    var goalContributionsThisMonth: Double {
        let savingsCatIds = Set(categories.filter { $0.type == .savings }.map { $0.id })
        let monthly = CashFlowEngine.transactions(from: visibleTransactions, in: Date())
        return monthly.filter { savingsCatIds.contains($0.categoryId) && $0.amount < 0 }
                      .reduce(0) { $0 + abs($1.amount) }
    }

    var safeToSpend: Double {
        // Subtract only REMAINING planned savings (already-contributed amounts are reflected in liquidCash)
        let remainingPlanned = max(0, plannedSavingsThisMonth - goalContributionsThisMonth)
        return CashFlowEngine.safeToSpend(
            liquidCash: totalLiquidCash,
            upcomingBills: upcomingBillsTotal,
            plannedSavings: remainingPlanned,
            emergencyContribution: emergencyMonthlyContribution
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
        visibleAccounts.filter { $0.type == .savings }.reduce(0) { $0 + $1.balance }
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

    var netWorth: Double {
        let assets = visibleAccounts.reduce(0) { $0 + $1.balance } + portfolioValue
        return CashFlowEngine.netWorth(totalAssets: assets, totalLiabilities: 0)
    }

    // Bills + BNPL installments = total monthly fixed obligations
    var fixedObligationRatio: Double {
        let income = effectiveMonthlyIncome
        guard income > 0 else { return 0 }
        return CashFlowEngine.fixedObligationRatio(
            fixedExpenses: upcomingBillsTotal + monthlyInstallmentPayments,
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
        FirestoreService.shared.save(account, to: "accounts", householdId: currentHouseholdId)
    }

    func withdrawFromEmergencyFund(amount: Double) {
        guard amount > 0 else { return }
        guard let idx = accounts.firstIndex(where: { $0.type == .savings }) else { return }
        let newBalance = max(0, accounts[idx].balance - amount)
        accounts[idx].balance = newBalance
        accounts[idx].updatedAt = Date()
        FirestoreService.shared.save(accounts[idx], to: "accounts", householdId: currentHouseholdId)
        logActivity(.transactionCreated, objectType: "account", description: "سحب من صندوق الطوارئ")
    }

    func depositToEmergencyFund(amount: Double) {
        guard amount > 0 else { return }
        if var account = accounts.first(where: { $0.type == .savings }) {
            account.balance += amount
            account.updatedAt = Date()
            if let idx = accounts.firstIndex(where: { $0.id == account.id }) { accounts[idx] = account }
            FirestoreService.shared.save(account, to: "accounts", householdId: currentHouseholdId)
        } else {
            // No savings account yet — create one automatically
            let account = Account(
                name: "صندوق الطوارئ",
                type: .savings,
                balance: amount,
                ownerUserId: currentUserId,
                householdId: currentHouseholdId
            )
            accounts.append(account)
            FirestoreService.shared.save(account, to: "accounts", householdId: currentHouseholdId)
        }
        logActivity(.transactionCreated, objectType: "account", description: "إيداع في صندوق الطوارئ")
    }

    func deleteTransaction(_ id: UUID) {
        guard let t = transactions.first(where: { $0.id == id }) else { return }
        // Reverse balance: update account
        if var account = accounts.first(where: { $0.id == t.accountId }) {
            account.balance -= t.amount
            account.updatedAt = Date()
            FirestoreService.shared.save(account, to: "accounts", householdId: currentHouseholdId)
        }
        logActivity(.transactionDeleted, objectType: "transaction", description: t.merchant)
        FirestoreService.shared.delete(id: id, from: "transactions", householdId: currentHouseholdId)
    }

    func addTransaction(_ transaction: Transaction) {
        // Update account balance
        if var account = accounts.first(where: { $0.id == transaction.accountId }) {
            account.balance += transaction.amount
            account.updatedAt = Date()
            FirestoreService.shared.save(account, to: "accounts", householdId: currentHouseholdId)
        }
        logActivity(.transactionCreated, objectType: "transaction", description: transaction.merchant)
        FirestoreService.shared.save(transaction, to: "transactions", householdId: currentHouseholdId)
    }

    func addBill(_ bill: Bill) {
        logActivity(.billCreated, objectType: "bill", description: bill.name)
        FirestoreService.shared.save(bill, to: "bills", householdId: currentHouseholdId)
    }

    func payBill(_ bill: Bill) {
        guard var updated = bills.first(where: { $0.id == bill.id }) else { return }
        updated.status = .paid
        updated.updatedAt = Date()
        // Optimistic local update
        if let idx = bills.firstIndex(where: { $0.id == bill.id }) { bills[idx] = updated }
        FirestoreService.shared.save(updated, to: "bills", householdId: currentHouseholdId)
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
        if bill.frequency != .custom {
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
        FirestoreService.shared.save(goal, to: "savingsGoals", householdId: currentHouseholdId)
    }

    func contribute(to goal: SavingsGoal, amount: Double) {
        guard amount > 0, var updated = savingsGoals.first(where: { $0.id == goal.id }) else { return }

        // 1. Update goal balance
        updated.currentAmount += amount
        updated.updatedAt = Date()
        if let idx = savingsGoals.firstIndex(where: { $0.id == goal.id }) { savingsGoals[idx] = updated }
        FirestoreService.shared.save(updated, to: "savingsGoals", householdId: currentHouseholdId)

        // 2. Create a savings transaction so it shows in cashflow and deducts from account
        let savingsCatId = categories.first(where: { $0.type == .savings })?.id ?? UUID()
        let accountId = visibleAccounts.first(where: { $0.isLiquid })?.id ?? UUID()
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

        logActivity(.goalUpdated, objectType: "goal", description: goal.name)
    }

    func addInvestment(_ asset: InvestmentAsset) {
        investments.append(asset)
        FirestoreService.shared.save(asset, to: "investments", householdId: currentHouseholdId)
    }

    func updateInvestmentPrice(assetId: UUID, newPrice: Double) {
        guard var asset = investments.first(where: { $0.id == assetId }) else { return }
        asset.lastPrice = newPrice
        asset.lastPriceUpdated = Date()
        asset.updatedAt = Date()
        // Optimistic local update so detail view refreshes immediately
        if let idx = investments.firstIndex(where: { $0.id == assetId }) {
            investments[idx] = asset
        }
        FirestoreService.shared.save(asset, to: "investments", householdId: currentHouseholdId)
    }

    func addInstallmentPlan(_ plan: InstallmentPlan) {
        FirestoreService.shared.save(plan, to: "installmentPlans", householdId: currentHouseholdId)
        let amount = plan.installmentAmount
        for i in 0..<plan.installmentsCount {
            let dueDate = Calendar.current.date(byAdding: .month, value: i, to: plan.startDate) ?? plan.startDate
            let installment = Installment(planId: plan.id, amount: amount, dueDate: dueDate)
            FirestoreService.shared.save(installment, to: "installments", householdId: currentHouseholdId)
        }
    }

    func category(for id: UUID) -> TransactionCategory? {
        categories.first { $0.id == id }
    }

    func reset() {
        guard let user = UserService.shared.currentUser else { return }
        let hid = user.householdId
        let fs = FirestoreService.shared
        // Delete all collections in Firestore
        for collection in ["accounts", "transactions", "savingsGoals", "bills", "investments", "installmentPlans", "installments", "activityLog"] {
            fs.collection(collection, householdId: hid).getDocuments { snap, _ in
                snap?.documents.forEach { $0.reference.delete() }
            }
        }
        // Clear listeners will update local state to empty via snapshots
    }
}

// MARK: - Date Helper
private extension Date {
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
