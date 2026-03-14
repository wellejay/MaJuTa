import SwiftUI

struct BillsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddBill = false

    var upcomingBills: [Bill] {
        dataStore.bills.filter { $0.status == .upcoming }.sorted { $0.dueDate < $1.dueDate }
    }
    var paidBills: [Bill] { dataStore.bills.filter { $0.status == .paid } }
    var overdueBills: [Bill] { dataStore.bills.filter { $0.isOverdue } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.md) {
                    billsSummaryCard
                    if !overdueBills.isEmpty { billSection(title: "متأخرة", bills: overdueBills, color: .maJuTaNegative) }
                    if !upcomingBills.isEmpty { billSection(title: "قادمة", bills: upcomingBills, color: .maJuTaGold) }
                    if !paidBills.isEmpty { billSection(title: "مدفوعة", bills: paidBills, color: .maJuTaPositive) }
                    if dataStore.bills.isEmpty { emptyBillsState }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.vertical, MaJuTaSpacing.md)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle("الفواتير والالتزامات")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAddBill = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(.maJuTaGold)
                    }
                }
            }
            .sheet(isPresented: $showAddBill) {
                AddBillView().environmentObject(dataStore)
            }
        }
    }

    private var billsSummaryCard: some View {
        HStack(spacing: MaJuTaSpacing.sm) {
            summaryItem(amount: upcomingBills.reduce(0) { $0 + $1.amount }, label: "إجمالي قادم", color: .maJuTaGold)
            summaryItem(value: "\(overdueBills.count)", label: "متأخرة", color: .maJuTaNegative)
            summaryItem(value: "\(upcomingBills.count)", label: "قادمة", color: .maJuTaTextPrimary)
        }
    }

    private func summaryItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.maJuTaBodyBold).foregroundColor(color)
            Text(label).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func summaryItem(amount: Double, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            SARText.bodyBold(amount, color: color)
            Text(label).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func billSection(title: String, bills: [Bill], color: Color) -> some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            Text(title).font(.maJuTaSectionTitle).foregroundColor(.maJuTaTextPrimary)
            VStack(spacing: MaJuTaSpacing.sm) {
                ForEach(bills) { bill in
                    BillRowView(bill: bill, onPay: bill.status == .paid ? nil : {
                        dataStore.payBill(bill)
                    })
                }
            }
        }
    }

    private var emptyBillsState: some View {
        VStack(spacing: MaJuTaSpacing.md) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48)).foregroundColor(.maJuTaPositive.opacity(0.6))
            Text("لا توجد فواتير").font(.maJuTaSectionTitle).foregroundColor(.maJuTaTextSecondary)
            Text("أضف فواتيرك الشهرية لتتبعها")
                .font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity).padding(MaJuTaSpacing.xxl)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
    }
}

struct AddBillView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var amount = ""
    @State private var dueDate = Date()
    @State private var provider = ""
    @State private var frequency: RecurringFrequency = .monthly

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.md) {
                    VStack(spacing: 1) {
                        fieldRow(label: "اسم الفاتورة") {
                            TextField("مثال: كهرباء، إنترنت", text: $name).multilineTextAlignment(.trailing)
                        }
                        Divider()
                        fieldRow(label: "المبلغ (﷼)") {
                            TextField("0", text: $amount).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                        Divider()
                        fieldRow(label: "الجهة المزودة") {
                            TextField("مثال: STC، SEC", text: $provider).multilineTextAlignment(.trailing)
                        }
                        Divider()
                        fieldRow(label: "تاريخ الاستحقاق") {
                            DatePicker("", selection: $dueDate, displayedComponents: .date)
                                .datePickerStyle(.compact).labelsHidden()
                        }
                        Divider()
                        fieldRow(label: "التكرار") {
                            Menu {
                                ForEach(RecurringFrequency.allCases, id: \.self) { f in
                                    Button(f.displayName) { frequency = f }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 12))
                                    Text(frequency.displayName)
                                }.foregroundColor(.maJuTaGold)
                            }
                        }
                    }
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    .maJuTaCardShadow()

                    Button("حفظ الفاتورة") { saveBill() }
                        .font(.maJuTaBodyBold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(name.isEmpty ? Color.maJuTaTextSecondary.opacity(0.3) : Color.maJuTaPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                        .disabled(name.isEmpty)
                }
                .padding(MaJuTaSpacing.horizontalPadding).padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle("فاتورة جديدة").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") { dismiss() }.foregroundColor(.maJuTaTextSecondary)
                }
            }
        }
    }

    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            content().font(.maJuTaBody)
            Spacer()
            Text(label).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
        }.padding(MaJuTaSpacing.md)
    }

    private func saveBill() {
        let categoryId = dataStore.categories.first { $0.name == "Utilities" }?.id ?? UUID()
        let accountId = dataStore.visibleAccounts.first?.id ?? UUID()
        let bill = Bill(
            name: name, nameArabic: name,
            amount: Double(amount) ?? 0,
            dueDate: dueDate,
            categoryId: categoryId,
            accountId: accountId,
            frequency: frequency,
            provider: provider,
            ownerUserId: dataStore.currentUserId
        )
        dataStore.addBill(bill)
        dismiss()
    }
}
