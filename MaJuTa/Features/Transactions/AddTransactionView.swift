import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var amountText: String = ""
    @State private var merchant: String = ""
    @State private var note: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedCategory: TransactionCategory?
    @State private var selectedAccount: Account?
    @State private var selectedPaymentMethod: PaymentMethod = .mada
    @State private var isExpense: Bool = true
    @State private var showCategoryPicker = false
    @State private var showReceiptScanner = false
    @State private var isSaving = false

    var amount: Double {
        (amountText.arabicNormalizedDouble ?? 0) * (isExpense ? -1 : 1)
    }

    var isValid: Bool {
        (amountText.arabicNormalizedDouble ?? 0) > 0 && selectedCategory != nil && selectedAccount != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.lg) {
                    // Amount Entry
                    amountSection

                    // Type Toggle
                    typeToggle

                    // Fields
                    fieldsSection

                    // Category
                    categorySection

                    // Actions
                    actionButtons
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.vertical, MaJuTaSpacing.lg)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("إضافة معاملة"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("إلغاء")) { dismiss() }
                        .foregroundColor(.maJuTaTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("حفظ")) { saveTransaction() }
                        .font(.maJuTaBodyBold)
                        .foregroundColor(isValid && !isSaving ? .maJuTaGold : .maJuTaTextSecondary)
                        .disabled(!isValid || isSaving)
                }
            }
        }
    }

    // MARK: - Amount Section
    private var amountSection: some View {
        VStack(spacing: MaJuTaSpacing.sm) {
            HStack(alignment: .lastTextBaseline, spacing: MaJuTaSpacing.sm) {
                Text("\u{E900}")
                    .font(.custom(maJuTaRiyalFontName, size: 28))
                    .foregroundColor(.maJuTaTextSecondary)
                TextField("0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.maJuTaHero)
                    .foregroundColor(.maJuTaTextPrimary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity)
            }
            .padding(MaJuTaSpacing.lg)
            .background(Color.maJuTaCard)
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            .maJuTaCardShadow()
        }
    }

    // MARK: - Income / Expense Toggle
    private var typeToggle: some View {
        HStack(spacing: 0) {
            toggleButton(title: L("مصروف"), icon: "arrow.up.circle.fill", isSelected: isExpense) {
                isExpense = true
            }
            toggleButton(title: L("دخل"), icon: "arrow.down.circle.fill", isSelected: !isExpense) {
                isExpense = false
            }
        }
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
        .maJuTaCardShadow()
    }

    private func toggleButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MaJuTaSpacing.xs) {
                Image(systemName: icon)
                Text(title)
                    .font(.maJuTaBodyMedium)
            }
            .foregroundColor(isSelected ? .white : .maJuTaTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MaJuTaSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MaJuTaRadius.button)
                    .fill(isSelected ? (isExpense ? Color.maJuTaNegative : Color.maJuTaPositive) : Color.clear)
            )
            .padding(4)
        }
        .accessibilityLabel(isSelected ? L("النوع المحدد: \(title)") : L("تحديد \(title)"))
    }

    // MARK: - Fields
    private var fieldsSection: some View {
        VStack(spacing: 1) {
            inputRow(label: L("التاجر / المصدر")) {
                TextField(L("مثال: كارفور، جهة العمل"), text: $merchant)
                    .font(.maJuTaBody)
                    .multilineTextAlignment(.trailing)
            }

            Divider().padding(.leading, MaJuTaSpacing.md)

            inputRow(label: L("طريقة الدفع")) {
                Menu {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        Button(method.displayName) {
                            selectedPaymentMethod = method
                        }
                    }
                } label: {
                    HStack(spacing: MaJuTaSpacing.xs) {
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                        Text(selectedPaymentMethod.displayName)
                            .font(.maJuTaBody)
                    }
                    .foregroundColor(.maJuTaGold)
                }
            }

            Divider().padding(.leading, MaJuTaSpacing.md)

            inputRow(label: L("الحساب")) {
                Menu {
                    ForEach(dataStore.accounts) { account in
                        Button(account.name) {
                            selectedAccount = account
                        }
                    }
                } label: {
                    HStack(spacing: MaJuTaSpacing.xs) {
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                        Text(selectedAccount?.name ?? L("اختر حساباً"))
                            .font(.maJuTaBody)
                    }
                    .foregroundColor(selectedAccount == nil ? .maJuTaTextSecondary : .maJuTaGold)
                }
            }

            Divider().padding(.leading, MaJuTaSpacing.md)

            inputRow(label: L("التاريخ")) {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "en_SA"))
            }

            Divider().padding(.leading, MaJuTaSpacing.md)

            inputRow(label: L("ملاحظة")) {
                TextField(L("اختياري"), text: $note)
                    .font(.maJuTaBody)
                    .multilineTextAlignment(.trailing)
            }
        }
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func inputRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            content()
            Spacer()
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
        }
        .padding(MaJuTaSpacing.md)
    }

    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            Text(L("الفئة"))
                .font(.maJuTaSectionTitle)
                .foregroundColor(.maJuTaTextPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: MaJuTaSpacing.sm) {
                ForEach(dataStore.categories.filter {
                    $0.type == (isExpense ? .expense : .income)
                }) { cat in
                    categoryButton(cat)
                }
            }
        }
    }

    private func categoryButton(_ cat: TransactionCategory) -> some View {
        Button {
            selectedCategory = cat
        } label: {
            VStack(spacing: MaJuTaSpacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: MaJuTaRadius.small)
                        .fill(Color(hex: cat.colorHex).opacity(selectedCategory?.id == cat.id ? 0.3 : 0.1))
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: MaJuTaRadius.small)
                                .stroke(Color(hex: cat.colorHex), lineWidth: selectedCategory?.id == cat.id ? 2 : 0)
                        )
                    Image(systemName: cat.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: cat.colorHex))
                }
                Text(cat.displayName)
                    .font(.maJuTaLabel)
                    .foregroundColor(.maJuTaTextSecondary)
                    .lineLimit(1)
            }
        }
        .accessibilityLabel(selectedCategory?.id == cat.id ? L("الفئة المحددة: \(cat.displayName)") : L("اختيار فئة \(cat.displayName)"))
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: MaJuTaSpacing.md) {
            Button {
                showReceiptScanner = true
            } label: {
                Label(L("مسح فاتورة"), systemImage: "camera.viewfinder")
                    .font(.maJuTaBodyMedium)
                    .foregroundColor(.maJuTaGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.maJuTaGold.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
            }
            .accessibilityLabel(L("مسح فاتورة بالكاميرا"))

            Button(action: saveTransaction) {
                Text(L("حفظ المعاملة"))
                    .font(.maJuTaBodyBold)
                    .foregroundColor(isValid && !isSaving ? .white : .maJuTaTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isValid && !isSaving ? Color.maJuTaPrimary : Color.maJuTaBackground)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
            }
            .disabled(!isValid || isSaving)
            .accessibilityLabel(L("حفظ المعاملة الجديدة"))
        }
        .sheet(isPresented: $showReceiptScanner) {
            ReceiptScannerView()
        }
    }

    // MARK: - Save
    private func saveTransaction() {
        guard !isSaving, let cat = selectedCategory, let account = selectedAccount else { return }
        isSaving = true
        let userId = UserService.shared.currentUser?.id ?? UUID()
        let tx = Transaction(
            amount: amount,
            date: selectedDate,
            categoryId: cat.id,
            accountId: account.id,
            merchant: merchant,
            paymentMethod: selectedPaymentMethod,
            note: note,
            ownerUserId: userId,
            createdByUserId: userId
        )
        dataStore.addTransaction(tx)
        dismiss()
    }
}
