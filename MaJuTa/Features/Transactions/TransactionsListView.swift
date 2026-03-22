import SwiftUI

struct TransactionsListView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedCategory: TransactionCategory?
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var showFilters = false

    var filteredTransactions: [Transaction] {
        var result = dataStore.visibleTransactions
        if !searchText.isEmpty {
            result = result.filter {
                $0.merchant.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let cat = selectedCategory {
            result = result.filter { $0.categoryId == cat.id }
        }
        if let method = selectedPaymentMethod {
            result = result.filter { $0.paymentMethod == method }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                searchBar

                // Filter chips
                if showFilters { filterChips }

                // List
                if filteredTransactions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(filteredTransactions) { transaction in
                                NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                    TransactionRowView(transaction: transaction)
                                        .environmentObject(dataStore)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(L("\(transaction.merchant.isEmpty ? L("معاملة") : transaction.merchant) — \(String(format: "%.0f", abs(transaction.amount))) ريال سعودي"))
                            }
                        }
                        .background(Color.maJuTaCard)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                        .maJuTaCardShadow()
                        .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                        .padding(.vertical, MaJuTaSpacing.md)
                        .padding(.bottom, MaJuTaSpacing.xxxl)
                    }
                }
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("المعاملات"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation { showFilters.toggle() }
                    } label: {
                        Image(systemName: ActionIcon.filter)
                            .foregroundColor(.maJuTaGold)
                    }
                    .accessibilityLabel(showFilters ? L("إخفاء خيارات التصفية") : L("عرض خيارات التصفية"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appState.showAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.maJuTaGold)
                    }
                    .accessibilityLabel(L("إضافة معاملة جديدة"))
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: MaJuTaSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.maJuTaTextSecondary)
            TextField(L("بحث عن معاملة..."), text: $searchText)
                .font(.maJuTaBody)
                .multilineTextAlignment(.trailing)
        }
        .padding(MaJuTaSpacing.sm)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.input))
        .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
        .padding(.vertical, MaJuTaSpacing.sm)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MaJuTaSpacing.sm) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    filterChip(
                        title: method.displayName,
                        isSelected: selectedPaymentMethod == method
                    ) {
                        selectedPaymentMethod = selectedPaymentMethod == method ? nil : method
                    }
                }
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
        }
        .padding(.bottom, MaJuTaSpacing.sm)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.maJuTaCaptionMedium)
                .foregroundColor(isSelected ? .maJuTaPrimary : .maJuTaTextSecondary)
                .padding(.horizontal, MaJuTaSpacing.sm)
                .padding(.vertical, MaJuTaSpacing.xs)
                .background(isSelected ? Color.maJuTaGold : Color.maJuTaCard)
                .clipShape(Capsule())
        }
        .accessibilityLabel(isSelected ? L("إلغاء تصفية \(title)") : L("تصفية بـ\(title)"))
    }

    private var emptyState: some View {
        VStack(spacing: MaJuTaSpacing.md) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.maJuTaTextSecondary.opacity(0.5))
            Text(L("لا توجد معاملات"))
                .font(.maJuTaSectionTitle)
                .foregroundColor(.maJuTaTextSecondary)
            Text(L("أضف معاملتك الأولى بالضغط على +"))
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary.opacity(0.7))
            Spacer()
        }
    }
}

struct TransactionDetailView: View {
    let transaction: Transaction
    @EnvironmentObject var dataStore: DataStore

    var category: TransactionCategory? {
        dataStore.category(for: transaction.categoryId)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MaJuTaSpacing.lg) {
                // Amount Hero
                VStack(spacing: MaJuTaSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: category?.colorHex ?? "#6B7280").opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: category?.icon ?? "circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: category?.colorHex ?? "#6B7280"))
                    }
                    SARText(abs(transaction.amount), size: 40, weight: .bold,
                            color: transaction.amount > 0 ? .maJuTaPositive : .maJuTaTextPrimary)
                    Text(category?.displayName ?? "")
                        .font(.maJuTaBody)
                        .foregroundColor(.maJuTaTextSecondary)
                }
                .padding(.top, MaJuTaSpacing.lg)

                // Details
                VStack(spacing: 1) {
                    detailRow(label: L("التاجر"), value: transaction.merchant)
                    detailRow(label: L("التاريخ"), value: transaction.date.gregorianFormatted)
                    detailRow(label: L("الميلادي"), value: transaction.date.hijriFormatted)
                    detailRow(label: L("طريقة الدفع"), value: transaction.paymentMethod.displayName)
                    if !transaction.note.isEmpty {
                        detailRow(label: L("ملاحظة"), value: transaction.note)
                    }
                }
                .background(Color.maJuTaCard)
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                .maJuTaCardShadow()
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
            }
        }
        .background(Color.maJuTaBackground)
        .navigationTitle(transaction.merchant.isEmpty ? L("تفاصيل المعاملة") : transaction.merchant)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(value)
                .font(.maJuTaBody)
                .foregroundColor(.maJuTaTextPrimary)
            Spacer()
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
        }
        .padding(MaJuTaSpacing.md)
    }
}
