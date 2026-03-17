import SwiftUI

struct InstallmentsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddPlan = false

    var totalOwed: Double {
        dataStore.installments.filter { $0.status == .upcoming }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.md) {
                    bnplSummaryCard
                    if dataStore.installmentPlans.isEmpty {
                        emptyState
                    } else {
                        ForEach(dataStore.installmentPlans) { plan in
                            InstallmentPlanCard(
                                plan: plan,
                                installments: dataStore.installments.filter { $0.planId == plan.id }
                            )
                        }
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.vertical, MaJuTaSpacing.md)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("الأقساط BNPL"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAddPlan = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(.maJuTaGold)
                    }
                }
            }
            .sheet(isPresented: $showAddPlan) {
                AddInstallmentPlanView().environmentObject(dataStore)
            }
        }
    }

    private var bnplSummaryCard: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            Text(L("إجمالي الأقساط المتبقية"))
                .font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
            SARText.hero(totalOwed)
            HStack(spacing: MaJuTaSpacing.md) {
                Spacer()
                providerBadge(L("تابي"), color: "#3DBDB2")
                providerBadge(L("تمارا"), color: "#FF5FA0")
                providerBadge(L("بوست باي"), color: "#0052CC")
            }
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func providerBadge(_ name: String, color: String) -> some View {
        Text(name).font(.maJuTaLabel).foregroundColor(Color(hex: color))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color(hex: color).opacity(0.1)).clipShape(Capsule())
    }

    private var emptyState: some View {
        VStack(spacing: MaJuTaSpacing.md) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48)).foregroundColor(.maJuTaTextSecondary.opacity(0.4))
            Text(L("لا توجد أقساط")).font(.maJuTaSectionTitle).foregroundColor(.maJuTaTextSecondary)
            Text(L("أضف أقساط تابي أو تمارا لتتبعها"))
                .font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity).padding(MaJuTaSpacing.xxl)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
    }
}

