import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showNotifications = false
    @State private var showSetLimit = false
    @State private var limitInput = ""

    // Color of spending card based on how much of the limit has been spent
    var spendingLimitColor: Color {
        let limit = appState.spendingLimit
        guard limit > 0 else { return .maJuTaGold }
        let spent = dataStore.discretionaryExpensesThisMonth
        let remaining = limit - spent
        let pct = remaining / limit
        if remaining < 0 || pct <= 0.05 { return .maJuTaNegative }
        if pct <= 0.20 { return .maJuTaWarning }
        return .maJuTaPositive
    }

    // Amount shown in the spending card — budget remaining when limit is set, otherwise income-based net
    var spendingCardAmount: Double {
        let limit = appState.spendingLimit
        guard limit > 0 else { return dataStore.monthlyNetFromIncome }
        return max(0, limit - dataStore.discretionaryExpensesThisMonth)
    }

    var spendingCardLabel: String {
        let limit = appState.spendingLimit
        guard limit > 0 else {
            return dataStore.monthlyNetFromIncome >= 0 ? L("المتاح للإنفاق") : L("تجاوزت ميزانيتك")
        }
        let remaining = limit - dataStore.discretionaryExpensesThisMonth
        return remaining < 0 ? L("تجاوزت الحد بـ") : L("باقي من ميزانيتك")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Header
                    dashboardHeader

                    // Main Metrics
                    VStack(spacing: MaJuTaSpacing.md) {
                        cashFlowRow
                        safeToSpendCard
                        financialMetricsGrid
                        upcomingBillsSection
                        recentTransactionsSection
                        healthScoreSection
                    }
                    .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                    .padding(.top, MaJuTaSpacing.md)
                    .padding(.bottom, MaJuTaSpacing.xxxl)
                }
            }
            .background(Color.maJuTaBackground)
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
                    .environmentObject(dataStore)
            }
        }
    }

    // MARK: - Header (Navy Card)
    private var dashboardHeader: some View {
        ZStack(alignment: .bottom) {
            LinearGradient.navyGradient
                .ignoresSafeArea(edges: .top)
                .frame(height: 260)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        showNotifications = true
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .accessibilityLabel(L("الإشعارات"))

                    Spacer()

                    VStack(spacing: 2) {
                        Text("\(L("مرحباً،")) \(appState.userName.isEmpty ? L("بك") : appState.userName)")
                            .font(.maJuTaCaption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(Date().monthYearLocalized)
                            .font(.maJuTaCaptionMedium)
                            .foregroundColor(.white)
                        if UserDefaults.standard.string(forKey: "appLanguage") != "en" {
                            Text(Date().hijriMonthYear)
                                .font(.maJuTaLabel)
                                .foregroundColor(.white.opacity(0.65))
                        }
                    }

                    Spacer()

                    // Avatar
                    Group {
                        if let img = appState.profileImage {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            let initial = appState.userName.isEmpty
                                ? (UserService.shared.currentUser?.name.prefix(1) ?? "م")
                                : appState.userName.prefix(1)
                            Circle()
                                .fill(LinearGradient.goldGradient)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(initial.uppercased())
                                        .font(.maJuTaBodyBold)
                                        .foregroundColor(.maJuTaPrimary)
                                )
                        }
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.top, 16)

                Spacer()

                // Income-based net available (income minus all outflows this month)
                VStack(spacing: 4) {
                    Text(dataStore.monthlyNetFromIncome >= 0 ? L("المتاح للإنفاق") : L("تجاوزت الميزانية"))
                        .font(.maJuTaCaption)
                        .foregroundColor(.white.opacity(0.7))

                    SARText.hero(dataStore.monthlyNetFromIncome, color: .white)
                        .accessibilityLabel(L("المتاح للإنفاق: \(String(format: "%.0f", dataStore.monthlyNetFromIncome)) ريال سعودي"))

                    HStack(spacing: MaJuTaSpacing.sm) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                            SARText(dataStore.monthlyIncome(), size: 13, weight: .medium, color: .maJuTaPositive)
                        }
                        Text("•").foregroundColor(.white.opacity(0.3))
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                            SARText(dataStore.discretionaryExpensesThisMonth, size: 13, weight: .medium, color: .maJuTaNegative)
                        }
                    }
                    .font(.maJuTaCaptionMedium)
                }
                .padding(.bottom, MaJuTaSpacing.lg)
            }
        }
    }

    // MARK: - Cash Flow Row (Income / Expense / Savings)
    private var cashFlowRow: some View {
        HStack(spacing: MaJuTaSpacing.sm) {
            cashFlowMiniCard(
                title: L("الدخل"),
                amount: dataStore.monthlyIncome(),
                icon: "arrow.down.circle.fill",
                color: .maJuTaPositive
            )
            cashFlowMiniCard(
                title: L("المصاريف"),
                amount: dataStore.discretionaryExpensesThisMonth,
                icon: "arrow.up.circle.fill",
                color: .maJuTaNegative
            )
            cashFlowMiniCard(
                title: L("الأهداف المحفوظة"),
                amount: dataStore.totalGoalsSaved,
                icon: "banknote.fill",
                color: .maJuTaGold
            )
        }
    }

    private func cashFlowMiniCard(title: String, amount: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            SARText.mediumNumber(amount)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(title)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    // MARK: - Safe To Spend Card
    private var safeToSpendCard: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            HStack {
                HStack(spacing: MaJuTaSpacing.xs) {
                    NavigationLink(destination: FinancialHealthView()) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.maJuTaTextSecondary)
                    }
                    .accessibilityLabel(L("عرض الصحة المالية"))
                    Button {
                        limitInput = appState.spendingLimit > 0 ? String(format: "%.0f", appState.spendingLimit) : ""
                        showSetLimit = true
                    } label: {
                        Image(systemName: appState.spendingLimit > 0 ? "slider.horizontal.3" : "plus.circle")
                            .foregroundColor(spendingLimitColor)
                            .font(.system(size: 16))
                    }
                    .accessibilityLabel(appState.spendingLimit > 0 ? L("تعديل حد الإنفاق") : L("تعيين حد الإنفاق"))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(spendingCardLabel)
                        .font(.maJuTaCaptionMedium)
                        .foregroundColor(spendingCardAmount >= 0 ? .maJuTaTextSecondary : .maJuTaNegative)
                    if appState.spendingLimit > 0 {
                        (Text("\(L("أنفقت:")) \(String(format: "%.0f", dataStore.discretionaryExpensesThisMonth)) ").font(.maJuTaLabel)
                         + Text("\u{E900}").font(.custom(maJuTaRiyalFontName, size: 11))
                         + Text(" \(L("من")) \(String(format: "%.0f", appState.spendingLimit)) ").font(.maJuTaLabel)
                         + Text("\u{E900}").font(.custom(maJuTaRiyalFontName, size: 11)))
                        .foregroundColor(spendingLimitColor)
                    }
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("")
                    .font(.maJuTaBody)
                    .foregroundColor(.maJuTaTextSecondary)
                SARText.hero(spendingCardAmount,
                    color: spendingCardAmount > 0 ? .maJuTaTextPrimary : .maJuTaNegative)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            // Breakdown
            HStack(spacing: MaJuTaSpacing.md) {
                Spacer()
                breakdownItem(label: L("فواتير قادمة"), amount: dataStore.upcomingBillsTotal, color: .maJuTaWarning)
                breakdownItem(label: L("مدخرات مخططة"), amount: dataStore.plannedSavingsThisMonth, color: .maJuTaGold)
                emergencyBreakdownItem
            }
            .padding(.top, 4)
        }
        .padding(MaJuTaSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: MaJuTaRadius.card)
                .fill(Color.maJuTaCard)
                .overlay(
                    RoundedRectangle(cornerRadius: MaJuTaRadius.card)
                        .strokeBorder(spendingLimitColor, lineWidth: appState.spendingLimit > 0 ? 2 : 1)
                )
        )
        .maJuTaCardShadow()
        .sheet(isPresented: $showSetLimit) {
            SpendingLimitSheet(limitInput: $limitInput, onSave: { value in
                appState.spendingLimit = value
            })
        }
    }

    private func breakdownItem(label: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            SARText.compact(amount, color: color)
            Text(label)
                .font(.maJuTaLabel)
                .foregroundColor(.maJuTaTextSecondary)
        }
    }

    /// Emergency fund breakdown item — shows actual funded amount this month with status color.
    private var emergencyBreakdownItem: some View {
        let deposited = dataStore.emergencyDepositsThisMonth
        let target = dataStore.emergencyMonthlyContribution
        let color: Color = deposited >= target && target > 0 ? .maJuTaPositive
                         : deposited == 0 ? .maJuTaNegative
                         : .maJuTaWarning
        let label: String = deposited >= target && target > 0 ? "\(L("طوارئ")) ✓" : L("طوارئ")

        return VStack(alignment: .trailing, spacing: 2) {
            SARText.compact(deposited > 0 ? deposited : target, color: color)
            Text(label)
                .font(.maJuTaLabel)
                .foregroundColor(color)
        }
    }

    // MARK: - Financial Metrics Grid
    private var financialMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MaJuTaSpacing.sm) {
            metricCard(
                title: L("صندوق الطوارئ"),
                amount: dataStore.emergencyFundBalance,
                suffix: "",
                icon: "exclamationmark.shield.fill",
                color: dataStore.emergencyMonths >= 3 ? .maJuTaPositive
                     : dataStore.emergencyMonths >= 1 ? .maJuTaWarning
                     : .maJuTaNegative
            )
            metricCard(
                title: L("صافي الثروة"),
                amount: dataStore.netWorth,
                suffix: "",
                icon: "chart.line.uptrend.xyaxis",
                color: .maJuTaGold
            )
            metricCard(
                title: L("المحفظة الاستثمارية"),
                amount: dataStore.portfolioValue,
                suffix: "",
                icon: "chart.bar.fill",
                color: .maJuTaOrange
            )
            metricCard(
                title: L("معدل الادخار"),
                value: String(format: "%.0f", dataStore.actualSavingsRate),
                suffix: "%",
                icon: "percent",
                color: dataStore.actualSavingsRate >= 20 ? .maJuTaPositive : .maJuTaGold
            )
        }
    }

    private func metricCard(title: String, value: String = "", amount: Double? = nil, suffix: String, icon: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            HStack {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            if let a = amount {
                SARText.compact(a, color: color)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(suffix)
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                    Text(value)
                        .font(.maJuTaMediumNumber)
                        .foregroundColor(.maJuTaTextPrimary)
                }
            }
            Text(title)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    // MARK: - Upcoming Bills
    private var upcomingBillsSection: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            HStack {
                NavigationLink(destination: BillsView()) {
                    Text(L("عرض الكل"))
                        .font(.maJuTaCaptionMedium)
                        .foregroundColor(.maJuTaGold)
                }
                .accessibilityLabel(L("عرض جميع الفواتير"))
                Spacer()
                Text(L("الفواتير القادمة"))
                    .font(.maJuTaSectionTitle)
                    .foregroundColor(.maJuTaTextPrimary)
            }

            let upcomingVisible = dataStore.visibleBills.filter { $0.status == .upcoming && !$0.isOverdue }
                .sorted { $0.dueDate < $1.dueDate }
            if upcomingVisible.isEmpty {
                emptyStateView(icon: "checkmark.circle.fill", text: L("لا توجد فواتير قادمة"))
            } else {
                VStack(spacing: MaJuTaSpacing.sm) {
                    ForEach(upcomingVisible.prefix(3)) { bill in
                        BillRowView(bill: bill, onPay: {
                            DataStore.shared.payBill(bill)
                        })
                        .environmentObject(dataStore)
                    }
                }
            }
        }
    }

    // MARK: - Recent Transactions
    private var recentTransactionsSection: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            HStack {
                NavigationLink(destination: TransactionsListView()) {
                    Text(L("عرض الكل"))
                        .font(.maJuTaCaptionMedium)
                        .foregroundColor(.maJuTaGold)
                }
                .accessibilityLabel(L("عرض جميع المعاملات"))
                Spacer()
                Text(L("آخر المعاملات"))
                    .font(.maJuTaSectionTitle)
                    .foregroundColor(.maJuTaTextPrimary)
            }

            VStack(spacing: 1) {
                ForEach(dataStore.visibleTransactions.prefix(5)) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            }
            .background(Color.maJuTaCard)
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            .maJuTaCardShadow()
        }
    }

    // MARK: - Health Score
    private var healthScoreSection: some View {
        NavigationLink(destination: FinancialHealthView()) {
            let score = FinancialHealthEngine.calculateScore(
                savingsRate: CashFlowEngine.savingsRate(
                    savingsContributions: max(0, dataStore.netCashFlow()),
                    disposableIncome: dataStore.effectiveMonthlyIncome
                ),
                emergencyMonths: dataStore.emergencyMonths,
                debtRatio: dataStore.fixedObligationRatio,
                spendingStability: dataStore.spendingStability,
                hasData: !dataStore.transactions.isEmpty
            )

            HStack(spacing: MaJuTaSpacing.md) {
                VStack(alignment: .leading, spacing: MaJuTaSpacing.sm) {
                    Text(score.grade.description)
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                        .multilineTextAlignment(.trailing)
                    Text(L("اعرض التقرير الكامل"))
                        .font(.maJuTaCaptionMedium)
                        .foregroundColor(.maJuTaGold)
                }

                Spacer()

                // Score Gauge
                ZStack {
                    Circle()
                        .stroke(Color.maJuTaBackground, lineWidth: 8)
                        .frame(width: 72, height: 72)
                    Circle()
                        .trim(from: 0, to: score.total / 100)
                        .stroke(Color(hex: score.grade.colorHex), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(score.total))")
                            .font(.maJuTaBodyBold)
                            .foregroundColor(.maJuTaTextPrimary)
                        Text(score.grade.label)
                            .font(.maJuTaLabel)
                            .foregroundColor(Color(hex: score.grade.colorHex))
                    }
                }

                VStack(alignment: .trailing, spacing: MaJuTaSpacing.xs) {
                    Text(L("الصحة المالية"))
                        .font(.maJuTaSectionTitle)
                        .foregroundColor(.maJuTaTextPrimary)
                    Text(L("من 100 نقطة"))
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                }
            }
            .padding(MaJuTaSpacing.lg)
            .background(Color.maJuTaCard)
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            .maJuTaCardShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L("الصحة المالية — عرض التقرير الكامل"))
    }

    // MARK: - Notifications Sheet
    struct NotificationsView: View {
        @EnvironmentObject var dataStore: DataStore
        @Environment(\.dismiss) var dismiss

        private var overdueBills: [Bill] {
            dataStore.visibleBills.filter { $0.isOverdue }
        }
        private var dueSoonBills: [Bill] {
            dataStore.visibleBills.filter { $0.isDueSoon && !$0.isOverdue && $0.status != .paid }
        }

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: MaJuTaSpacing.md) {
                        if overdueBills.isEmpty && dueSoonBills.isEmpty {
                            VStack(spacing: MaJuTaSpacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48)).foregroundColor(.maJuTaPositive)
                                Text(L("لا توجد إشعارات جديدة"))
                                    .font(.maJuTaBody).foregroundColor(.maJuTaTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(MaJuTaSpacing.xxl)
                        }
                        if !overdueBills.isEmpty {
                            notifSection(title: L("فواتير متأخرة"), color: .maJuTaNegative, bills: overdueBills)
                        }
                        if !dueSoonBills.isEmpty {
                            notifSection(title: L("فواتير تستحق قريباً"), color: .maJuTaWarning, bills: dueSoonBills)
                        }
                    }
                    .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                    .padding(.vertical, MaJuTaSpacing.md)
                }
                .background(Color.maJuTaBackground)
                .navigationTitle(L("الإشعارات"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(L("إغلاق")) { dismiss() }
                            .foregroundColor(.maJuTaTextSecondary)
                            .accessibilityLabel(L("إغلاق الإشعارات"))
                    }
                }
            }
        }

        private func notifSection(title: String, color: Color, bills: [Bill]) -> some View {
            VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
                Text(title).font(.maJuTaCaption).foregroundColor(color)
                VStack(spacing: MaJuTaSpacing.xs) {
                    ForEach(bills) { bill in
                        HStack {
                            SARText.bodyBold(bill.amount, color: color)
                            Spacer()
                            Text(bill.nameArabic.isEmpty ? bill.name : bill.nameArabic)
                                .font(.maJuTaBody).foregroundColor(.maJuTaTextPrimary)
                        }
                        .padding(MaJuTaSpacing.md)
                        .background(color.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private func emptyStateView(icon: String, text: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: MaJuTaSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.maJuTaPositive)
                Text(text)
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
            }
            .padding(MaJuTaSpacing.xl)
            Spacer()
        }
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
    }
}

