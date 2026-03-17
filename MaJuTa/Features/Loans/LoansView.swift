import SwiftUI

// MARK: - LoansView

struct LoansView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddLoan = false

    private var activeLoans: [Loan] {
        dataStore.visibleLoans.filter { !$0.isFullyPaid }
            .sorted { $0.nextPaymentDate < $1.nextPaymentDate }
    }
    private var paidLoans: [Loan] {
        dataStore.visibleLoans.filter { $0.isFullyPaid }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.md) {
                    summaryCard
                    if !activeLoans.isEmpty {
                        loanSection(title: L("القروض النشطة"), loans: activeLoans)
                    }
                    if !paidLoans.isEmpty {
                        loanSection(title: L("مسددة بالكامل"), loans: paidLoans)
                    }
                    if dataStore.visibleLoans.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.vertical, MaJuTaSpacing.md)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("القروض"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showAddLoan = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.maJuTaGold)
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showAddLoan) {
                AddLoanView().environmentObject(dataStore)
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: MaJuTaSpacing.sm) {
            HStack(spacing: MaJuTaSpacing.sm) {
                summaryBox(label: L("إجمالي المديونية"), amount: dataStore.totalLoanBalance, color: .maJuTaNegative)
                summaryBox(label: L("الدفع الشهري"), amount: dataStore.monthlyLoanPayments, color: .maJuTaGold)
            }
            HStack(spacing: MaJuTaSpacing.sm) {
                summaryCountBox(label: L("قروض نشطة"), count: activeLoans.count, color: .maJuTaTextPrimary)
                summaryCountBox(label: L("ديون التزامات / دخل"), value: String(format: "%.0f%%", dataStore.debtObligationRatio * 100), color: dataStore.debtObligationRatio > 0.4 ? .maJuTaNegative : .maJuTaPositive)
            }
        }
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func summaryBox(label: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            SARText.bodyBold(amount, color: color)
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaBackground)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.small))
    }

    private func summaryCountBox(label: String, count: Int, color: Color) -> some View {
        summaryCountBox(label: label, value: "\(count)", color: color)
    }

    private func summaryCountBox(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(value)
                .font(.maJuTaBodyBold)
                .foregroundColor(color)
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaBackground)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.small))
    }

    // MARK: - Loan Section

    private func loanSection(title: String, loans: [Loan]) -> some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            Text(title)
                .font(.maJuTaSectionTitle)
                .foregroundColor(.maJuTaTextPrimary)

            VStack(spacing: 1) {
                ForEach(loans) { loan in
                    NavigationLink(
                        destination: LoanDetailView(loanId: loan.id)
                            .environmentObject(dataStore)
                    ) {
                        LoanRowView(loan: loan)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.maJuTaCard)
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            .maJuTaCardShadow()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MaJuTaSpacing.md) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 52))
                .foregroundColor(.maJuTaTextSecondary.opacity(0.4))
            Text(L("لا توجد قروض مسجلة"))
                .font(.maJuTaSectionTitle)
                .foregroundColor(.maJuTaTextSecondary)
            Text(L("أضف قروضك لتتبع الأرصدة والدفعات الشهرية"))
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.xxl)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
    }
}

// MARK: - LoanRowView

struct LoanRowView: View {
    let loan: Loan