// MARK: - Add Installment Plan View
struct AddInstallmentPlanView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var merchant = ""
    @State private var provider: BNPLProvider = .tabby
    @State private var totalAmount = ""
    @State private var installmentsCount = 4
    @State private var startDate = Date()

    private let countOptions = [2, 3, 4, 6, 8, 12]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.lg) {
                    // Merchant
                    VStack(alignment: .trailing, spacing: MaJuTaSpacing.xs) {
                        Text(L("المتجر")).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                        TextField(L("اسم المتجر"), text: $merchant)
                            .font(.maJuTaBody).multilineTextAlignment(.trailing)
                            .padding(MaJuTaSpacing.md).background(Color.maJuTaCard)
                            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                            .maJuTaCardShadow()
                    }

                    // Provider
                    VStack(alignment: .trailing, spacing: MaJuTaSpacing.xs) {
                        Text(L("مزود الخدمة")).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                        HStack(spacing: MaJuTaSpacing.sm) {
                            ForEach(BNPLProvider.allCases, id: \.self) { p in
                                Button {
                                    provider = p
                                } label: {
                                    Text(p.displayName).font(.maJuTaCaptionMedium)
                                        .foregroundColor(provider == p ? .white : Color(hex: p.logoColor))
                                        .padding(.horizontal, MaJuTaSpacing.md).padding(.vertical, MaJuTaSpacing.sm)
                                        .background(provider == p ? Color(hex: p.logoColor) : Color(hex: p.logoColor).opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            Spacer()
                        }
                    }

                    // Total Amount
                    VStack(alignment: .trailing, spacing: MaJuTaSpacing.xs) {
                        Text(L("المبلغ الكلي")).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                        HStack {
                            TextField("0", text: $totalAmount)
                                .keyboardType(.numberPad)
                                .font(.maJuTaLargeNumber).multilineTextAlignment(.trailing)
                            Text("\u{E900}").font(.custom("saudi_riyalregular", size: 28)).foregroundColor(.maJuTaGold)
                        }
                        .padding(MaJuTaSpacing.md).background(Color.maJuTaCard)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card)).maJuTaCardShadow()
                    }

                    // Installments Count
                    VStack(alignment: .trailing, spacing: MaJuTaSpacing.xs) {
                        Text(L("عدد الأقساط")).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                        HStack(spacing: MaJuTaSpacing.sm) {
                            ForEach(countOptions, id: \.self) { count in
                                Button {
                                    installmentsCount = count
                                } label: {
                                    Text("\(count)").font(.maJuTaCaptionMedium)
                                        .foregroundColor(installmentsCount == count ? .maJuTaPrimary : .maJuTaTextSecondary)
                                        .frame(width: 40, height: 40)
                                        .background(installmentsCount == count ? Color.maJuTaGold : Color.maJuTaBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.small))
                                }
                            }
                            Spacer()
                        }

                        if let amount = Double(totalAmount), amount > 0 {
                            HStack(spacing: 2) {
                                Text(L("/ شهر")).font(.maJuTaBodyBold).foregroundColor(.maJuTaGold)
                                SARText.bodyBold(amount / Double(installmentsCount), color: .maJuTaGold)
                                Text(L("قسط")).font(.maJuTaBodyBold).foregroundColor(.maJuTaGold)
                            }
                        }
                    }

                    // Start Date
                    VStack(alignment: .trailing, spacing: MaJuTaSpacing.xs) {
                        Text(L("تاريخ البداية")).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .environment(\.locale, Locale(identifier: "en_SA"))
                    }
                    .padding(MaJuTaSpacing.md).background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card)).maJuTaCardShadow()

                    // Save
                    Button(L("إضافة الخطة")) {
                        savePlan()
                    }
                    .font(.maJuTaBodyBold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(merchant.isEmpty || totalAmount.isEmpty ? Color.maJuTaTextSecondary.opacity(0.3) : Color.maJuTaPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                    .disabled(merchant.isEmpty || totalAmount.isEmpty)
                }
                .padding(MaJuTaSpacing.horizontalPadding)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("خطة أقساط جديدة"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("إلغاء")) { dismiss() }.foregroundColor(.maJuTaTextSecondary)
                }
            }
        }
    }

    private func savePlan() {
        guard let amount = Double(totalAmount), amount > 0, !merchant.isEmpty else { return }
        let plan = InstallmentPlan(
            merchant: merchant,
            provider: provider,
            totalAmount: amount,
            installmentsCount: installmentsCount,
            startDate: startDate,
            ownerUserId: dataStore.currentUserId
        )
        dataStore.addInstallmentPlan(plan)
        dismiss()
    }
}

// MARK: - Installment Plan Card
struct InstallmentPlanCard: View {
    let plan: InstallmentPlan
    let installments: [Installment]

    var paidCount: Int { installments.filter { $0.status == .paid }.count }
    var progress: Double { installments.isEmpty ? 0 : Double(paidCount) / Double(installments.count) }

    var body: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            HStack {
                SARText.bodyBold(plan.installmentAmount)
                Text(L("/ قسط")).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                Spacer()
                Text(plan.merchant).font(.maJuTaBodyMedium).foregroundColor(.maJuTaTextPrimary)
                providerLabel(plan.provider)
            }

            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text("\(plan.installmentsCount) \(L("قسط"))").font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                    Spacer()
                    Text("\(paidCount) \(L("مدفوع"))").font(.maJuTaCaption).foregroundColor(.maJuTaPositive)
                }
                GeometryReader { geo in
                    ZStack(alignment: .trailing) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.maJuTaBackground).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: plan.provider.logoColor))
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }.frame(height: 6)
            }

            HStack(spacing: MaJuTaSpacing.sm) {
                ForEach(installments.filter { $0.status == .upcoming }.prefix(3)) { inst in
                    VStack(spacing: 2) {
                        SARText.caption(inst.amount)
                        Text(inst.dueDate.shortFormatted).font(.maJuTaLabel).foregroundColor(.maJuTaTextSecondary)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.maJuTaBackground)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.small))
                }
                Spacer()
            }
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func providerLabel(_ provider: BNPLProvider) -> some View {
        Text(provider.displayName).font(.maJuTaLabel).foregroundColor(Color(hex: provider.logoColor))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color(hex: provider.logoColor).opacity(0.1)).clipShape(Capsule())
    }
}
