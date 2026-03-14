import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showNotifications = false

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

                    Spacer()

                    VStack(spacing: 2) {
                        Text("مرحباً، \(appState.userName.isEmpty ? "بك" : appState.userName)")
                            .font(.maJuTaCaption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(Date().monthYearArabic)
                            .font(.maJuTaCaptionMedium)
                            .foregroundColor(.white)
                        Text(Date().hijriMonthYear)
                            .font(.maJuTaLabel)
                            .foregroundColor(.white.opacity(0.65))
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

                // Net Cash Flow
                VStack(spacing: 4) {
                    Text("صافي التدفق النقدي")
                        .font(.maJuTaCaption)
                        .foregroundColor(.white.opacity(0.7))

                    SARText.hero(dataStore.netCashFlow(), color: .white)

                    HStack(spacing: MaJuTaSpacing.sm) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                            SARText(dataStore.monthlyIncome(), size: 13, weight: .medium, color: .maJuTaPositive)
                        }
                        Text("•").foregroundColor(.white.opacity(0.3))
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                            SARText(dataStore.monthlyExpenses(), size: 13, weight: .medium, color: .maJuTaNegative)
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
                title: "الدخل",
                amount: dataStore.monthlyIncome(),
                icon: "arrow.down.circle.fill",
                color: .maJuTaPositive
            )
            cashFlowMiniCard(
                title: "المصاريف",
                amount: dataStore.monthlyExpenses(),
                icon: "arrow.up.circle.fill",
                color: .maJuTaNegative
            )
            cashFlowMiniCard(
                title: "المدخرات",
                amount: dataStore.plannedSavingsThisMonth,
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
            Text(title)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
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
                NavigationLink(destination: FinancialHealthView()) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.maJuTaTextSecondary)
                }
                Spacer()
                Text(dataStore.safeToSpend >= 0 ? "يمكنك إنفاق اليوم" : "تجاوزت ميزانيتك بـ")
                    .font(.maJuTaCaptionMedium)
                    .foregroundColor(dataStore.safeToSpend >= 0 ? .maJuTaTextSecondary : .maJuTaNegative)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("")
                    .font(.maJuTaBody)
                    .foregroundColor(.maJuTaTextSecondary)
                SARText.hero(dataStore.safeToSpend,
                    color: dataStore.safeToSpend > 0 ? .maJuTaTextPrimary : .maJuTaNegative)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            // Breakdown
            HStack(spacing: MaJuTaSpacing.md) {
                Spacer()
                breakdownItem(label: "فواتير قادمة", amount: dataStore.upcomingBillsTotal, color: .maJuTaWarning)
                breakdownItem(label: "مدخرات مخططة", amount: dataStore.plannedSavingsThisMonth, color: .maJuTaGold)
                breakdownItem(label: "طوارئ", amount: dataStore.emergencyMonthlyContribution, color: .maJuTaPositive)
            }
            .padding(.top, 4)
        }
        .padding(MaJuTaSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: MaJuTaRadius.card)
                .fill(Color.maJuTaCard)
                .overlay(
                    RoundedRectangle(cornerRadius: MaJuTaRadius.card)
                        .strokeBorder(LinearGradient.goldGradient, lineWidth: 1)
                )
        )
        .maJuTaCardShadow()
    }

    private func breakdownItem(label: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            SARText.compact(amount, color: color)
            Text(label)
                .font(.maJuTaLabel)
                .foregroundColor(.maJuTaTextSecondary)
        }
    }

    // MARK: - Financial Metrics Grid
    private var financialMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MaJuTaSpacing.sm) {
            metricCard(
                title: "أشهر الطوارئ",
                value: String(format: "%.1f", dataStore.emergencyMonths),
                suffix: "شهر",
                icon: "exclamationmark.shield.fill",
                color: dataStore.emergencyMonths >= 3 ? .maJuTaPositive : .maJuTaNegative
            )
            metricCard(
                title: "صافي الثروة",
                amount: dataStore.netWorth,
                suffix: "",
                icon: "chart.line.uptrend.xyaxis",
                color: .maJuTaGold
            )
            metricCard(
                title: "المحفظة الاستثمارية",
                amount: dataStore.portfolioValue,
                suffix: "",
                icon: "chart.bar.fill",
                color: .maJuTaOrange
            )
            metricCard(
                title: "معدل الادخار",
                value: String(format: "%.0f", CashFlowEngine.savingsRate(
                    savingsContributions: max(0, dataStore.netCashFlow()),
                    disposableIncome: dataStore.effectiveMonthlyIncome
                )),
                suffix: "%",
                icon: "percent",
                color: .maJuTaPositive
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
                    Text("عرض الكل")
                        .font(.maJuTaCaptionMedium)
                        .foregroundColor(.maJuTaGold)
                }
                Spacer()
                Text("الفواتير القادمة")
                    .font(.maJuTaSectionTitle)
                    .foregroundColor(.maJuTaTextPrimary)
            }

            let upcomingVisible = dataStore.visibleBills.filter { $0.status == .upcoming && !$0.isOverdue }
                .sorted { $0.dueDate < $1.dueDate }
            if upcomingVisible.isEmpty {
                emptyStateView(icon: "checkmark.circle.fill", text: "لا توجد فواتير قادمة")
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
                    Text("عرض الكل")
                        .font(.maJuTaCaptionMedium)
                        .foregroundColor(.maJuTaGold)
                }
                Spacer()
                Text("آخر المعاملات")
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
                        .multilineTextAlignment(.leading)
                    Text("اعرض التقرير الكامل")
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
                    Text("الصحة المالية")
                        .font(.maJuTaSectionTitle)
                        .foregroundColor(.maJuTaTextPrimary)
                    Text("من 100 نقطة")
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
                                Text("لا توجد إشعارات جديدة")
                                    .font(.maJuTaBody).foregroundColor(.maJuTaTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(MaJuTaSpacing.xxl)
                        }
                        if !overdueBills.isEmpty {
                            notifSection(title: "فواتير متأخرة", color: .maJuTaNegative, bills: overdueBills)
                        }
                        if !dueSoonBills.isEmpty {
                            notifSection(title: "فواتير تستحق قريباً", color: .maJuTaWarning, bills: dueSoonBills)
                        }
                    }
                    .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                    .padding(.vertical, MaJuTaSpacing.md)
                }
                .background(Color.maJuTaBackground)
                .navigationTitle("الإشعارات")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("إغلاق") { dismiss() }
                            .foregroundColor(.maJuTaTextSecondary)
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