    var body: some View {
        HStack(spacing: MaJuTaSpacing.md) {
            // Amount + progress
            VStack(alignment: .trailing, spacing: 4) {
                SARText.bodyBold(loan.remainingBalance, color: loan.isFullyPaid ? .maJuTaPositive : .maJuTaNegative)
                Text(loan.isFullyPaid ? L("مسدد بالكامل") : "\(Int(loan.percentagePaid))% " + L("مسدد"))
                    .font(.maJuTaLabel)
                    .foregroundColor(loan.percentagePaid >= 50 ? .maJuTaPositive : .maJuTaGold)
            }

            Spacer()

            // Name + due
            VStack(alignment: .trailing, spacing: 4) {
                Text(loan.name)
                    .font(.maJuTaBodyMedium)
                    .foregroundColor(.maJuTaTextPrimary)
                if !loan.isFullyPaid {
                    Text(loan.isPaymentOverdue ? L("متأخر") : (loan.isPaymentDueSoon ? L("قريباً") : "\(loan.monthsRemaining) " + L("شهر متبقي")))
                        .font(.maJuTaLabel)
                        .foregroundColor(loan.isPaymentOverdue ? .maJuTaNegative : .maJuTaTextSecondary)
                }
            }

            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: MaJuTaRadius.small)
                    .fill(Color(hex: loan.loanType.colorHex).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: loan.loanType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: loan.loanType.colorHex))
            }
        }
        .padding(MaJuTaSpacing.md)
    }
}

// MARK: - AddLoanView

