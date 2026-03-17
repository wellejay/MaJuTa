import SwiftUI

struct AccountsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddAccount = false

    var sharedAccounts: [Account] { dataStore.visibleAccounts.filter { $0.isShared } }
    var personalAccounts: [Account] {
        let currentUserId = UserService.shared.currentUser?.id
        return dataStore.visibleAccounts.filter { !$0.isShared && $0.ownerUserId == currentUserId }
    }
    var totalBalance: Double { dataStore.visibleAccounts.reduce(0) { $0 + $1.balance } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.md) {
                    totalCard
                    if !sharedAccounts.isEmpty {
                        accountSection(title: L("الحسابات المشتركة"), accounts: sharedAccounts, icon: "person.2.fill")
                    }
                    if !personalAccounts.isEmpty {
                        accountSection(title: L("حساباتي الخاصة"), accounts: personalAccounts, icon: "person.fill")
                    }
                    if dataStore.visibleAccounts.isEmpty { emptyState }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.vertical, MaJuTaSpacing.md)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("الحسابات"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAddAccount = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(.maJuTaGold)
                    }
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AddAccountView().environmentObject(dataStore)
            }
        }
    }

    private var totalCard: some View {
        ZStack {
            LinearGradient.navyGradient
            VStack(spacing: MaJuTaSpacing.sm) {
                Text(L("إجمالي الأصول السائلة")).font(.maJuTaCaption).foregroundColor(.white.opacity(0.7))
                SARText.hero(totalBalance, color: .white)
            }.padding(MaJuTaSpacing.xl)
        }
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private func accountSection(title: String, accounts: [Account], icon: String) -> some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            HStack {
                Image(systemName: icon).foregroundColor(.maJuTaTextSecondary).font(.system(size: 14))
                Spacer()
                Text(title).font(.maJuTaSectionTitle).foregroundColor(.maJuTaTextPrimary)
            }
            VStack(spacing: 1) {
                ForEach(accounts) { AccountRowView(account: $0) }
            }
            .background(Color.maJuTaCard)
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            .maJuTaCardShadow()
        }
    }

    private var emptyState: some View {
        VStack(spacing: MaJuTaSpacing.md) {
            Image(systemName: "creditcard.fill").font(.system(size: 48)).foregroundColor(.maJuTaTextSecondary.opacity(0.4))
            Text(L("لا توجد حسابات")).font(.maJuTaSectionTitle).foregroundColor(.maJuTaTextSecondary)
            Text(L("أضف حسابك البنكي أو محفظتك الإلكترونية"))
                .font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary.opacity(0.7)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(MaJuTaSpacing.xxl)
        .background(Color.maJuTaCard).clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
    }
}

struct AccountRowView: View {
    let account: Account

    var body: some View {
        HStack(spacing: MaJuTaSpacing.md) {
            SARText.bodyBold(account.balance)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(account.name).font(.maJuTaBodyMedium).foregroundColor(.maJuTaTextPrimary)
                Text(account.institution).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
            }
            ZStack {
                RoundedRectangle(cornerRadius: MaJuTaRadius.small).fill(Color.maJuTaPrimary.opacity(0.1)).frame(width: 40, height: 40)
                Image(systemName: account.type.icon).font(.system(size: 16)).foregroundColor(.maJuTaPrimary)
            }
        }
        .padding(MaJuTaSpacing.md).background(Color.maJuTaCard)
    }
}

struct AddAccountView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var institution = ""
    @State private var balance = ""
    @State private var selectedType: AccountType = .bank
    @State private var isShared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.lg) {
                    VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
                        Text(L("نوع الحساب")).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MaJuTaSpacing.sm) {
                                ForEach(AccountType.allCases, id: \.self) { type in
                                    Button { selectedType = type } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: type.icon)
                                            Text(type.displayName)
                                        }
                                        .font(.maJuTaCaptionMedium)
                                        .foregroundColor(selectedType == type ? .maJuTaPrimary : .maJuTaTextSecondary)
                                        .padding(.horizontal, MaJuTaSpacing.sm).padding(.vertical, MaJuTaSpacing.xs)
                                        .background(selectedType == type ? Color.maJuTaGold : Color.maJuTaCard)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(MaJuTaSpacing.md).background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card)).maJuTaCardShadow()

                    VStack(spacing: 1) {
                        fieldRow(label: L("اسم الحساب")) { TextField(L("مثال: البنك الأهلي - جاري"), text: $name).multilineTextAlignment(.trailing) }
                        Divider()
                        fieldRow(label: L("البنك / المزود")) { TextField(L("مثال: البنك الأهلي"), text: $institution).multilineTextAlignment(.trailing) }
                        Divider()
                        fieldRow(label: L("الرصيد (ر.س)")) { TextField("0", text: $balance).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                        Divider()
                        HStack {
                            Toggle("", isOn: $isShared).tint(.maJuTaGold).labelsHidden()
                            Spacer()
                            Text(L("حساب مشترك مع العائلة")).font(.maJuTaBody).foregroundColor(.maJuTaTextPrimary)
                        }.padding(MaJuTaSpacing.md)
                    }
                    .background(Color.maJuTaCard).clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card)).maJuTaCardShadow()

                    Button(L("إضافة الحساب")) { saveAccount() }
                        .font(.maJuTaBodyBold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(name.isEmpty ? Color.maJuTaTextSecondary.opacity(0.3) : Color.maJuTaPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                        .disabled(name.isEmpty)
                }
                .padding(MaJuTaSpacing.horizontalPadding).padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("حساب جديد")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button(L("إلغاء")) { dismiss() }.foregroundColor(.maJuTaTextSecondary) } }
        }
    }

    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack { content().font(.maJuTaBody); Spacer(); Text(label).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary) }
            .padding(MaJuTaSpacing.md)
    }

    private func saveAccount() {
        let userId = UserService.shared.currentUser?.id ?? UUID()
        let householdId = UserService.shared.currentUser?.householdId ?? UUID()
        let account = Account(name: name, type: selectedType, balance: Double(balance) ?? 0,
                              institution: institution, ownerUserId: userId,
                              householdId: householdId, isShared: isShared)
        dataStore.addAccount(account)
        dismiss()
    }
}