// MARK: - Spending Limit Sheet
private struct SpendingLimitSheet: View {
    @Binding var limitInput: String
    let onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var amount: Double { limitInput.arabicNormalizedDouble ?? 0 }

    var body: some View {
        NavigationStack {
            VStack(spacing: MaJuTaSpacing.xl) {
                VStack(spacing: MaJuTaSpacing.sm) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 48))
                        .foregroundColor(.maJuTaGold)
                    Text(L("حد الإنفاق الشهري"))
                        .font(.maJuTaTitle2)
                        .foregroundColor(.maJuTaTextPrimary)
                    Text(L("يتغير لون البطاقة تبعاً للمتبقي من ميزانيتك"))
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, MaJuTaSpacing.xl)

                // Color legend
                HStack(spacing: MaJuTaSpacing.md) {
                    legendItem(color: .maJuTaPositive, label: L("أكثر من 20%"))
                    legendItem(color: .maJuTaWarning, label: "5% - 20%")
                    legendItem(color: .maJuTaNegative, label: L("أقل من 5%"))
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)

                TextField("0", text: $limitInput)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.maJuTaTextPrimary)
                    .padding(MaJuTaSpacing.md)
                    .background(Color.maJuTaBackground)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                    .focused($focused)

                Button {
                    onSave(amount)
                    dismiss()
                } label: {
                    Group {
                        if amount > 0 {
                            Text("\(L("حفظ")) \(String(format: "%.0f", amount)) ").font(.maJuTaBodyBold)
                            + Text("\u{E900}").font(.custom(maJuTaRiyalFontName, size: 16))
                        } else {
                            Text(L("حفظ")).font(.maJuTaBodyBold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(MaJuTaSpacing.md)
                    .background(amount > 0 ? Color.maJuTaGold : Color.maJuTaTextSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .disabled(amount <= 0)
                .accessibilityLabel(amount > 0 ? L("حفظ حد الإنفاق: \(String(format: "%.0f", amount)) ريال سعودي") : L("حفظ حد الإنفاق"))

                if limitInput != "" {
                    Button(L("إزالة الحد")) {
                        onSave(0)
                        dismiss()
                    }
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
                    .accessibilityLabel(L("إزالة حد الإنفاق"))
                }

                Spacer()
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("حد الإنفاق"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("إلغاء")) { dismiss() }.foregroundColor(.maJuTaTextSecondary)
                }
            }
            .onAppear { focused = true }
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        VStack(spacing: 4) {
            Circle().fill(color).frame(width: 12, height: 12)
            Text(label).font(.maJuTaLabel).foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