struct AddLoanView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var selectedType: LoanType = .personal
    @State private var principalText = ""
    @State private var remainingText = ""
    @State private var monthlyText = ""
    @State private var interestText = ""
    @State private var startDate = Date()
    @State private var nextPaymentDate: Date = {
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }()

    private var canSave: Bool {
        !name.isEmpty && (Double(remainingText) ?? 0) > 0 && (Double(monthlyText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.lg) {
                    // Loan type selector
                    typeSelector

                    // Fields
                    VStack(spacing: 0) {
                        fieldRow(label: L("اسم القرض")) {
                            TextField(L("مثال: قرض البنك الأهلي"), text: $name)
                                .multilineTextAlignment(.trailing)
                        }
                        divider()
                        fieldRow(label: L("المبلغ الأصلي (﷼)")) {
                            TextField("0", text: $principalText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        divider()
                        fieldRow(label: L("الرصيد المتبقي (﷼)")) {
                            TextField("0", text: $remainingText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        divider()
                        fieldRow(label: L("الدفعة الشهرية (﷼)")) {
                            TextField("0", text: $monthlyText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        divider()
                        fieldRow(label: L("نسبة الفائدة السنوية (%)")) {
                            TextField("0", text: $interestText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        divider()
                        fieldRow(label: L("تاريخ بداية القرض")) {
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        divider()
                        fieldRow(label: L("تاريخ الدفعة القادمة")) {
                            DatePicker("", selection: $nextPaymentDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    .maJuTaCardShadow()

                    // Save button
                    Button {
                        saveLoan()
                    } label: {
                        Text(L("حفظ القرض"))
                            .font(.maJuTaBodyBold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(canSave ? Color.maJuTaPrimary : Color.maJuTaTextSecondary.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                    }
                    .disabled(!canSave)
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.vertical, MaJuTaSpacing.md)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("قرض جديد"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("إلغاء")) { dismiss() }
                        .foregroundColor(.maJuTaTextSecondary)
                }
            }
        }
    }

    private var typeSelector: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            Text(L("نوع القرض"))
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
            HStack(spacing: MaJuTaSpacing.sm) {
                ForEach(LoanType.allCases, id: \.self) { type in
                    Button {
                        selectedType = type
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 20))
                            Text(type.displayNameArabic)
                                .font(.maJuTaLabel)
                                .multilineTextAlignment(.center)
                        }
                        .foregroundColor(selectedType == type ? Color(hex: type.colorHex) : .maJuTaTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MaJuTaSpacing.sm)
                        .background(
                            selectedType == type
                            ? Color(hex: type.colorHex).opacity(0.12)
                            : Color.maJuTaCard
                        )
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: MaJuTaRadius.small)
                                .strokeBorder(selectedType == type ? Color(hex: type.colorHex) : Color.clear, lineWidth: 1.5)
                        )
                    }
                }
            }
        }
    }

    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: MaJuTaSpacing.md) {
            content().font(.maJuTaBody)
            Spacer()
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
                .frame(width: 160, alignment: .trailing)
        }
        .padding(MaJuTaSpacing.md)
    }

    private func divider() -> some View {
        Divider().padding(.horizontal, MaJuTaSpacing.md)
    }

    private func saveLoan() {
        let principal = Double(principalText) ?? (Double(remainingText) ?? 0)
        let loan = Loan(
            householdId: dataStore.currentHouseholdId,
            ownerUserId: dataStore.currentUserId,
            name: name.trimmingCharacters(in: .whitespaces),
            loanType: selectedType,
            principalAmount: principal,
            remainingBalance: Double(remainingText) ?? 0,
            monthlyPayment: Double(monthlyText) ?? 0,
            interestRate: Double(interestText) ?? 0,
            startDate: startDate,
            nextPaymentDate: nextPaymentDate
        )
        dataStore.addLoan(loan)
        dismiss()
    }
}

// MARK: - LoanDetailView

struct LoanDetailView: View {
    let loanId: UUID
    @EnvironmentObject var dataStore: DataStore
    @State private var showPaySheet = false
    @State private var paymentText = ""
    @State private var showDeleteAlert = false

    private var loan: Loan? { dataStore.loans.first { $0.id == loanId } }

    var body: some View {
        Group {
            if let loan = loan {
                content(loan: loan)
            } else {
                Text(L("القرض غير موجود")).foregroundColor(.maJuTaTextSecondary)
            }
        }
        .background(Color.maJuTaBackground)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(loan: Loan) -> some View {
        ScrollView {
            VStack(spacing: MaJuTaSpacing.lg) {
                // Header
                headerCard(loan: loan)
                // Progress bar
                progressCard(loan: loan)
                // Stats grid
                statsGrid(loan: loan)
                // Pay button
                if !loan.isFullyPaid {
                    payButton(loan: loan)
                }
                // Delete
                Button {
                    showDeleteAlert = true
                } label: {
                    Text(L("حذف القرض"))
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaNegative.opacity(0.7))
                }
                .padding(.top, MaJuTaSpacing.sm)
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
            .padding(.vertical, MaJuTaSpacing.lg)
            .padding(.bottom, MaJuTaSpacing.xxxl)
        }
        .navigationTitle(loan.name)
        .alert(L("حذف القرض"), isPresented: $showDeleteAlert) {
            Button(L("إلغاء"), role: .cancel) {}
            Button(L("حذف"), role: .destructive) {
                dataStore.deleteLoan(id: loanId)
            }
        } message: {
            Text(L("سيتم حذف هذا القرض نهائياً."))
        }
        .sheet(isPresented: $showPaySheet) {
            paymentSheet(loan: loan)
        }
    }

    private func headerCard(loan: Loan) -> some View {
        HStack(spacing: MaJuTaSpacing.md) {
            VStack(alignment: .trailing, spacing: MaJuTaSpacing.xs) {
                Text(loan.isFullyPaid ? L("مسدد بالكامل ✓") : L("الرصيد المتبقي"))
                    .font(.maJuTaCaption)
                    .foregroundColor(loan.isFullyPaid ? .maJuTaPositive : .maJuTaTextSecondary)
                SARText.hero(loan.remainingBalance,
                             color: loan.isFullyPaid ? .maJuTaPositive : .maJuTaNegative)
                Text(L("من أصل") + " \(Int(loan.principalAmount).formatted()) ﷼")
                    .font(.maJuTaLabel)
                    .foregroundColor(.maJuTaTextSecondary)
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: MaJuTaRadius.card)
                    .fill(Color(hex: loan.loanType.colorHex).opacity(0.12))
                    .frame(width: 60, height: 60)
                Image(systemName: loan.loanType.icon)
                    .font(.system(size: 26))
                    .foregroundColor(Color(hex: loan.loanType.colorHex))
            }
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func progressCard(loan: Loan) -> some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            HStack {
                Text(String(format: "%.1f%%", loan.percentagePaid) + " " + L("مسدد"))
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
                Spacer()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.maJuTaBackground).frame(height: 10)
                    Capsule()
                        .fill(loan.percentagePaid >= 75 ? Color.maJuTaPositive : Color.maJuTaGold)
                        .frame(width: max(0, geo.size.width * CGFloat(loan.percentagePaid / 100)), height: 10)
                }
            }
            .frame(height: 10)
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func statsGrid(loan: Loan) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MaJuTaSpacing.sm) {
            statCell(label: L("الدفعة الشهرية"), amount: loan.monthlyPayment)
            statCell(label: L("نسبة الفائدة"), text: String(format: "%.1f%%", loan.interestRate))
            statCell(label: L("أشهر متبقية"), text: "\(loan.monthsRemaining) " + L("شهر"))
            statCell(label: L("تاريخ الإنهاء المتوقع"),
                     text: loan.isFullyPaid ? "—" : loan.estimatedPayoffDate.formatted(date: .abbreviated, time: .omitted))
            statCell(label: L("تاريخ الدفعة القادمة"),
                     text: loan.isFullyPaid ? "—" : loan.nextPaymentDate.formatted(date: .abbreviated, time: .omitted),
                     color: loan.isPaymentOverdue ? .maJuTaNegative : loan.isPaymentDueSoon ? .maJuTaWarning : .maJuTaTextPrimary)
            statCell(label: L("نوع القرض"), text: loan.loanType.displayNameArabic)
        }
    }

    private func statCell(label: String, amount: Double) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            SARText.compact(amount)
            Text(label).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func statCell(label: String, text: String, color: Color = .maJuTaTextPrimary) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(text).font(.maJuTaBodyBold).foregroundColor(color)
            Text(label).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func payButton(loan: Loan) -> some View {
        Button {
            paymentText = String(format: "%.0f", loan.monthlyPayment)
            showPaySheet = true
        } label: {
            Label(loan.isPaymentOverdue ? L("سداد (متأخر)") : L("سداد الدفعة"),
                  systemImage: "checkmark.circle.fill")
                .font(.maJuTaBodyMedium)
                .foregroundColor(loan.isPaymentOverdue ? .maJuTaNegative : .maJuTaPositive)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background((loan.isPaymentOverdue ? Color.maJuTaNegative : Color.maJuTaPositive).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
        }
    }

    private func paymentSheet(loan: Loan) -> some View {
        NavigationStack {
            VStack(spacing: MaJuTaSpacing.lg) {
                VStack(spacing: MaJuTaSpacing.xs) {
                    Text(L("مبلغ السداد"))
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                    HStack {
                        TextField("0", text: $paymentText)
                            .keyboardType(.decimalPad)
                            .font(.maJuTaLargeNumber)
                            .multilineTextAlignment(.trailing)
                        Text("﷼")
                            .font(.maJuTaTitle1)
                            .foregroundColor(.maJuTaGold)
                    }
                    .padding(MaJuTaSpacing.md)
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.input))
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.top, MaJuTaSpacing.xl)

                let remaining = max(0, loan.remainingBalance - (Double(paymentText) ?? 0))
                let remainingStr = String(format: "%.0f", remaining)
                Text(L("الرصيد المتبقي بعد السداد:") + " \(remainingStr) ﷼")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)

                Spacer()
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("سداد:") + " \(loan.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("إلغاء")) { showPaySheet = false }
                        .foregroundColor(.maJuTaTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("تأكيد")) {
                        if let amount = Double(paymentText), amount > 0 {
                            dataStore.makeLoanPayment(loan, amount: amount)
                        }
                        showPaySheet = false
                    }
                    .foregroundColor(.maJuTaGold)
                    .font(.maJuTaBodyBold)
                    .disabled((Double(paymentText) ?? 0) <= 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
